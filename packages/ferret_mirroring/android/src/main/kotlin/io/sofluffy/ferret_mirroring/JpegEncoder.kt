package io.sofluffy.ferret_mirroring

import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.media.ImageReader
import android.os.Handler
import android.os.SystemClock
import android.view.Surface
import java.io.ByteArrayOutputStream

/**
 * The fallback for viewers without a video decoder: reads the screen as
 * bitmaps and sends each as a JPEG, a few times per second.
 */
internal class JpegEncoder(
    private val size: CaptureSize,
    rotation: Int,
    private val fps: Int,
    private val handler: Handler,
    private val output: EncoderOutput,
) : FrameEncoder {
    private val reader = ImageReader.newInstance(size.width, size.height, PixelFormat.RGBA_8888, MAX_IMAGES)
    private val frameGapMs = 1000L / fps.coerceAtLeast(1)
    private var lastFrameAtMs = 0L
    private var lastJpeg: ByteArray? = null
    private var padded: Bitmap? = null

    @Volatile
    private var released = false

    override val surface: Surface = reader.surface
    override val needsFreshFrame = false

    init {
        reader.setOnImageAvailableListener({ onImage() }, handler)
        handler.post {
            output.onConfig(
                NativeStreamConfig(
                    codec = NativeCodec.JPEG,
                    width = size.width.toLong(),
                    height = size.height.toLong(),
                    rotation = rotation.toLong(),
                    fps = fps.toLong(),
                ),
            )
        }
    }

    /** Every JPEG decodes on its own, so a keyframe is the last picture again. */
    override fun requestKeyframe() {
        handler.post {
            val jpeg = lastJpeg
            if (jpeg != null && !released) {
                output.onFrame(jpeg, SystemClock.elapsedRealtimeNanos() / 1000, true)
            }
        }
    }

    override fun setBitrate(bitrate: Int) = Unit

    override fun release() {
        if (released) {
            return
        }

        released = true
        reader.setOnImageAvailableListener(null, null)
        reader.close()
        padded?.recycle()
        padded = null
    }

    private fun onImage() {
        if (released) {
            return
        }

        val image = try {
            reader.acquireLatestImage()
        } catch (error: IllegalStateException) {
            output.onEncoderError(error)
            null
        } ?: return

        try {
            val now = SystemClock.elapsedRealtime()
            if (now - lastFrameAtMs < frameGapMs) {
                return
            }

            lastFrameAtMs = now
            val plane = image.planes[0]
            val rowPixels = plane.rowStride / plane.pixelStride
            val bitmap = paddedBitmap(rowPixels)
            bitmap.copyPixelsFromBuffer(plane.buffer)
            val jpeg = compress(bitmap, rowPixels)
            lastJpeg = jpeg
            output.onFrame(jpeg, image.timestamp / 1000, true)
        } catch (error: RuntimeException) {
            output.onEncoderError(error)
        } finally {
            image.close()
        }
    }

    /** Rows may be wider than the picture; the bitmap matches the rows. */
    private fun paddedBitmap(rowPixels: Int): Bitmap {
        val current = padded
        if (current != null && current.width == rowPixels) {
            return current
        }

        current?.recycle()
        val created = Bitmap.createBitmap(rowPixels, size.height, Bitmap.Config.ARGB_8888)
        padded = created
        return created
    }

    private fun compress(bitmap: Bitmap, rowPixels: Int): ByteArray {
        val bytes = ByteArrayOutputStream(INITIAL_JPEG_BYTES)
        if (rowPixels == size.width) {
            bitmap.compress(Bitmap.CompressFormat.JPEG, QUALITY, bytes)
            return bytes.toByteArray()
        }

        val cropped = Bitmap.createBitmap(bitmap, 0, 0, size.width, size.height)
        cropped.compress(Bitmap.CompressFormat.JPEG, QUALITY, bytes)
        cropped.recycle()
        return bytes.toByteArray()
    }

    companion object {
        private const val MAX_IMAGES = 2
        private const val QUALITY = 60
        private const val INITIAL_JPEG_BYTES = 256 * 1024
    }
}
