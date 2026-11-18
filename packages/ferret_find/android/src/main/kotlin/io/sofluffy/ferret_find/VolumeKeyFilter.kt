package io.sofluffy.ferret_find

/**
 * Tells a volume key press apart from the volume changes Ferret makes
 * itself: changes within [graceMs] of Ferret's own are ignored.
 */
internal class VolumeKeyFilter(private val graceMs: Long = 1500) {
    private var ignoreUntilMs = 0L

    /** Ferret is about to change the volume itself. */
    fun ownChange(nowMs: Long) {
        ignoreUntilMs = nowMs + graceMs
    }

    fun isKeyPress(nowMs: Long): Boolean = nowMs >= ignoreUntilMs
}
