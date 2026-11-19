package io.sofluffy.ferret_power

import io.sofluffy.ferret_power.shell.ShellInput
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class ShellInputTest {
    @Test
    fun everyInputSurvivesItsLine() {
        val inputs = listOf(
            ShellInput.Touch(ShellInput.ACTION_DOWN, 540.5f, 1200f),
            ShellInput.Scroll(10f, 20f, -1f, 2.5f),
            ShellInput.Key(keyCode = 4, down = true, metaState = 0),
            ShellInput.Key(keyCode = 29, down = false, metaState = 0x1000),
            ShellInput.Text("two words, a \\ and\na new line "),
        )

        for (input in inputs) {
            val line = ShellInput.line(input)

            assertEquals(false, line.contains('\n'))
            assertEquals(input, ShellInput.parse(line))
        }
    }

    @Test
    fun aSpaceAloneIsStillText() {
        assertEquals(ShellInput.Text(" "), ShellInput.parse("text  "))
    }

    @Test
    fun anythingElseIsNotInput() {
        assertNull(ShellInput.parse("input tap 1 2"))
        assertNull(ShellInput.parse("touch 0 1"))
        assertNull(ShellInput.parse("touch 0 1 2 3"))
        assertNull(ShellInput.parse("touch 9 1 2"))
        assertNull(ShellInput.parse("touch 0 NaN 2"))
        assertNull(ShellInput.parse("touch 0 -1 2"))
        assertNull(ShellInput.parse("scroll 1 2 3"))
        assertNull(ShellInput.parse("scroll 1 2 500 0"))
        assertNull(ShellInput.parse("key 0 1 0"))
        assertNull(ShellInput.parse("key 4 2 0"))
        assertNull(ShellInput.parse("key 4; reboot 1 0"))
        assertNull(ShellInput.parse("text "))
        assertNull(ShellInput.parse("text"))
    }

    @Test
    fun textHasALimit() {
        assertNull(ShellInput.checked(ShellInput.Text("a".repeat(ShellInput.MAX_TEXT_LENGTH + 1))))
        assertEquals(
            ShellInput.MAX_TEXT_LENGTH,
            (ShellInput.checked(ShellInput.Text("a".repeat(ShellInput.MAX_TEXT_LENGTH))) as ShellInput.Text).text.length,
        )
    }
}
