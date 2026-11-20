package io.sofluffy.ferret_drop

/**
 * Picks what a share hands over. [streams] come from EXTRA_STREAM, [clipItems]
 * from the intent's ClipData.
 *
 * A link shared from Chrome carries the link in EXTRA_TEXT and the page's
 * preview image only in ClipData, for the share sheet's preview. That image
 * is not what was shared: with text and no stream, the text wins.
 */
internal object SharedContent {
    fun <T> files(streams: List<T>, clipItems: List<T>, text: String?): List<T> {
        if (streams.isNotEmpty()) {
            return streams.distinct()
        }

        if (!text.isNullOrEmpty()) {
            return emptyList()
        }

        return clipItems.distinct()
    }
}
