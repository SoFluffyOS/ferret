package io.sofluffy.ferret_mirroring

/**
 * Joins the pieces that Android starts on its own (the consent activity and
 * the foreground service) with the plugin that talks to Dart.
 */
internal object MirrorBridge {
    /** Receives the capture's output. [onFrame] and [onConfig] arrive on the capture thread. */
    interface Listener {
        fun onConfig(config: NativeStreamConfig)

        fun onFrame(data: ByteArray, ptsUs: Long, keyframe: Boolean)

        fun onScreenOff(off: Boolean)

        fun onEnded(end: NativeCaptureEnd)
    }

    @Volatile
    var listener: Listener? = null

    /** The running service, between a granted consent and the end of the capture. */
    @Volatile
    var service: MirrorService? = null
}
