package io.sofluffy.ferret_system

import java.security.MessageDigest

/**
 * What a Tasker action of Ferret asks for, as kept in the bundle Tasker
 * stores. Only bundles made by [TaskerEditActivity] carry this install's
 * secret, so another app firing the plugin intent can't make Ferret act.
 */
object TaskerRequest {
    const val ACTION_ID = "script.run"

    const val KEY_SECRET = "io.sofluffy.ferret.extra.SECRET"
    const val KEY_COMMAND = "io.sofluffy.ferret.extra.COMMAND"
    const val KEY_DEVICE = "io.sofluffy.ferret.extra.DEVICE"
    const val KEY_VALUE = "io.sofluffy.ferret.extra.VALUE"
    const val KEY_BODY = "io.sofluffy.ferret.extra.BODY"

    /** Keys whose %variables Tasker fills in before it fires. */
    val VARIABLE_KEYS = listOf(KEY_DEVICE, KEY_VALUE, KEY_BODY)

    /** The commands Tasker can run, as `ferret-cli` names them. */
    val COMMANDS = listOf("clipboard_send", "ring", "open", "action_run", "notify")

    private const val MAX_LENGTH = 64 * 1024

    /** The action for Dart, or null when [values] wasn't made here. */
    fun toAction(values: Map<String, String?>, secret: String): SystemActionMessage? {
        val given = values[KEY_SECRET] ?: return null
        if (secret.isEmpty() || !sameSecret(given, secret)) {
            return null
        }

        val command = values[KEY_COMMAND]?.takeIf { it in COMMANDS } ?: return null
        val device = values[KEY_DEVICE].orEmpty().trim().take(MAX_LENGTH)
        val value = values[KEY_VALUE].orEmpty().take(MAX_LENGTH)
        val body = values[KEY_BODY].orEmpty().take(MAX_LENGTH)
        if (command != "clipboard_send" && device.isEmpty()) {
            return null
        }

        return SystemActionMessage(
            id = ACTION_ID,
            data = mapOf(
                "command" to command,
                "device" to device,
                "value" to value,
                "body" to body,
            ),
        )
    }

    private fun sameSecret(given: String, secret: String): Boolean =
        MessageDigest.isEqual(given.toByteArray(), secret.toByteArray())
}
