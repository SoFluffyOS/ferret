package io.sofluffy.ferret_mirroring

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.util.Log
import android.view.Surface
import java.nio.ByteBuffer

/**
 * Hardware H.264 through MediaCodec with a surface input, tuned for a live
 * picture: constrained baseline (no B-frames, so nothing waits for a later
 * frame), a keyframe every two seconds, and the last frame repeated when
 * the screen stands still so a viewer that joins late gets a picture.
 */
internal class H264Encoder(
    private val size: CaptureSize,
    private val rotation: Int,
    private val fps: Int,
    bitrate: Int,
    handler: Handler,
    private val output: EncoderOutput,
) : FrameEncoder {
    private val codec: MediaCodec
    override val surface: Surface
    override val needsFreshFrame = true

    @Volatile
    private var released = false

    init {
        val created = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        codec = configure(created, bitrate)
        codec.setCallback(Callback(), handler)
        surface = codec.createInputSurface()
        codec.start()
    }

    override fun requestKeyframe() {
        setParameter(MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME, 0)
    }

    override fun setBitrate(bitrate: Int) {
        setParameter(MediaCodec.PARAMETER_KEY_VIDEO_BITRATE, bitrate)
    }

    override fun release() {
        if (released) {
            return
        }

        released = true
        try {
            codec.stop()
        } catch (error: IllegalStateException) {
            Log.w(TAG, "Encoder was not running when stopped", error)
        }

        codec.release()
        surface.release()
    }

    /** Tries the low-latency profile first; some encoders only take the plain format. */
    private fun configure(created: MediaCodec, bitrate: Int): MediaCodec {
        try {
            created.configure(format(bitrate, tuned = true), null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            return created
        } catch (error: Exception) {
            Log.w(TAG, "Encoder refused the tuned format; using the plain one", error)
            created.release()
        }

        val plain = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        try {
            plain.configure(format(bitrate, tuned = false), null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        } catch (error: Exception) {
            plain.release()
            throw error
        }

        return plain
    }

    private fun format(bitrate: Int, tuned: Boolean): MediaFormat =
        MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, size.width, size.height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, KEYFRAME_INTERVAL_SECONDS)
            setLong(MediaFormat.KEY_REPEAT_PREVIOUS_FRAME_AFTER, REPEAT_FRAME_AFTER_US)
            setFloat(KEY_MAX_FPS_TO_ENCODER, fps.toFloat())
            if (!tuned) {
                return@apply
            }

            setInteger(MediaFormat.KEY_BITRATE_MODE, MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR)
            setInteger(MediaFormat.KEY_PRIORITY, PRIORITY_REALTIME)
            setInteger(MediaFormat.KEY_PROFILE, baselineProfile())
            setInteger(MediaFormat.KEY_LEVEL, MediaCodecInfo.CodecProfileLevel.AVCLevel42)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                setInteger(MediaFormat.KEY_LATENCY, 0)
            }
        }

    private fun baselineProfile(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            return MediaCodecInfo.CodecProfileLevel.AVCProfileConstrainedBaseline
        }

        return MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline
    }

    private fun setParameter(key: String, value: Int) {
        if (released) {
            return
        }

        try {
            codec.setParameters(Bundle().apply { putInt(key, value) })
        } catch (error: IllegalStateException) {
            Log.w(TAG, "Encoder did not take $key", error)
        }
    }

    private inner class Callback : MediaCodec.Callback() {
        override fun onInputBufferAvailable(codec: MediaCodec, index: Int) = Unit

        override fun onOutputBufferAvailable(codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo) {
            if (released) {
                return
            }

            try {
                val isConfig = info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
                val buffer = codec.getOutputBuffer(index)
                if (buffer != null && info.size > 0 && !isConfig) {
                    val data = ByteArray(info.size)
                    buffer.position(info.offset)
                    buffer.get(data)
                    val keyframe = info.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME != 0
                    output.onFrame(data, info.presentationTimeUs, keyframe)
                }

                codec.releaseOutputBuffer(index, false)
            } catch (error: IllegalStateException) {
                output.onEncoderError(error)
            }
        }

        override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) {
            val sps = parameterSet(format.getByteBuffer("csd-0"))
            val pps = parameterSet(format.getByteBuffer("csd-1"))
            if (sps == null || pps == null) {
                output.onEncoderError(IllegalStateException("Encoder gave no parameter sets"))
                return
            }

            output.onConfig(
                NativeStreamConfig(
                    codec = NativeCodec.H264,
                    width = size.width.toLong(),
                    height = size.height.toLong(),
                    rotation = rotation.toLong(),
                    fps = fps.toLong(),
                    sps = sps,
                    pps = pps,
                ),
            )
        }

        override fun onError(codec: MediaCodec, error: MediaCodec.CodecException) {
            if (!released) {
                output.onEncoderError(error)
            }
        }
    }

    companion object {
        private const val TAG = "FerretMirroring"
        private const val KEYFRAME_INTERVAL_SECONDS = 2
        private const val REPEAT_FRAME_AFTER_US = 100_000L
        private const val PRIORITY_REALTIME = 0
        private const val KEY_MAX_FPS_TO_ENCODER = "max-fps-to-encoder"

        fun isSupported(): Boolean =
            MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.any { info ->
                info.isEncoder && info.supportedTypes.any { it.equals(MediaFormat.MIMETYPE_VIDEO_AVC, ignoreCase = true) }
            }

        /** One NAL unit from a `csd` buffer, without its Annex-B start code. */
        fun parameterSet(buffer: ByteBuffer?): ByteArray? {
            if (buffer == null) {
                return null
            }

            val bytes = ByteArray(buffer.remaining())
            buffer.duplicate().get(bytes)
            return stripStartCode(bytes)
        }

        fun stripStartCode(bytes: ByteArray): ByteArray {
            val start = when {
                bytes.size > 4 && bytes[0] == ZERO && bytes[1] == ZERO && bytes[2] == ZERO && bytes[3] == ONE -> 4
                bytes.size > 3 && bytes[0] == ZERO && bytes[1] == ZERO && bytes[2] == ONE -> 3
                else -> 0
            }

            return bytes.copyOfRange(start, bytes.size)
        }

        private const val ZERO: Byte = 0
        private const val ONE: Byte = 1
    }
}
