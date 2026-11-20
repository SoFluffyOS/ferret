package io.sofluffy.ferret_mirroring

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.view.Surface
import java.util.ArrayDeque
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Decodes a live H.264 stream (Annex-B access units) with MediaCodec onto
 * a [Surface], on a thread of its own. Tuned for a picture that must show
 * the moment it arrives: low latency where the decoder has it, realtime
 * priority, and each picture rendered as soon as it is out. Not tied to
 * Flutter: whoever owns the surface hands it over with [setSurface].
 */
internal class H264Decoder(private val listener: Listener) {
    interface Listener {
        /**
         * A picture went to the surface. Its buffer is [size]'s coded size
         * and the part shown starts at its crop. On the decoder's thread.
         */
        fun onPicture(ptsUs: Long, size: SpsSize)

        /** A frame couldn't be decoded; the next one must be a keyframe. On the decoder's thread. */
        fun onError(status: Int)
    }

    private class Frame(val data: ByteArray, val ptsUs: Long, val keyframe: Boolean)

    private val thread = HandlerThread("FerretH264Decoder").apply { start() }
    private val handler = Handler(thread.looper)
    private val freeInputs = ArrayDeque<Int>()
    private val waiting = ArrayDeque<Frame>()
    private var codec: MediaCodec? = null
    private var surface: Surface? = null
    private var sps: ByteArray? = null
    private var pps: ByteArray? = null
    private var size: SpsSize? = null
    private var needsKeyframe = true
    private var released = false

    /** Sets up for a stream with these parameter sets (NAL units without start codes). */
    fun configure(sps: ByteArray, pps: ByteArray): SpsSize? {
        val parsed = SpsSize.parse(sps)
        handler.post {
            this.sps = sps
            this.pps = pps
            size = parsed
            needsKeyframe = true
            closeCodec()
            openCodec()
        }
        return parsed
    }

    /** Where pictures go, or null while there is nowhere: decoding waits for a surface. */
    fun setSurface(surface: Surface?) {
        runOnThread {
            this.surface = surface
            val running = codec
            if (surface == null || running == null) {
                closeCodec()
                openCodec()
                if (codec != null) {
                    // A new decoder has no pictures to build on yet.
                    fail(STATUS_RESTARTED)
                }

                return@runOnThread
            }

            try {
                running.setOutputSurface(surface)
            } catch (error: RuntimeException) {
                Log.w(TAG, "The decoder couldn't move to the new surface", error)
                closeCodec()
                openCodec()
            }
        }
    }

    fun decode(data: ByteArray, ptsUs: Long, keyframe: Boolean) {
        handler.post {
            if (released) {
                return@post
            }

            val startsPicture = keyframe || AnnexB.hasIdr(data)
            if (needsKeyframe && !startsPicture) {
                return@post
            }

            if (waiting.size >= MAX_WAITING) {
                waiting.clear()
                fail(STATUS_BEHIND)
                if (!startsPicture) {
                    return@post
                }
            }

            needsKeyframe = false
            waiting.add(Frame(data, ptsUs, startsPicture))
            feed()
        }
    }

    /** Stops for good. Returns once the decoder no longer touches the surface. */
    fun release() {
        runOnThread {
            released = true
            closeCodec()
            surface = null
        }
        thread.quitSafely()
    }

    /** Runs [block] on the decoder's thread and waits for it, so the surface can be taken away right after. */
    private fun runOnThread(block: () -> Unit) {
        if (Thread.currentThread() == thread) {
            block()
            return
        }

        val done = CountDownLatch(1)
        val posted = handler.post {
            try {
                block()
            } finally {
                done.countDown()
            }
        }
        if (posted) {
            done.await(WAIT_SECONDS, TimeUnit.SECONDS)
        }
    }

    private fun openCodec() {
        val sps = sps ?: return
        val pps = pps ?: return
        val surface = surface ?: return
        if (released || codec != null || !surface.isValid) {
            return
        }

        val size = size
        val format = MediaFormat.createVideoFormat(
            MediaFormat.MIMETYPE_VIDEO_AVC,
            size?.width ?: DEFAULT_WIDTH,
            size?.height ?: DEFAULT_HEIGHT,
        )
        format.setByteBuffer("csd-0", java.nio.ByteBuffer.wrap(AnnexB.withStartCode(sps)))
        format.setByteBuffer("csd-1", java.nio.ByteBuffer.wrap(AnnexB.withStartCode(pps)))

        val created = try {
            MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        } catch (error: Exception) {
            Log.w(TAG, "No H.264 decoder here", error)
            fail(STATUS_NO_DECODER)
            return
        }

        val started = start(created, lowLatency(created, MediaFormat(format)), surface) ||
            start(created, format, surface)
        if (!started) {
            created.release()
            fail(STATUS_CONFIGURE)
            return
        }

        codec = created
        freeInputs.clear()
        needsKeyframe = true
    }

    private fun start(codec: MediaCodec, format: MediaFormat, surface: Surface): Boolean = try {
        codec.setCallback(Callback(codec), handler)
        codec.configure(format, surface, null, 0)
        codec.start()
        true
    } catch (error: Exception) {
        Log.w(TAG, "The decoder refused $format", error)
        try {
            codec.reset()
        } catch (ignored: Exception) {
        }
        false
    }

    /** [format] asking for the picture as soon as it is decoded, where the decoder can. */
    private fun lowLatency(codec: MediaCodec, format: MediaFormat): MediaFormat {
        format.setInteger(MediaFormat.KEY_PRIORITY, 0)
        format.setInteger(MediaFormat.KEY_OPERATING_RATE, Short.MAX_VALUE.toInt())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val capabilities = try {
                codec.codecInfo.getCapabilitiesForType(MediaFormat.MIMETYPE_VIDEO_AVC)
            } catch (error: IllegalArgumentException) {
                null
            }
            val supported = capabilities?.isFeatureSupported(MediaCodecInfo.CodecCapabilities.FEATURE_LowLatency) ?: false
            if (supported) {
                format.setInteger(MediaFormat.KEY_LOW_LATENCY, 1)
            }
        }

        return format
    }

    private fun closeCodec() {
        val running = codec ?: return
        codec = null
        freeInputs.clear()
        waiting.clear()
        try {
            running.stop()
        } catch (error: IllegalStateException) {
            Log.w(TAG, "Decoder was not running when stopped", error)
        }

        running.release()
    }

    private fun feed() {
        val running = codec ?: return
        while (freeInputs.isNotEmpty() && waiting.isNotEmpty()) {
            val index = freeInputs.poll() ?: return
            val frame = waiting.poll() ?: return
            try {
                val buffer = running.getInputBuffer(index)
                if (buffer == null || buffer.capacity() < frame.data.size) {
                    running.queueInputBuffer(index, 0, 0, frame.ptsUs, 0)
                    fail(STATUS_TOO_BIG)
                    continue
                }

                buffer.clear()
                buffer.put(frame.data)
                val flags = if (frame.keyframe) MediaCodec.BUFFER_FLAG_KEY_FRAME else 0
                running.queueInputBuffer(index, 0, frame.data.size, frame.ptsUs, flags)
            } catch (error: IllegalStateException) {
                Log.w(TAG, "The decoder didn't take a frame", error)
                fail(STATUS_INPUT)
                return
            }
        }
    }

    private fun fail(status: Int) {
        needsKeyframe = true
        listener.onError(status)
    }

    private inner class Callback(private val owner: MediaCodec) : MediaCodec.Callback() {
        override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
            if (owner !== this@H264Decoder.codec) {
                return
            }

            freeInputs.add(index)
            feed()
        }

        override fun onOutputBufferAvailable(codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo) {
            if (owner !== this@H264Decoder.codec) {
                return
            }

            val ended = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
            try {
                codec.releaseOutputBuffer(index, !ended)
            } catch (error: IllegalStateException) {
                return
            }

            val shown = size
            if (!ended && shown != null) {
                listener.onPicture(info.presentationTimeUs, shown)
            }
        }

        override fun onError(codec: MediaCodec, error: MediaCodec.CodecException) {
            if (owner !== this@H264Decoder.codec) {
                return
            }

            Log.w(TAG, "The decoder failed", error)
            if (!error.isTransient) {
                // Not from inside the codec's own callback.
                handler.post {
                    if (owner === this@H264Decoder.codec) {
                        closeCodec()
                        openCodec()
                    }
                }
            }

            fail(error.errorCode)
        }

        override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) {
            if (owner !== this@H264Decoder.codec) {
                return
            }

            sizeOf(format)?.let { size = it }
        }
    }

    companion object {
        private const val TAG = "FerretH264Decoder"

        /** Frames that may wait for the decoder before the rest are dropped up to a keyframe. */
        private const val MAX_WAITING = 8
        private const val WAIT_SECONDS = 2L
        private const val DEFAULT_WIDTH = 1920
        private const val DEFAULT_HEIGHT = 1080
        const val STATUS_NO_DECODER = -1
        const val STATUS_CONFIGURE = -2
        const val STATUS_INPUT = -3
        const val STATUS_TOO_BIG = -4
        const val STATUS_BEHIND = -5
        const val STATUS_RESTARTED = -6

        /** The buffer size and the shown part the decoder reports, or null when it says neither. */
        fun sizeOf(format: MediaFormat): SpsSize? {
            if (!format.containsKey(MediaFormat.KEY_WIDTH) || !format.containsKey(MediaFormat.KEY_HEIGHT)) {
                return null
            }

            val width = format.getInteger(MediaFormat.KEY_WIDTH)
            val height = format.getInteger(MediaFormat.KEY_HEIGHT)
            val hasCrop = format.containsKey(CROP_LEFT) && format.containsKey(CROP_RIGHT) &&
                format.containsKey(CROP_TOP) && format.containsKey(CROP_BOTTOM)
            if (!hasCrop) {
                return SpsSize(width, height, 0, 0, width, height)
            }

            val left = format.getInteger(CROP_LEFT)
            val top = format.getInteger(CROP_TOP)
            val shownWidth = format.getInteger(CROP_RIGHT) - left + 1
            val shownHeight = format.getInteger(CROP_BOTTOM) - top + 1
            if (shownWidth <= 0 || shownHeight <= 0) {
                return SpsSize(width, height, 0, 0, width, height)
            }

            return SpsSize(width, height, left, top, shownWidth, shownHeight)
        }

        private const val CROP_LEFT = "crop-left"
        private const val CROP_RIGHT = "crop-right"
        private const val CROP_TOP = "crop-top"
        private const val CROP_BOTTOM = "crop-bottom"
    }
}
