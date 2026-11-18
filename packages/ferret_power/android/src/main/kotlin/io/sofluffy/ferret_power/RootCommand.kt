package io.sofluffy.ferret_power

import io.sofluffy.ferret_power.shell.ShellOptions

/**
 * Builds the one command line Ferret hands to `su`: start the helper class
 * from Ferret's own APK with `app_process`. Every value is single-quoted, so
 * a path or name can never be read as shell syntax.
 */
object RootCommand {
    const val HELPER_CLASS = "io.sofluffy.ferret_power.shell.ShellMain"

    /** The uid of Android's shell user, which may read the clipboard in the background. */
    const val SHELL_UID = "2000"

    fun quote(value: String): String = "'" + value.replace("'", "'\\''") + "'"

    fun helper(apkPath: String, options: ShellOptions): String {
        val arguments = options.toArguments().joinToString(" ") { quote(it) }
        return "CLASSPATH=${quote(apkPath)} exec app_process /system/bin $HELPER_CLASS $arguments 2>/dev/null"
    }

    /**
     * The ways to start [command], best first: as the shell user, whose
     * clipboard access is the documented one, then as root for a `su` that
     * can't switch user.
     */
    fun launchers(command: String): List<List<String>> = listOf(
        listOf("su", SHELL_UID, "-c", command),
        listOf("su", "-c", command),
    )
}
