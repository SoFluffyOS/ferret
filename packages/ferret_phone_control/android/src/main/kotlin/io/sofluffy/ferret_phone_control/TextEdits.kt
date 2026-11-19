package io.sofluffy.ferret_phone_control

/** A text field's new content and where its cursor goes. */
data class TextEdit(val text: String, val cursor: Int)

/**
 * What typing does to a text field, worked out from its content and
 * selection. An accessibility service can't press keys: it reads the field
 * it is typing into, and writes the result back.
 */
object TextEdits {
    /** [typed] in place of the selection, or at the end of a field that has no cursor. */
    fun insert(current: String, selectionStart: Int, selectionEnd: Int, typed: String): TextEdit {
        val (start, end) = selection(current, selectionStart, selectionEnd)
        return TextEdit(current.substring(0, start) + typed + current.substring(end), start + typed.length)
    }

    /** The selection removed, or the character before the cursor. Null when there is nothing to remove. */
    fun backspace(current: String, selectionStart: Int, selectionEnd: Int): TextEdit? {
        val (start, end) = selection(current, selectionStart, selectionEnd)
        if (start != end) {
            return TextEdit(current.removeRange(start, end), start)
        }
        if (start == 0) {
            return null
        }

        val from = current.offsetByCodePoints(start, -1)
        return TextEdit(current.removeRange(from, start), from)
    }

    /** The selection removed, or the character after the cursor. Null when there is nothing to remove. */
    fun delete(current: String, selectionStart: Int, selectionEnd: Int): TextEdit? {
        val (start, end) = selection(current, selectionStart, selectionEnd)
        if (start != end) {
            return TextEdit(current.removeRange(start, end), start)
        }
        if (start >= current.length) {
            return null
        }

        val to = current.offsetByCodePoints(start, 1)
        return TextEdit(current.removeRange(start, to), start)
    }

    /** Where the cursor lands [steps] characters away, kept inside the text. */
    fun cursorAfter(current: String, selectionStart: Int, selectionEnd: Int, steps: Int): Int {
        val (start, end) = selection(current, selectionStart, selectionEnd)
        if (start != end) {
            return if (steps < 0) start else end
        }

        val codePoints = current.codePointCount(0, start)
        val target = (codePoints + steps).coerceIn(0, current.codePointCount(0, current.length))
        return current.offsetByCodePoints(0, target)
    }

    private fun selection(current: String, selectionStart: Int, selectionEnd: Int): Pair<Int, Int> {
        if (selectionStart < 0 || selectionEnd < 0) {
            return current.length to current.length
        }

        val first = minOf(selectionStart, selectionEnd).coerceIn(0, current.length)
        val second = maxOf(selectionStart, selectionEnd).coerceIn(0, current.length)
        return first to second
    }
}
