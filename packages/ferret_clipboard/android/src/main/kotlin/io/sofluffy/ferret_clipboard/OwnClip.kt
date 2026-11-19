package io.sofluffy.ferret_clipboard

/**
 * How Ferret marks the clips it puts on the clipboard, so a watcher can tell
 * them apart from the clip's description alone. Reading the content of a clip
 * another app set shows Android's "pasted from your clipboard" toast, while the
 * description is free. Ferret's shell helper (ferret_power) uses the same label
 * and extra.
 */
object OwnClip {
    const val LABEL = "Ferret"

    /** When Ferret wrote the clip, in [System.currentTimeMillis]. */
    const val EXTRA_WRITTEN_AT = "io.sofluffy.ferret.extra.WRITTEN_AT"

    /** A change this long after Ferret's write is treated as someone else's. */
    const val WINDOW_MS = 30_000L

    /** Whether a clip with this [label] and [writtenAt] is the one Ferret just wrote. */
    fun isOwn(label: CharSequence?, writtenAt: Long, now: Long): Boolean {
        if (label?.toString() != LABEL || writtenAt <= 0L) {
            return false
        }

        return kotlin.math.abs(now - writtenAt) <= WINDOW_MS
    }
}
