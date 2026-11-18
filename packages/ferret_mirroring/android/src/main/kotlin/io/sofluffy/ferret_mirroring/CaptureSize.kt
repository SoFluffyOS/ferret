package io.sofluffy.ferret_mirroring

import kotlin.math.max
import kotlin.math.min

/** The picture size to capture at: the screen scaled down to fit the limits. */
internal data class CaptureSize(val width: Int, val height: Int) {
    companion object {
        /**
         * Scales [width] x [height] down (never up) so the long side fits
         * [maxLongSide] and the short side [maxShortSide], with both sides
         * a multiple of [align] as video encoders want.
         */
        fun fit(width: Int, height: Int, maxLongSide: Int, maxShortSide: Int, align: Int): CaptureSize {
            val longSide = max(width, height).coerceAtLeast(1)
            val shortSide = min(width, height).coerceAtLeast(1)
            val scale = min(1.0, min(maxLongSide.toDouble() / longSide, maxShortSide.toDouble() / shortSide))

            return CaptureSize(snap(width * scale, align), snap(height * scale, align))
        }

        private fun snap(value: Double, align: Int): Int = max(align, (value.toInt() / align) * align)
    }
}
