package io.sofluffy.ferret_mirroring

import android.view.Surface

/** Turns what is drawn on [surface] into frames for [EncoderOutput]. */
internal interface FrameEncoder {
    val surface: Surface

    /** A keyframe only comes with a new picture drawn on [surface]. */
    val needsFreshFrame: Boolean

    fun requestKeyframe()

    fun setBitrate(bitrate: Int)

    fun release()
}

/** Where an encoder's output goes. Called on the capture thread. */
internal interface EncoderOutput {
    fun onConfig(config: NativeStreamConfig)

    fun onFrame(data: ByteArray, ptsUs: Long, keyframe: Boolean)

    fun onEncoderError(error: Throwable)
}
