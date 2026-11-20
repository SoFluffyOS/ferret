package io.sofluffy.ferret_mirroring

import kotlin.math.abs

/** What to ask a camera for, worked out from what it offers. */
internal object CameraPlan {
    private const val FULL_TURN = 360
    private const val QUARTER_TURN = 90

    /** How far past a quarter the phone has to tip before the picture turns. */
    private const val TURN_SLACK = 60

    /** 16:9, the shape video apps expect from a webcam. */
    private const val WIDE = 16.0 / 9.0

    /**
     * The biggest of [sizes] that fits [maxLongSide] by [maxShortSide],
     * 16:9 before any other shape. Null when nothing fits.
     */
    fun size(sizes: List<CaptureSize>, maxLongSide: Int, maxShortSide: Int): CaptureSize? {
        val fitting = sizes.filter { size ->
            maxOf(size.width, size.height) <= maxLongSide && minOf(size.width, size.height) <= maxShortSide
        }
        val wide = fitting.filter { size -> abs(size.width.toDouble() / size.height - WIDE) < 0.02 }

        return wide.ifEmpty { fitting }.maxByOrNull { size -> size.width.toLong() * size.height }
    }

    /**
     * The steadiest of the camera's frame rate [ranges] (lowest to highest)
     * that tops out at [fps]; else the one whose top is nearest.
     */
    fun fpsRange(ranges: List<Pair<Int, Int>>, fps: Int): Pair<Int, Int>? {
        val exact = ranges.filter { range -> range.second == fps }.maxByOrNull { range -> range.first }
        if (exact != null) {
            return exact
        }

        return ranges.minWithOrNull(compareBy({ range -> abs(range.second - fps) }, { range -> -range.first }))
    }

    /**
     * Degrees clockwise to turn a picture so it shows upright: the sensor
     * sits [sensorOrientation] degrees from the phone's upright, and the
     * phone is held [deviceDegrees] clockwise from it.
     */
    fun turn(sensorOrientation: Int, deviceDegrees: Int, front: Boolean): Int {
        val device = if (front) -deviceDegrees else deviceDegrees
        return ((sensorOrientation + device) % FULL_TURN + FULL_TURN) % FULL_TURN
    }

    /**
     * The quarter turn the phone is held at, from the [degrees] its
     * sensor says. It stays at [current] until the phone has clearly
     * tipped over to another, so a phone held at an angle doesn't flip
     * back and forth.
     */
    fun snap(degrees: Int, current: Int): Int {
        if (degrees < 0) {
            return current
        }

        val away = abs(degrees - current).let { gap -> minOf(gap, FULL_TURN - gap) }
        if (away <= TURN_SLACK) {
            return current
        }

        return ((degrees + QUARTER_TURN / 2) / QUARTER_TURN * QUARTER_TURN) % FULL_TURN
    }
}
