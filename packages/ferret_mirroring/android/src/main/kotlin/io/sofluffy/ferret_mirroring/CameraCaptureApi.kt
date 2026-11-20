package io.sofluffy.ferret_mirroring

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.util.Log
import java.util.concurrent.atomic.AtomicInteger
import kotlin.coroutines.resume
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull

/** Sends this phone's camera and microphone to Dart: permissions, the service, and the frames. */
internal class CameraCaptureApi(
    private val context: Context,
    private val flutterApi: CameraCaptureFlutterApi,
    private val scope: CoroutineScope,
    private val activity: () -> Activity?,
) : CameraCaptureHostApi, CameraSession.Listener {
    /** Frames handed to Dart that it hasn't taken yet. */
    private val waitingForDart = AtomicInteger(0)

    @Volatile
    private var skippingToKeyframe = false

    /** Sound handed to Dart that it hasn't taken yet. */
    private val soundWaitingForDart = AtomicInteger(0)
    private var permissionAnswer: (() -> Unit)? = null

    fun attach() {
        CameraBridge.listener = this
    }

    fun detach() {
        if (CameraBridge.listener === this) {
            CameraBridge.listener = null
        }

        CameraBridge.service?.finish()
        answerPermission()
    }

    /** Android answered the prompt from [requestAccess]. */
    fun onPermissionsResult(requestCode: Int): Boolean {
        if (requestCode != REQUEST_CAMERA) {
            return false
        }

        answerPermission()
        return true
    }

    /** The screen the prompt was on went away. */
    fun answerPermission() {
        val answer = permissionAnswer
        permissionAnswer = null
        answer?.invoke()
    }

    override fun support(): NativeCameraSupport = NativeCameraSupport(
        h264 = H264Encoder.isSupported(),
        lenses = CameraLenses.all(context.getSystemService(CameraManager::class.java)),
        cameraGranted = isGranted(Manifest.permission.CAMERA),
        microphoneGranted = isGranted(Manifest.permission.RECORD_AUDIO),
    )

    override suspend fun requestAccess(withMicrophone: Boolean): NativeCameraSupport {
        val missing = listOfNotNull(
            Manifest.permission.CAMERA.takeUnless(::isGranted),
            Manifest.permission.RECORD_AUDIO.takeIf { permission -> withMicrophone && !isGranted(permission) },
        )
        val screen = activity()
        if (missing.isEmpty() || screen == null) {
            return support()
        }

        suspendCancellableCoroutine { continuation ->
            answerPermission()
            permissionAnswer = {
                if (continuation.isActive) {
                    continuation.resume(Unit)
                }
            }
            screen.requestPermissions(missing.toTypedArray(), REQUEST_CAMERA)
        }

        return support()
    }

    override suspend fun start(options: NativeCameraOptions, texts: NativeCameraTexts): NativeCameraLens? {
        if (!isGranted(Manifest.permission.CAMERA)) {
            return null
        }

        CameraBridge.service?.finish()
        waitingForDart.set(0)
        soundWaitingForDart.set(0)
        skippingToKeyframe = false
        val withMicrophone = options.audioCodec != null && isGranted(Manifest.permission.RECORD_AUDIO)
        val service = withTimeoutOrNull(ARM_TIMEOUT_MS) {
            suspendCancellableCoroutine { continuation ->
                CameraBridge.whenArmed { armed ->
                    if (continuation.isActive) {
                        continuation.resume(armed)
                    }
                }
                if (!CameraService.start(context, texts, withMicrophone)) {
                    CameraBridge.armed(null)
                }
            }
        }
        if (service == null) {
            return null
        }

        val wanted = if (withMicrophone) options else options.copy(audioCodec = null)
        return service.begin(wanted, this)
    }

    override suspend fun setLens(lens: NativeCameraLens): NativeCameraLens? = CameraBridge.service?.setLens(lens)

    override fun stop() {
        CameraBridge.service?.finish()
    }

    override fun requestKeyframe() {
        CameraBridge.service?.requestKeyframe()
    }

    override fun setBitrate(bitrate: Long) {
        CameraBridge.service?.setBitrate(bitrate.toInt())
    }

    override fun onConfig(config: NativeStreamConfig) {
        toDart { api -> api.onConfig(config) }
    }

    /**
     * Called on the camera thread. When Dart falls behind, frames are
     * skipped up to the next keyframe, because the ones in between can't be
     * decoded without the skipped one.
     */
    override fun onFrame(data: ByteArray, ptsUs: Long, keyframe: Boolean) {
        if (skippingToKeyframe && !keyframe) {
            return
        }

        if (waitingForDart.get() >= MAX_WAITING_FRAMES) {
            skippingToKeyframe = true
            return
        }

        skippingToKeyframe = false
        waitingForDart.incrementAndGet()
        scope.launch {
            try {
                flutterApi.onFrame(NativeFrame(data, ptsUs, keyframe))
            } catch (error: Throwable) {
                skippingToKeyframe = true
            } finally {
                val left = waitingForDart.decrementAndGet()
                if (left == 0 && skippingToKeyframe) {
                    CameraBridge.service?.requestKeyframe()
                }
            }
        }
    }

    override fun onAudioConfig(codec: NativeAudioCodec, sampleRate: Int, channels: Int) {
        toDart { api -> api.onAudioConfig(codec, sampleRate.toLong(), channels.toLong()) }
    }

    /** Called on the sound thread. Sound Dart has no time for is dropped, not kept. */
    override fun onAudioFrame(data: ByteArray, ptsUs: Long) {
        if (soundWaitingForDart.get() >= MAX_WAITING_SOUND) {
            return
        }

        soundWaitingForDart.incrementAndGet()
        scope.launch {
            try {
                flutterApi.onAudioFrame(data, ptsUs)
            } catch (error: Throwable) {
                Log.w(TAG, "Dart did not take the microphone's sound", error)
            } finally {
                soundWaitingForDart.decrementAndGet()
            }
        }
    }

    override fun onAudioEnded() {
        toDart { api -> api.onAudioEnded() }
    }

    override fun onEnded(end: NativeCaptureEnd) {
        scope.launch {
            CameraBridge.service?.finish()
            try {
                flutterApi.onEnded(end)
            } catch (error: Throwable) {
                Log.w(TAG, "Dart did not take the end of the camera", error)
            }
        }
    }

    private fun isGranted(permission: String): Boolean =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun toDart(send: suspend (CameraCaptureFlutterApi) -> Unit) {
        scope.launch {
            try {
                send(flutterApi)
            } catch (error: Throwable) {
                Log.w(TAG, "Dart did not take a camera event", error)
            }
        }
    }

    companion object {
        private const val TAG = "FerretCamera"
        private const val MAX_WAITING_FRAMES = 8

        /** Half a second of 20 ms packets. */
        private const val MAX_WAITING_SOUND = 25
        private const val REQUEST_CAMERA = 7405
        private const val ARM_TIMEOUT_MS = 5_000L
    }
}
