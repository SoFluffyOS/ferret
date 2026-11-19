package io.sofluffy.ferret_power.shell

/**
 * The lines the root helper and the app exchange over the helper's stdin and
 * stdout. One message per line; clip text is escaped so it stays on one line.
 */
object ShellLines {
    const val READY = "READY"
    const val OK = "OK"
    const val FAIL = "FAIL"
    const val EMPTY = "EMPTY"
    const val CLIP = "CLIP"
    const val CHANGE = "CHANGE"

    const val READ = "read"
    const val WATCH = "watch"
    const val UNWATCH = "unwatch"
    const val GRANT = "grant"
    const val RELEASE = "release"
    const val QUIT = "quit"

    fun clipLine(prefix: String, clip: ShellClip): String {
        val flag = if (clip.sensitive) "1" else "0"
        return "$prefix $flag ${escape(clip.text)}"
    }

    /** The clip in [line], or null when it isn't a [prefix] line. */
    fun parseClip(prefix: String, line: String): ShellClip? {
        val parts = line.split(' ', limit = 3)
        if (parts.size != 3 || parts[0] != prefix) {
            return null
        }

        val sensitive = when (parts[1]) {
            "1" -> true
            "0" -> false
            else -> return null
        }
        return ShellClip(unescape(parts[2]), sensitive)
    }

    fun escape(text: String): String {
        val escaped = StringBuilder(text.length + 16)
        for (char in text) {
            when (char) {
                '\\' -> escaped.append("\\\\")
                '\n' -> escaped.append("\\n")
                '\r' -> escaped.append("\\r")
                else -> escaped.append(char)
            }
        }
        return escaped.toString()
    }

    fun unescape(text: String): String {
        val plain = StringBuilder(text.length)
        var index = 0
        while (index < text.length) {
            val char = text[index]
            if (char != '\\' || index + 1 >= text.length) {
                plain.append(char)
                index++
                continue
            }

            when (text[index + 1]) {
                'n' -> plain.append('\n')
                'r' -> plain.append('\r')
                else -> plain.append(text[index + 1])
            }
            index += 2
        }
        return plain.toString()
    }
}
