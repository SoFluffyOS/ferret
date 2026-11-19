package io.sofluffy.ferret_phone_control

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class TextEditsTest {
    @Test
    fun typingGoesAtTheCursor() {
        assertEquals(TextEdit("help me", 4), TextEdits.insert("hel me", 3, 3, "p"))
    }

    @Test
    fun typingReplacesTheSelection() {
        assertEquals(TextEdit("hi there", 8), TextEdits.insert("hi you", 3, 6, "there"))
    }

    @Test
    fun aFieldWithoutACursorTakesTextAtItsEnd() {
        assertEquals(TextEdit("hello!", 6), TextEdits.insert("hello", -1, -1, "!"))
    }

    @Test
    fun backspaceTakesAWholeEmoji() {
        val text = "ok 👍"

        assertEquals(TextEdit("ok ", 3), TextEdits.backspace(text, text.length, text.length))
    }

    @Test
    fun backspaceAndDeleteRemoveTheSelection() {
        assertEquals(TextEdit("held", 3), TextEdits.backspace("hello world", 3, 10))
        assertEquals(TextEdit("held", 3), TextEdits.delete("hello world", 10, 3))
    }

    @Test
    fun nothingToRemoveAtTheEdges() {
        assertNull(TextEdits.backspace("hello", 0, 0))
        assertNull(TextEdits.delete("hello", 5, 5))
    }

    @Test
    fun arrowsMoveByCharactersAndCollapseASelection() {
        assertEquals(2, TextEdits.cursorAfter("hello", 3, 3, -1))
        assertEquals(5, TextEdits.cursorAfter("hello", 5, 5, 1))
        assertEquals(1, TextEdits.cursorAfter("hello", 1, 4, -1))
        assertEquals(4, TextEdits.cursorAfter("hello", 1, 4, 1))
        assertEquals(2, TextEdits.cursorAfter("👍a", 0, 0, 1))
    }
}
