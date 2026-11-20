package io.sofluffy.ferret_mirroring

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import android.media.MediaCodec
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import android.util.Range
import android.view.OrientationEventListener

/**
 * One time a computer uses the camera: Camera2 draws into the H.264
 * encoder's surface, the microphone goes along when asked, and a new
 * config says how to turn the picture whenever the phone is turned. The
 * pictures are sent as the sensor sees them.
 */
internal class CameraSession(
    private val context: Context,
    private val options: NativeCameraOptions,
    private val listener: Listener,
) : EncoderOutput, AudioCapture.Output {
    /** Receives the camera's output. Frames and configs arrive on the camera thread. */
    interface Listener {
        fun onConfig(config: NativeStreamConfig)

        fun onFrame(data: ByteArray, ptsUs: Long, keyframe: Boolean)

        fun onAudioConfig(codec: NativeAudioCodec, sampleRate: Int, channels: Int)

        fun onAudioFrame(data: ByteArray, ptsUs: Long)

        /** Capturing the microphone stopped working; the pictures go on. */
        fun onAudioEnded()

        fun onEnded(end: NativeCaptureEnd)
    }

    private val thread = HandlerThread("ferret-camera").apply { start() }
    private val handler = Handler(thread.looper)
    private val main = Handler(Looper.getMainLooper())
    private val manager = context.getSystemService(CameraManager::class.java)
    private var device: CameraDevice? = null
    private var capture: CameraCaptureSession? = null
    private var encoder: H264Encoder? = null
    private var audio: AudioCapture? = null
    private var lastConfig: NativeStreamConfig? = null
    private var fpsRange: Pair<Int, Int>? = null
    private var sensorOrientation = 0
    private var bitrate = options.bitrate.toInt()

    @Volatile
    private var lens = options.lens

    @Volatile
    private var deviceDegrees = 0

    @Volatile
    private var released = false

    private val orientation = object : OrientationEventListener(context) {
        override fun onOrientationChanged(degrees: Int) {
            val snapped = CameraPlan.snap(degrees, deviceDegrees)
            if (snapped == deviceDegrees) {
                return
            }

            deviceDegrees = snapped
            handler.post { sendTurn() }
        }
    }

    /** Throws when this phone has no camera. Answers with the one that is opening. */
    fun start(): NativeCameraLens {
        val first = CameraLenses.nearest(manager, options.lens)
            ?: throw IllegalStateException("This phone has no camera")
        lens = first
        handler.post { open(first) }
        main.post {
            if (!released && orientation.canDetectOrientation()) {
                orientation.enable()
            }
        }
        startAudio()
        return first
    }

    /** The camera that is on after trying [wanted]. */
    fun setLens(wanted: NativeCameraLens): NativeCameraLens {
        val next = CameraLenses.nearest(manager, wanted) ?: return lens
        if (next == lens || released) {
            return lens
        }

        lens = next
        handler.post {
            closeCamera()
            open(next)
        }
        return next
    }

    fun requestKeyframe() {
        handler.post { encoder?.requestKeyframe() }
    }

    fun setBitrate(bitrate: Int) {
        handler.post {
            this.bitrate = bitrate
            encoder?.setBitrate(bitrate)
        }
    }

    fun release() {
        if (released) {
            return
        }

        released = true
        main.post { orientation.disable() }
        audio?.release()
        audio = null
        handler.post {
            closeCamera()
            thread.quitSafely()
        }
    }

    override fun onConfig(config: NativeStreamConfig) {
        lastConfig = config
        if (!released) {
            listener.onConfig(config.copy(turn = turn().toLong()))
        }
    }

    override fun onFrame(data: ByteArray, ptsUs: Long, keyframe: Boolean) {
        if (!released) {
            listener.onFrame(data, ptsUs, keyframe)
        }
    }

    override fun onEncoderError(error: Throwable) {
        Log.w(TAG, "Camera encoder failed", error)
        fail(NativeCaptureEnd.FAILED)
    }

    override fun onAudioConfig(codec: NativeAudioCodec, sampleRate: Int, channels: Int) {
        if (!released) {
            listener.onAudioConfig(codec, sampleRate, channels)
        }
    }

    override fun onAudioFrame(data: ByteArray, ptsUs: Long) {
        if (!released) {
            listener.onAudioFrame(data, ptsUs)
        }
    }

    override fun onAudioEnded() {
        if (!released) {
            listener.onAudioEnded()
        }
    }

    /** A microphone that can't be opened never stops the pictures. */
    private fun startAudio() {
        val codec = options.audioCodec ?: return
        try {
            val created = AudioCapture(AudioCapture.Source.Microphone, codec, this)
            created.start()
            audio = created
        } catch (error: Exception) {
            Log.w(TAG, "The microphone could not be opened", error)
            listener.onAudioEnded()
        }
    }

    /** Runs on the camera thread. Each camera gets an encoder of its own size. */
    @SuppressLint("MissingPermission")
    private fun open(target: NativeCameraLens) {
        if (released) {
            return
        }

        try {
            val id = CameraLenses.idOf(manager, target) ?: throw IllegalStateException("The camera is gone")
            val traits = manager.getCameraCharacteristics(id)
            val sizes = traits.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
                ?.getOutputSizes(MediaCodec::class.java)
                .orEmpty()
                .map { size -> CaptureSize(size.width, size.height) }
            val size = CameraPlan.size(sizes, options.maxLongSide.toInt(), options.maxShortSide.toInt())
                ?: throw IllegalStateException("The camera has no size that fits")
            val fps = options.fps.toInt()
            sensorOrientation = traits.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0
            fpsRange = CameraPlan.fpsRange(
                traits.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES)
                    .orEmpty()
                    .map { range -> range.lower to range.upper },
                fps,
            )
            lastConfig = null
            encoder = H264Encoder(size, 0, fps, bitrate, handler, this)
            manager.openCamera(id, deviceCallback, handler)
        } catch (error: Exception) {
            Log.w(TAG, "The camera could not be opened", error)
            fail(NativeCaptureEnd.FAILED)
        }
    }

    private val deviceCallback = object : CameraDevice.StateCallback() {
        override fun onOpened(camera: CameraDevice) {
            val surface = encoder?.surface
            if (released || surface == null) {
                camera.close()
                return
            }

            device = camera
            try {
                @Suppress("DEPRECATION")
                camera.createCaptureSession(listOf(surface), captureCallback, handler)
            } catch (error: Exception) {
                Log.w(TAG, "The camera refused the encoder", error)
                fail(NativeCaptureEnd.FAILED)
            }
        }

        /** Another app took the camera, or Android turned cameras off. */
        override fun onDisconnected(camera: CameraDevice) {
            camera.close()
            if (camera === device) {
                device = null
                fail(NativeCaptureEnd.ENDED_BY_SYSTEM)
            }
        }

        override fun onError(camera: CameraDevice, error: Int) {
            Log.w(TAG, "The camera failed ($error)")
            camera.close()
            if (camera === device || device == null) {
                device = null
                fail(NativeCaptureEnd.FAILED)
            }
        }
    }

    private val captureCallback = object : CameraCaptureSession.StateCallback() {
        override fun onConfigured(session: CameraCaptureSession) {
            val camera = device
            val surface = encoder?.surface
            if (released || camera == null || surface == null || session.device !== camera) {
                return
            }

            capture = session
            try {
                val request = camera.createCaptureRequest(CameraDevice.TEMPLATE_RECORD).apply {
                    addTarget(surface)
                    fpsRange?.let { range ->
                        set(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, Range(range.first, range.second))
                    }
                }
                session.setRepeatingRequest(request.build(), null, handler)
            } catch (error: Exception) {
                Log.w(TAG, "The camera did not start sending pictures", error)
                fail(NativeCaptureEnd.FAILED)
            }
        }

        override fun onConfigureFailed(session: CameraCaptureSession) {
            if (session.device === device) {
                fail(NativeCaptureEnd.FAILED)
            }
        }
    }

    private fun closeCamera() {
        val camera = device
        device = null
        capture = null
        try {
            camera?.close()
        } catch (error: Exception) {
            Log.w(TAG, "Closing the camera failed", error)
        }

        encoder?.release()
        encoder = null
    }

    /** The phone was turned: the same stream, shown turned another way. */
    private fun sendTurn() {
        val config = lastConfig
        if (released || config == null) {
            return
        }

        listener.onConfig(config.copy(turn = turn().toLong()))
        encoder?.requestKeyframe()
    }

    private fun turn(): Int = CameraPlan.turn(sensorOrientation, deviceDegrees, lens == NativeCameraLens.FRONT)

    private fun fail(end: NativeCaptureEnd) {
        if (!released) {
            listener.onEnded(end)
        }
    }

    companion object {
        private const val TAG = "FerretCamera"
    }
}

/** Which cameras a phone has, by the way they face. */
internal object CameraLenses {
    /** Every way a camera of this phone faces, the back first. */
    fun all(manager: CameraManager?): List<NativeCameraLens> =
        listOf(NativeCameraLens.BACK, NativeCameraLens.FRONT).filter { lens -> idOf(manager, lens) != null }

    /** [wanted] when the phone has it, else the camera it does have. */
    fun nearest(manager: CameraManager?, wanted: NativeCameraLens): NativeCameraLens? {
        val lenses = all(manager)
        if (wanted in lenses) {
            return wanted
        }

        return lenses.firstOrNull()
    }

    /** The first camera facing that way: the main one on phones with several. */
    fun idOf(manager: CameraManager?, lens: NativeCameraLens): String? {
        val facing = when (lens) {
            NativeCameraLens.BACK -> CameraCharacteristics.LENS_FACING_BACK
            NativeCameraLens.FRONT -> CameraCharacteristics.LENS_FACING_FRONT
        }

        try {
            return manager?.cameraIdList?.firstOrNull { id ->
                manager.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING) == facing
            }
        } catch (error: Exception) {
            Log.w("FerretCamera", "Could not list the cameras", error)
            return null
        }
    }
}
