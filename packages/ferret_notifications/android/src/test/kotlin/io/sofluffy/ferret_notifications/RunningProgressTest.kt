package io.sofluffy.ferret_notifications

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class RunningProgressTest {
    @Test
    fun aMovingBarIsRunning() {
        assertTrue(NotificationReader.isRunningProgress(max = 100, progress = 45, indeterminate = false))
        assertTrue(NotificationReader.isRunningProgress(max = 0, progress = 0, indeterminate = true))
    }

    @Test
    fun aFullBarOrNoBarIsNot() {
        assertFalse(NotificationReader.isRunningProgress(max = 100, progress = 100, indeterminate = false))
        assertFalse(NotificationReader.isRunningProgress(max = 0, progress = 0, indeterminate = false))
    }
}
