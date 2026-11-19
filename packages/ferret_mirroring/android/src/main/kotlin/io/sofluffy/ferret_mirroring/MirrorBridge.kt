package io.sofluffy.ferret_mirroring

/**
 * Joins the pieces that Android starts on its own (the consent activity and
 * the foreground service) with the plugin that talks to Dart.
 */
internal object MirrorBridge {
    /**
     * Receives the capture's output. [onFrame] and [onConfig] arrive on the
     * capture thread, the sound on a thread of its own.
     */
    interface Listener {
        fun onConfig(config: NativeStreamConfig)

        fun onFrame(data: ByteArray, ptsUs: Long, keyframe: Boolean)

        fun onScreenOff(off: Boolean)

        fun onAudioConfig(codec: NativeAudioCodec, sampleRate: Int, channels: Int)

        fun onAudioFrame(data: ByteArray, ptsUs: Long)

        /** Capturing the sound stopped working; the pictures go on. */
        fun onAudioEnded()

        fun onEnded(end: NativeCaptureEnd)
    }

    @Volatile
    var listener: Listener? = null

    /** The running service, between a granted consent and the end of the capture. */
    @Volatile
    var service: MirrorService? = null
}
