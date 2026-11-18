package io.sofluffy.ferret_notifications

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class RestrictedSettingsTest {
    @Test
    fun beforeAndroid13NothingIsRestricted() {
        assertFalse(RestrictedSettings.isLikelyRestricted(32, false, 2, 4))
    }

    @Test
    fun grantedAccessIsNeverRestricted() {
        assertFalse(RestrictedSettings.isLikelyRestricted(34, true, 2, 4))
    }

    @Test
    fun allowedOpIsNotRestricted() {
        assertFalse(RestrictedSettings.isLikelyRestricted(34, false, 0, 4))
    }

    @Test
    fun installedFromAFileIsRestricted() {
        assertTrue(RestrictedSettings.isLikelyRestricted(34, false, null, 3))
        assertTrue(RestrictedSettings.isLikelyRestricted(34, false, null, 4))
    }

    @Test
    fun storeInstallsAreNotRestricted() {
        assertFalse(RestrictedSettings.isLikelyRestricted(34, false, 2, 2))
    }

    @Test
    fun unknownSourceFollowsTheAppOp() {
        assertTrue(RestrictedSettings.isLikelyRestricted(34, false, 2, null))
        assertTrue(RestrictedSettings.isLikelyRestricted(34, false, 1, 1))
        assertFalse(RestrictedSettings.isLikelyRestricted(34, false, null, null))
    }
}
