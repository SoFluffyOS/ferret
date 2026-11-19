package io.sofluffy.ferret_power.shell

/**
 * One thing the helper can inject, always as typed values: a touch, a
 * scroll, a key or text. Positions are screen pixels in the current
 * rotation. Over the root helper's pipe each one is a line; [parse] takes
 * nothing that isn't exactly one of them.
 */
sealed interface ShellInput {
    data class Touch(val action: Int, val x: Float, val y: Float) : ShellInput

    data class Scroll(val x: Float, val y: Float, val horizontal: Float, val vertical: Float) : ShellInput

    data class Key(val keyCode: Int, val down: Boolean, val metaState: Int) : ShellInput

    data class Text(val text: String) : ShellInput

    companion object {
        const val TOUCH = "touch"
        const val SCROLL = "scroll"
        const val KEY = "key"
        const val TEXT = "text"

        const val ACTION_DOWN = 0
        const val ACTION_UP = 1
        const val ACTION_MOVE = 2
        const val ACTION_CANCEL = 3

        const val MAX_TEXT_LENGTH = 4096
        private const val MAX_KEY_CODE = 1023
        private const val MAX_POSITION = 100_000f
        private const val MAX_SCROLL = 100f

        fun line(input: ShellInput): String = when (input) {
            is Touch -> "$TOUCH ${input.action} ${input.x} ${input.y}"
            is Scroll -> "$SCROLL ${input.x} ${input.y} ${input.horizontal} ${input.vertical}"
            is Key -> "$KEY ${input.keyCode} ${if (input.down) 1 else 0} ${input.metaState}"
            is Text -> "$TEXT ${ShellLines.escape(input.text)}"
        }

        /** The input in [line], or null when it isn't one or a value is out of range. */
        fun parse(line: String): ShellInput? {
            val name = line.substringBefore(' ')
            val rest = line.substringAfter(' ', "")
            return when (name) {
                TOUCH -> touchOf(rest.split(' '))
                SCROLL -> scrollOf(rest.split(' '))
                KEY -> keyOf(rest.split(' '))
                TEXT -> checked(Text(ShellLines.unescape(rest)))
                else -> null
            }
        }

        /** [input] when every value is one the helper may inject, or null. */
        fun checked(input: ShellInput): ShellInput? {
            val valid = when (input) {
                is Touch -> input.action in ACTION_DOWN..ACTION_CANCEL && isPosition(input.x) && isPosition(input.y)
                is Scroll -> isPosition(input.x) && isPosition(input.y) &&
                    isScroll(input.horizontal) && isScroll(input.vertical)
                is Key -> input.keyCode in 1..MAX_KEY_CODE && input.metaState >= 0
                is Text -> input.text.isNotEmpty() && input.text.length <= MAX_TEXT_LENGTH
            }
            return if (valid) input else null
        }

        private fun touchOf(parts: List<String>): ShellInput? {
            if (parts.size != 3) {
                return null
            }

            val action = parts[0].toIntOrNull() ?: return null
            val x = parts[1].toFloatOrNull() ?: return null
            val y = parts[2].toFloatOrNull() ?: return null
            return checked(Touch(action, x, y))
        }

        private fun scrollOf(parts: List<String>): ShellInput? {
            if (parts.size != 4) {
                return null
            }

            val values = parts.map { it.toFloatOrNull() ?: return null }
            return checked(Scroll(values[0], values[1], values[2], values[3]))
        }

        private fun keyOf(parts: List<String>): ShellInput? {
            if (parts.size != 3) {
                return null
            }

            val keyCode = parts[0].toIntOrNull() ?: return null
            val down = when (parts[1]) {
                "1" -> true
                "0" -> false
                else -> return null
            }
            val metaState = parts[2].toIntOrNull() ?: return null
            return checked(Key(keyCode, down, metaState))
        }

        private fun isPosition(value: Float): Boolean = value.isFinite() && value >= 0f && value <= MAX_POSITION

        private fun isScroll(value: Float): Boolean = value.isFinite() && value >= -MAX_SCROLL && value <= MAX_SCROLL
    }
}
