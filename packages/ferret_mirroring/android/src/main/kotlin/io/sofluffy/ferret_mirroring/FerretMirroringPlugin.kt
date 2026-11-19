package io.sofluffy.ferret_mirroring

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.atomic.AtomicInteger
import kotlin.coroutines.resume
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine

/** Captures this phone's screen for Dart: consent, the service, and the frames. */
class FerretMirroringPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    MirrorCaptureHostApi,
    MirrorBridge.Listener {
    private var context: Context? = null
    private var flutterApi: MirrorCaptureFlutterApi? = null
    private var scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    /** Frames handed to Dart that it hasn't taken yet. */
    private val waitingForDart = AtomicInteger(0)

    @Volatile
    private var skippingToKeyframe = false

    /** Sound handed to Dart that it hasn't taken yet. */
    private val soundWaitingForDart = AtomicInteger(0)
    private var activity: ActivityPluginBinding? = null
    private var permissionAnswer: ((Boolean) -> Unit)? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterApi = MirrorCaptureFlutterApi(binding.binaryMessenger)
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        MirrorCaptureHostApi.setUp(binding.binaryMessenger, this)
        MirrorBridge.listener = this
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MirrorCaptureHostApi.setUp(binding.binaryMessenger, null)
        if (MirrorBridge.listener === this) {
            MirrorBridge.listener = null
        }

        MirrorBridge.service?.finish()
        scope.cancel()
        flutterApi = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity?.removeRequestPermissionsResultListener(this)
        activity = null
        answerPermission(false)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_SOUND) {
            return false
        }

        answerPermission(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        return true
    }

    override fun audioSupport(): NativeAudioSupport {
        val appContext = context ?: return NativeAudioSupport.UNSUPPORTED
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return NativeAudioSupport.UNSUPPORTED
        }

        return AudioCapture.support(appContext)
    }

    override suspend fun requestAudioPermission(): Boolean {
        if (audioSupport() == NativeAudioSupport.READY) {
            return true
        }

        val screen = activity?.activity
        if (screen == null || audioSupport() == NativeAudioSupport.UNSUPPORTED) {
            return false
        }

        return suspendCancellableCoroutine { continuation ->
            answerPermission(false)
            permissionAnswer = { granted ->
                if (continuation.isActive) {
                    continuation.resume(granted)
                }
            }
            screen.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_SOUND)
        }
    }

    private fun answerPermission(granted: Boolean) {
        val answer = permissionAnswer
        permissionAnswer = null
        answer?.invoke(granted)
    }

    override fun support(): NativeCaptureSupport = NativeCaptureSupport(h264 = H264Encoder.isSupported(), jpeg = true)

    override suspend fun requestConsent(texts: NativeConsentTexts, timeoutSeconds: Long): NativeConsentResult {
        val appContext = context ?: return NativeConsentResult.FAILED
        MirrorBridge.service?.finish()

        return suspendCancellableCoroutine { continuation ->
            ProjectionConsent.request(appContext, texts, timeoutSeconds) { result ->
                if (continuation.isActive) {
                    continuation.resume(result)
                }
            }
        }
    }

    override fun cancelConsent() {
        val appContext = context ?: return
        ProjectionConsent.complete(appContext, NativeConsentResult.TIMED_OUT)
    }

    override suspend fun start(options: NativeCaptureOptions): Boolean {
        val service = MirrorBridge.service ?: return false
        waitingForDart.set(0)
        soundWaitingForDart.set(0)
        skippingToKeyframe = false
        return service.begin(options, this)
    }

    override fun stop() {
        MirrorBridge.service?.finish()
    }

    override fun requestKeyframe() {
        MirrorBridge.service?.requestKeyframe()
    }

    override fun setBitrate(bitrate: Long) {
        MirrorBridge.service?.setBitrate(bitrate.toInt())
    }

    override fun onConfig(config: NativeStreamConfig) {
        toDart { api -> api.onConfig(config) }
    }

    /**
     * Called on the capture thread. When Dart falls behind, frames are
     * skipped up to the next keyframe, because the ones in between can't be
     * decoded without the skipped one.
     */
    override fun onFrame(data: ByteArray, ptsUs: Long, keyframe: Boolean) {
        val waiting = waitingForDart.get()
        if (skippingToKeyframe && !keyframe) {
            return
        }

        if (waiting >= MAX_WAITING_FRAMES) {
            skippingToKeyframe = true
            return
        }

        if (skippingToKeyframe) {
            skippingToKeyframe = false
        }

        waitingForDart.incrementAndGet()
        scope.launch {
            try {
                flutterApi?.onFrame(NativeFrame(data, ptsUs, keyframe))
            } catch (error: Throwable) {
                skippingToKeyframe = true
            } finally {
                val left = waitingForDart.decrementAndGet()
                if (left == 0 && skippingToKeyframe) {
                    MirrorBridge.service?.requestKeyframe()
                }
            }
        }
    }

    override fun onScreenOff(off: Boolean) {
        toDart { api -> api.onScreenOff(off) }
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
                flutterApi?.onAudioFrame(data, ptsUs)
            } catch (error: Throwable) {
                android.util.Log.w(TAG, "Dart did not take the sound", error)
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
            MirrorBridge.service?.finish()
            try {
                flutterApi?.onEnded(end)
            } catch (error: Throwable) {
                android.util.Log.w(TAG, "Dart did not take the end of the capture", error)
            }
        }
    }

    private fun toDart(send: suspend (MirrorCaptureFlutterApi) -> Unit) {
        scope.launch {
            val api = flutterApi ?: return@launch
            try {
                send(api)
            } catch (error: Throwable) {
                android.util.Log.w(TAG, "Dart did not take a capture event", error)
            }
        }
    }

    companion object {
        private const val TAG = "FerretMirroring"
        private const val MAX_WAITING_FRAMES = 8

        /** Half a second of 20 ms packets. */
        private const val MAX_WAITING_SOUND = 25
        private const val REQUEST_SOUND = 7403
    }
}
