package io.sofluffy.ferret_battery

import android.os.BatteryManager
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class OnPowerTest {
    @Test
    fun aPhoneOnItsCableThatHoldsItsChargeIsOnPower() {
        assertTrue(
            FerretBatteryPlugin.isOnPower(
                BatteryManager.BATTERY_STATUS_NOT_CHARGING,
                BatteryManager.BATTERY_PLUGGED_AC,
            ),
        )
    }

    @Test
    fun chargingCountsEvenBeforeThePlugIsReported() {
        assertTrue(FerretBatteryPlugin.isOnPower(BatteryManager.BATTERY_STATUS_CHARGING, 0))
        assertTrue(FerretBatteryPlugin.isOnPower(BatteryManager.BATTERY_STATUS_FULL, 0))
    }

    @Test
    fun anUnpluggedPhoneRunsDown() {
        assertFalse(FerretBatteryPlugin.isOnPower(BatteryManager.BATTERY_STATUS_DISCHARGING, 0))
        assertFalse(FerretBatteryPlugin.isOnPower(BatteryManager.BATTERY_STATUS_NOT_CHARGING, 0))
    }
}
