package io.sofluffy.ferret_power.shell

/**
 * Fills the arguments of the clipboard service's hidden methods. Their
 * signatures changed with almost every Android release (a user id in 10, an
 * attribution tag in 13, a device id in 14, vendor extras in between), but
 * the meaning of each type stayed the same, so the arguments are picked by
 * type instead of by version.
 */
object ShellArguments {
    /** The package the shell user owns, which the service checks the caller against. */
    const val SHELL_PACKAGE = "com.android.shell"

    fun fill(types: Array<Class<*>>, userId: Int, listener: Any?): Array<Any?> {
        var strings = 0
        var ints = 0
        return Array(types.size) { index ->
            val type = types[index]
            when {
                type == String::class.java -> if (strings++ == 0) SHELL_PACKAGE else null
                type == Int::class.javaPrimitiveType -> if (ints++ == 0) userId else DEFAULT_DEVICE_ID
                type == Boolean::class.javaPrimitiveType -> true
                listener != null && type.isInstance(listener) -> listener
                else -> null
            }
        }
    }

    private const val DEFAULT_DEVICE_ID = 0
}
