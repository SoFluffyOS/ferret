package io.sofluffy.ferret_power.shell

/** What the app tells the root helper when it starts it. */
data class ShellOptions(
    val userId: Int,
    val packageName: String,
    val listenerComponent: String,
) {
    fun toArguments(): List<String> = listOf(
        "$USER$userId",
        "$PACKAGE$packageName",
        "$LISTENER$listenerComponent",
    )

    companion object {
        private const val USER = "--user="
        private const val PACKAGE = "--package="
        private const val LISTENER = "--listener="

        fun parse(arguments: Array<String>): ShellOptions {
            var userId = 0
            var packageName = ""
            var listenerComponent = ""
            for (argument in arguments) {
                when {
                    argument.startsWith(USER) -> userId = argument.removePrefix(USER).toIntOrNull() ?: 0
                    argument.startsWith(PACKAGE) -> packageName = argument.removePrefix(PACKAGE)
                    argument.startsWith(LISTENER) -> listenerComponent = argument.removePrefix(LISTENER)
                }
            }
            return ShellOptions(userId, packageName, listenerComponent)
        }
    }
}
