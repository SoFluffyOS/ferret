package io.sofluffy.ferret_mirroring

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.projection.MediaProjection
import android.os.Handler
import android.os.HandlerThread
import android.os.PowerManager
import android.util.DisplayMetrics
import android.util.Log
import android.view.Display

/**
 * One capture: mirrors the screen into an encoder's surface, follows
 * rotation and size changes with a new encoder and a new config, and
 * reports the screen going off and the system ending the capture.
 */
internal class ScreenCaptureSession(
    private val context: Context,
    private val projection: MediaProjection,
    private val options: NativeCaptureOptions,
    private val listener: MirrorBridge.Listener,
) : EncoderOutput {
    private val thread = HandlerThread("ferret-mirror").apply { start() }
    private val handler = Handler(thread.looper)
    private val displayManager = context.getSystemService(DisplayManager::class.java)
    private var virtualDisplay: VirtualDisplay? = null
    private var encoder: FrameEncoder? = null
    private var size = CaptureSize(0, 0)
    private var rotation = 0

    /** Set while the captured area isn't the whole screen, as Android 14 allows. */
    private var contentSize: CaptureSize? = null

    @Volatile
    private var released = false

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            if (!released) {
                listener.onEnded(NativeCaptureEnd.ENDED_BY_SYSTEM)
            }
        }

        override fun onCapturedContentResize(width: Int, height: Int) {
            contentSize = CaptureSize(width, height)
            reconfigure()
        }
    }

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit

        override fun onDisplayRemoved(displayId: Int) = Unit

        override fun onDisplayChanged(displayId: Int) {
            if (displayId == Display.DEFAULT_DISPLAY) {
                reconfigure()
            }
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val off = intent.action == Intent.ACTION_SCREEN_OFF
            listener.onScreenOff(off)
            if (!off) {
                handler.post { keyframeNow() }
            }
        }
    }

    /** Throws when the encoder or the virtual display can't be created. */
    fun start() {
        projection.registerCallback(projectionCallback, handler)
        val metrics = screenMetrics()
        rotation = screenRotation()
        size = targetSize(metrics)
        val created = createEncoder()
        encoder = created
        virtualDisplay = projection.createVirtualDisplay(
            "ferret-mirror",
            size.width,
            size.height,
            metrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            created.surface,
            null,
            handler,
        )
        displayManager.registerDisplayListener(displayListener, handler)
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        context.registerReceiver(screenReceiver, filter)
        val power = context.getSystemService(PowerManager::class.java)
        if (power != null && !power.isInteractive) {
            listener.onScreenOff(true)
        }
    }

    /**
     * Asks for a frame that decodes on its own. An encoder only makes a
     * frame when the screen changes (it repeats a still picture for about a
     * second, then waits), so the display is attached again to draw one.
     */
    fun requestKeyframe() {
        handler.post { keyframeNow() }
    }

    fun setBitrate(bitrate: Int) {
        handler.post { encoder?.setBitrate(bitrate) }
    }

    fun release() {
        if (released) {
            return
        }

        released = true
        try {
            context.unregisterReceiver(screenReceiver)
        } catch (error: IllegalArgumentException) {
            Log.w(TAG, "Screen receiver was not registered", error)
        }

        displayManager.unregisterDisplayListener(displayListener)
        projection.unregisterCallback(projectionCallback)
        handler.post {
            virtualDisplay?.release()
            virtualDisplay = null
            encoder?.release()
            encoder = null
            projection.stop()
            thread.quitSafely()
        }
    }

    override fun onConfig(config: NativeStreamConfig) {
        if (!released) {
            listener.onConfig(config)
        }
    }

    override fun onFrame(data: ByteArray, ptsUs: Long, keyframe: Boolean) {
        if (!released) {
            listener.onFrame(data, ptsUs, keyframe)
        }
    }

    override fun onEncoderError(error: Throwable) {
        Log.w(TAG, "Screen encoder failed", error)
        if (!released) {
            listener.onEnded(NativeCaptureEnd.FAILED)
        }
    }

    /** Runs on the capture thread: a rotated or resized screen needs a new encoder. */
    private fun reconfigure() {
        val display = virtualDisplay
        if (released || display == null) {
            return
        }

        val metrics = screenMetrics()
        val newRotation = screenRotation()
        val newSize = targetSize(metrics)
        if (newSize == size && newRotation == rotation) {
            return
        }

        size = newSize
        rotation = newRotation
        val previous = encoder
        try {
            val created = createEncoder()
            display.resize(newSize.width, newSize.height, metrics.densityDpi)
            display.surface = created.surface
            encoder = created
        } catch (error: Exception) {
            onEncoderError(error)
            return
        }

        previous?.release()
    }

    private fun keyframeNow() {
        val current = encoder ?: return
        current.requestKeyframe()
        if (released || !current.needsFreshFrame) {
            return
        }

        try {
            virtualDisplay?.surface = null
        } catch (error: RuntimeException) {
            Log.w(TAG, "Could not detach the mirrored display", error)
        }

        handler.postDelayed({ reattach(current) }, REATTACH_DELAY_MS)
    }

    private fun reattach(expected: FrameEncoder) {
        if (released || encoder !== expected) {
            return
        }

        try {
            virtualDisplay?.surface = expected.surface
        } catch (error: RuntimeException) {
            onEncoderError(error)
        }
    }

    private fun createEncoder(): FrameEncoder {
        if (options.codec == NativeCodec.JPEG) {
            return JpegEncoder(size, rotation, options.fps.toInt(), handler, this)
        }

        return H264Encoder(size, rotation, options.fps.toInt(), options.bitrate.toInt(), handler, this)
    }

    private fun targetSize(metrics: DisplayMetrics): CaptureSize {
        val source = contentSize ?: CaptureSize(metrics.widthPixels, metrics.heightPixels)
        val align = when (options.codec) {
            NativeCodec.H264 -> H264_ALIGN
            NativeCodec.JPEG -> JPEG_ALIGN
        }

        return CaptureSize.fit(
            source.width,
            source.height,
            options.maxLongSide.toInt(),
            options.maxShortSide.toInt(),
            align,
        )
    }

    @Suppress("DEPRECATION")
    private fun screenMetrics(): DisplayMetrics {
        val metrics = DisplayMetrics()
        val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
        if (display == null) {
            return context.resources.displayMetrics
        }

        display.getRealMetrics(metrics)
        return metrics
    }

    private fun screenRotation(): Int {
        val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY) ?: return 0
        return display.rotation * QUARTER_TURN
    }

    companion object {
        private const val TAG = "FerretMirroring"
        private const val H264_ALIGN = 8
        private const val JPEG_ALIGN = 2
        private const val QUARTER_TURN = 90
        private const val REATTACH_DELAY_MS = 30L
    }
}
