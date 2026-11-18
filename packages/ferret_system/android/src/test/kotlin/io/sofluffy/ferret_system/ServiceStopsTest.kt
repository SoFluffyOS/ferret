package io.sofluffy.ferret_system

import android.app.ApplicationExitInfo
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class ServiceStopsTest {
    private val boot = 1_000_000L

    @Test
    fun aCleanStopIsNotAKill() {
        assertFalse(ServiceStops.wasKilled(wasRunning = false, previousBootAt = boot, bootAt = boot, exitReason = null))
    }

    @Test
    fun aRebootIsNotAKill() {
        assertFalse(ServiceStops.wasKilled(wasRunning = true, previousBootAt = boot, bootAt = boot + 3_600_000, exitReason = null))
    }

    @Test
    fun theUsersOwnStopIsNotAKill() {
        assertFalse(
            ServiceStops.wasKilled(
                wasRunning = true,
                previousBootAt = boot,
                bootAt = boot + 500,
                exitReason = ApplicationExitInfo.REASON_USER_REQUESTED,
            ),
        )
    }

    @Test
    fun aLowMemoryKillCounts() {
        assertTrue(
            ServiceStops.wasKilled(
                wasRunning = true,
                previousBootAt = boot,
                bootAt = boot + 500,
                exitReason = ApplicationExitInfo.REASON_LOW_MEMORY,
            ),
        )
    }

    @Test
    fun onlyTheLastWeekIsKept() {
        val now = 30L * 24 * 60 * 60 * 1000
        val day = 24L * 60 * 60 * 1000

        val kept = ServiceStops.keepRecent(listOf(now - 8 * day, now - 2 * day, now - 1000), now)

        assertEquals(listOf(now - 2 * day, now - 1000), kept)
    }
}
