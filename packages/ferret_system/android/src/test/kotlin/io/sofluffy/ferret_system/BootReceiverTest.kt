package io.sofluffy.ferret_system

import android.content.Intent
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class BootReceiverTest {
    @Test
    fun anUpdateBringsARunningFerretBack() {
        assertTrue(BootReceiver.shouldStart(Intent.ACTION_MY_PACKAGE_REPLACED, serviceEnabled = true, startOnBoot = false))
    }

    @Test
    fun aRebootStartsItOnlyWhenAsked() {
        assertTrue(BootReceiver.shouldStart(Intent.ACTION_BOOT_COMPLETED, serviceEnabled = true, startOnBoot = true))
        assertFalse(BootReceiver.shouldStart(Intent.ACTION_BOOT_COMPLETED, serviceEnabled = true, startOnBoot = false))
    }

    @Test
    fun aFastBootCountsAsAReboot() {
        assertTrue(BootReceiver.shouldStart("android.intent.action.QUICKBOOT_POWERON", serviceEnabled = true, startOnBoot = true))
    }

    @Test
    fun nothingStartsWhenTheUserTurnedTheServiceOff() {
        assertFalse(BootReceiver.shouldStart(Intent.ACTION_MY_PACKAGE_REPLACED, serviceEnabled = false, startOnBoot = true))
        assertFalse(BootReceiver.shouldStart(Intent.ACTION_BOOT_COMPLETED, serviceEnabled = false, startOnBoot = true))
    }

    @Test
    fun otherBroadcastsAreIgnored() {
        assertFalse(BootReceiver.shouldStart(Intent.ACTION_SCREEN_ON, serviceEnabled = true, startOnBoot = true))
        assertFalse(BootReceiver.shouldStart(null, serviceEnabled = true, startOnBoot = true))
    }
}
