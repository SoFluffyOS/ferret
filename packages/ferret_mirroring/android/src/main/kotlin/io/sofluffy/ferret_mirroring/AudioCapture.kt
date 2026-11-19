package io.sofluffy.ferret_mirroring

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaFormat
import android.media.projection.MediaProjection
import android.os.Build
import android.util.Log
import android.annotation.TargetApi

/**
 * Captures what the phone plays (media and games, never the microphone)
 * with the same grant the screen is captured with, and hands it on as Opus
 * packets or plain samples. Apps that don't allow their sound to be
 * captured are simply not in it. Nothing is handed on while the phone is
 * silent.
 */
@TargetApi(Build.VERSION_CODES.Q)
internal class AudioCapture(
    private val projection: MediaProjection,
    private val codec: NativeAudioCodec,
    private val output: Output,
) {
    /** Called on the sound thread. */
    interface Output {
        fun onAudioConfig(codec: NativeAudioCodec, sampleRate: Int, channels: Int)

        fun onAudioFrame(data: ByteArray, ptsUs: Long)

        fun onAudioEnded()
    }

    private var record: AudioRecord? = null
    private var encoder: MediaCodec? = null
    private var thread: Thread? = null

    @Volatile
    private var running = false

    /** Throws when Android refuses the capture or has no encoder. */
    @SuppressLint("MissingPermission")
    fun start() {
        val capture = AudioPlaybackCaptureConfiguration.Builder(projection)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
            .build()
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(SAMPLE_RATE)
            .setChannelMask(AudioFormat.CHANNEL_IN_STEREO)
            .build()
        val smallest = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_STEREO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val created = AudioRecord.Builder()
            .setAudioFormat(format)
            .setBufferSizeInBytes(maxOf(smallest, CHUNK_BYTES * BUFFERED_CHUNKS))
            .setAudioPlaybackCaptureConfig(capture)
            .build()
        if (created.state != AudioRecord.STATE_INITIALIZED) {
            created.release()
            throw IllegalStateException("Android refused to capture the sound")
        }

        try {
            if (codec == NativeAudioCodec.OPUS) {
                encoder = createEncoder()
            }

            created.startRecording()
        } catch (error: Exception) {
            created.release()
            encoder?.release()
            encoder = null
            throw error
        }

        record = created
        running = true
        thread = Thread({ run(created) }, "ferret-mirror-sound").apply { start() }
    }

    fun release() {
        running = false
        try {
            record?.stop()
        } catch (error: IllegalStateException) {
            Log.w(TAG, "The sound capture was not running", error)
        }

        try {
            thread?.join(JOIN_MS)
        } catch (error: InterruptedException) {
            Thread.currentThread().interrupt()
        }

        thread = null
        record?.release()
        record = null
        try {
            encoder?.stop()
        } catch (error: IllegalStateException) {
            Log.w(TAG, "The sound encoder was not running", error)
        }

        encoder?.release()
        encoder = null
    }

    private fun run(record: AudioRecord) {
        val chunk = ByteArray(CHUNK_BYTES)
        var silentChunks = 0
        try {
            output.onAudioConfig(codec, SAMPLE_RATE, CHANNELS)
            while (running) {
                val read = record.read(chunk, 0, chunk.size)
                if (!running) {
                    return
                }

                if (read <= 0) {
                    throw IllegalStateException("Reading the sound failed ($read)")
                }

                silentChunks = if (isSilent(chunk, read)) silentChunks + 1 else 0
                if (silentChunks > SILENT_CHUNKS_SENT) {
                    continue
                }

                val ptsUs = System.nanoTime() / NANOS_PER_MICRO - durationUs(read)
                hand(chunk, read, ptsUs)
            }
        } catch (error: Throwable) {
            Log.w(TAG, "Capturing the sound stopped", error)
            if (running) {
                running = false
                output.onAudioEnded()
            }
        }
    }

    private fun hand(chunk: ByteArray, length: Int, ptsUs: Long) {
        val opus = encoder
        if (opus == null) {
            output.onAudioFrame(chunk.copyOf(length), ptsUs)
            return
        }

        val index = opus.dequeueInputBuffer(ENCODER_WAIT_US)
        if (index >= 0) {
            val input = opus.getInputBuffer(index)
            if (input != null) {
                input.clear()
                val size = minOf(length, input.capacity())
                input.put(chunk, 0, size)
                opus.queueInputBuffer(index, 0, size, ptsUs, 0)
            }
        }

        drain(opus)
    }

    private fun drain(opus: MediaCodec) {
        val info = MediaCodec.BufferInfo()
        while (true) {
            val index = opus.dequeueOutputBuffer(info, 0)
            if (index == MediaCodec.INFO_TRY_AGAIN_LATER) {
                return
            }

            if (index < 0) {
                continue
            }

            val isHeader = info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
            val packet = opus.getOutputBuffer(index)
            if (!isHeader && packet != null && info.size > 0) {
                val data = ByteArray(info.size)
                packet.position(info.offset)
                packet.get(data)
                output.onAudioFrame(data, info.presentationTimeUs)
            }

            opus.releaseOutputBuffer(index, false)
        }
    }

    private fun createEncoder(): MediaCodec {
        val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_OPUS, SAMPLE_RATE, CHANNELS).apply {
            setInteger(MediaFormat.KEY_BIT_RATE, OPUS_BITRATE)
            setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, CHUNK_BYTES)
        }
        val created = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_OPUS)
        try {
            created.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            created.start()
        } catch (error: Exception) {
            created.release()
            throw error
        }

        return created
    }

    private fun isSilent(chunk: ByteArray, length: Int): Boolean {
        for (index in 0 until length) {
            if (chunk[index] != 0.toByte()) {
                return false
            }
        }

        return true
    }

    private fun durationUs(bytes: Int): Long = bytes.toLong() * MICROS_PER_SECOND / (SAMPLE_RATE * BYTES_PER_FRAME)

    companion object {
        private const val TAG = "FerretMirroring"
        private const val SAMPLE_RATE = 48_000
        private const val CHANNELS = 2
        private const val BYTES_PER_FRAME = 4

        /** 20 ms, the length of one Opus packet. */
        private const val CHUNK_BYTES = SAMPLE_RATE / 50 * BYTES_PER_FRAME
        private const val BUFFERED_CHUNKS = 4

        /** Silence that still goes out after the last sound, so its tail isn't cut. */
        private const val SILENT_CHUNKS_SENT = 10
        private const val OPUS_BITRATE = 128_000
        private const val ENCODER_WAIT_US = 10_000L
        private const val JOIN_MS = 500L
        private const val NANOS_PER_MICRO = 1_000L
        private const val MICROS_PER_SECOND = 1_000_000L

        /** Whether this phone can capture what it plays, as things stand now. */
        fun support(context: Context): NativeAudioSupport {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                return NativeAudioSupport.UNSUPPORTED
            }

            val granted = context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
            return if (granted) NativeAudioSupport.READY else NativeAudioSupport.NEEDS_PERMISSION
        }
    }
}
