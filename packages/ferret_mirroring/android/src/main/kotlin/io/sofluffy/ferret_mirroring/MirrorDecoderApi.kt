package io.sofluffy.ferret_mirroring

import android.util.Log
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Dart's H.264 decoder on Android: [H264Decoder] drawing into a Flutter
 * texture (a SurfaceProducer). Flutter may take the surface away while the
 * app is in the background; decoding waits for the next one and asks for
 * a keyframe then.
 */
internal class MirrorDecoderApi(
    private val textures: TextureRegistry,
    private val flutterApi: MirrorDecoderFlutterApi,
    private val scope: CoroutineScope,
) : MirrorDecoderHostApi, H264Decoder.Listener {
    private var producer: TextureRegistry.SurfaceProducer? = null
    private var decoder: H264Decoder? = null

    /** The size last told to Dart. */
    @Volatile
    private var told: SpsSize? = null

    override fun create(): Long {
        producer?.let { return it.id() }

        val created = textures.createSurfaceProducer()
        created.setSize(DEFAULT_SIDE, DEFAULT_SIDE)
        producer = created
        val decoding = H264Decoder(this)
        decoder = decoding
        created.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
            override fun onSurfaceAvailable() {
                decoding.setSurface(created.surface)
            }

            override fun onSurfaceCleanup() {
                decoding.setSurface(null)
            }
        })
        return created.id()
    }

    override fun configure(sps: ByteArray, pps: ByteArray) {
        val producer = producer ?: throw FlutterError("no-texture", "create() comes first")
        val decoding = decoder ?: throw FlutterError("no-texture", "create() comes first")
        val size = SpsSize.parse(sps) ?: throw FlutterError("bad-sps", "The parameter sets can't be read")
        if (producer.width != size.codedWidth || producer.height != size.codedHeight) {
            producer.setSize(size.codedWidth, size.codedHeight)
        }

        told = null
        decoding.configure(sps, pps)
        decoding.setSurface(producer.surface)
    }

    override fun decode(data: ByteArray, ptsUs: Long, keyframe: Boolean) {
        decoder?.decode(data, ptsUs, keyframe)
    }

    override fun dispose() {
        decoder?.release()
        decoder = null
        producer?.release()
        producer = null
        told = null
    }

    /** Reading the texture back isn't done here: there is no picture to save. */
    override suspend fun savePicture(path: String): Boolean = false

    override fun canFullScreen(): Boolean = false

    override fun isFullScreen(): Boolean = false

    override fun setFullScreen(fullScreen: Boolean) {}

    override fun onPicture(ptsUs: Long, size: SpsSize) {
        val newSize = told != size
        told = size
        val handlesCrop = producer?.handlesCropAndRotation() ?: true
        scope.launch {
            try {
                if (newSize && handlesCrop) {
                    flutterApi.onBufferSize(size.width.toLong(), size.height.toLong(), 0, 0)
                }

                if (newSize && !handlesCrop) {
                    flutterApi.onBufferSize(
                        size.codedWidth.toLong(),
                        size.codedHeight.toLong(),
                        size.cropLeft.toLong(),
                        size.cropTop.toLong(),
                    )
                }

                flutterApi.onDecoded(ptsUs, size.width.toLong(), size.height.toLong())
            } catch (error: Throwable) {
                Log.w(TAG, "Dart did not take a picture", error)
            }
        }
    }

    override fun onError(status: Int) {
        scope.launch {
            try {
                flutterApi.onDecodeError(status.toLong())
            } catch (error: Throwable) {
                Log.w(TAG, "Dart did not take a decoder error", error)
            }
        }
    }

    companion object {
        private const val TAG = "FerretMirrorDecoder"
        private const val DEFAULT_SIDE = 16
    }
}
