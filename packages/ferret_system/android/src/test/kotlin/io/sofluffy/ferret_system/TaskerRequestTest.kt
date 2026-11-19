package io.sofluffy.ferret_system

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class TaskerRequestTest {
    private val secret = "install-secret"

    private fun values(vararg extra: Pair<String, String?>) = mapOf(
        TaskerRequest.KEY_SECRET to secret,
        TaskerRequest.KEY_COMMAND to "ring",
        TaskerRequest.KEY_DEVICE to "MacBook",
        *extra,
    )

    @Test
    fun aBundleMadeHereBecomesAnAction() {
        val action = TaskerRequest.toAction(values(), secret)

        assertEquals("script.run", action?.id)
        assertEquals("ring", action?.data?.get("command"))
        assertEquals("MacBook", action?.data?.get("device"))
    }

    @Test
    fun aBundleWithoutTheSecretIsIgnored() {
        assertNull(TaskerRequest.toAction(values(TaskerRequest.KEY_SECRET to null), secret))
        assertNull(TaskerRequest.toAction(values(TaskerRequest.KEY_SECRET to "guess"), secret))
    }

    @Test
    fun anUnknownCommandIsIgnored() {
        assertNull(TaskerRequest.toAction(values(TaskerRequest.KEY_COMMAND to "shell"), secret))
    }

    @Test
    fun ringingNeedsADevice() {
        assertNull(TaskerRequest.toAction(values(TaskerRequest.KEY_DEVICE to " "), secret))
    }

    @Test
    fun sendingTextMayGoToEveryDevice() {
        val action = TaskerRequest.toAction(
            values(
                TaskerRequest.KEY_COMMAND to "clipboard_send",
                TaskerRequest.KEY_DEVICE to "",
                TaskerRequest.KEY_VALUE to "hello",
            ),
            secret,
        )

        assertEquals("hello", action?.data?.get("value"))
    }
}
