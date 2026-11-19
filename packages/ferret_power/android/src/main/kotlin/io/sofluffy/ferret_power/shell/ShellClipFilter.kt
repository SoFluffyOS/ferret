package io.sofluffy.ferret_power.shell

/**
 * Decides from a clip's description alone whether the watcher needs its
 * content. Reading the content as the shell user shows Android's "Shell
 * pasted from your clipboard" toast, so the watcher reads only clips it may
 * send: text that Ferret did not just put there itself.
 */
object ShellClipFilter {
    /** The label ferret_clipboard gives the clips Ferret writes. */
    const val OWN_LABEL = "Ferret"

    /** When Ferret wrote the clip, in [System.currentTimeMillis]. */
    const val EXTRA_WRITTEN_AT = "io.sofluffy.ferret.extra.WRITTEN_AT"

    /** A change this long after Ferret's write is treated as someone else's. */
    const val WINDOW_MS = 30_000L

    private const val URI_LIST = "text/uri-list"

    fun shouldRead(label: CharSequence?, writtenAt: Long, mimeTypes: List<String>, now: Long): Boolean {
        if (isOwn(label, writtenAt, now)) {
            return false
        }

        return mimeTypes.isEmpty() || mimeTypes.any { it.startsWith("text/") && it != URI_LIST }
    }

    fun isOwn(label: CharSequence?, writtenAt: Long, now: Long): Boolean {
        if (label?.toString() != OWN_LABEL || writtenAt <= 0L) {
            return false
        }

        return kotlin.math.abs(now - writtenAt) <= WINDOW_MS
    }
}
