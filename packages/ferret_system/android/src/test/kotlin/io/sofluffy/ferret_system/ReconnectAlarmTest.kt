package io.sofluffy.ferret_system

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class ReconnectAlarmTest {
    @Test
    fun looksAgainWhileNobodyIsConnected() {
        assertTrue(ReconnectAlarm.isNeeded(serviceRunning = true, paused = false, connectedDevices = 0))
    }

    @Test
    fun restsWhileADeviceIsConnected() {
        assertFalse(ReconnectAlarm.isNeeded(serviceRunning = true, paused = false, connectedDevices = 1))
    }

    @Test
    fun restsWhilePausedOrStopped() {
        assertFalse(ReconnectAlarm.isNeeded(serviceRunning = true, paused = true, connectedDevices = 0))
        assertFalse(ReconnectAlarm.isNeeded(serviceRunning = false, paused = false, connectedDevices = 0))
    }
}
