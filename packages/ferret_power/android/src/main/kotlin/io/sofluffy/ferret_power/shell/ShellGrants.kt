package io.sofluffy.ferret_power.shell

/**
 * The only commands the helper ever runs, each one a setting Ferret turns on
 * for itself. They are built here from validated names and run without a
 * shell, so nothing the app sends can become another command.
 */
object ShellGrants {
    const val NOTIFICATION_ACCESS = "notificationAccess"
    const val BATTERY_UNRESTRICTED = "batteryUnrestricted"

    private val PACKAGE_NAME = Regex("^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+$")
    private val CLASS_NAME = Regex("^[A-Za-z_][A-Za-z0-9_$]*(\\.[A-Za-z_][A-Za-z0-9_$]*)*$")

    /** The command for [grant], or null when a name isn't what it should be. */
    fun commandFor(grant: String, packageName: String, listenerComponent: String): List<String>? {
        if (!PACKAGE_NAME.matches(packageName)) {
            return null
        }

        return when (grant) {
            NOTIFICATION_ACCESS -> {
                val className = listenerComponent.removePrefix("$packageName/")
                if (className == listenerComponent || !CLASS_NAME.matches(className)) {
                    return null
                }
                listOf("cmd", "notification", "allow_listener", listenerComponent)
            }
            BATTERY_UNRESTRICTED -> listOf("cmd", "deviceidle", "whitelist", "+$packageName")
            else -> null
        }
    }

    fun run(grant: String, packageName: String, listenerComponent: String): Boolean {
        val command = commandFor(grant, packageName, listenerComponent) ?: return false
        return runCatching {
            val process = ProcessBuilder(command).redirectErrorStream(true).start()
            process.outputStream.close()
            process.inputStream.use { output ->
                val discarded = ByteArray(1024)
                while (output.read(discarded) >= 0) {
                    // Drained so the command can't block on a full pipe.
                }
            }
            process.waitFor() == 0
        }.getOrDefault(false)
    }
}
