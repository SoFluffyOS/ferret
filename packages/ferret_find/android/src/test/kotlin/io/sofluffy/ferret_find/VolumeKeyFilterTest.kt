package io.sofluffy.ferret_find

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class VolumeKeyFilterTest {
    @Test
    fun ignoresChangesRightAfterFerretsOwn() {
        val filter = VolumeKeyFilter(graceMs = 1000)

        filter.ownChange(nowMs = 5000)

        assertFalse(filter.isKeyPress(nowMs = 5500))
        assertTrue(filter.isKeyPress(nowMs = 6000))
    }

    @Test
    fun treatsAnyChangeAsAKeyPressWhenFerretChangedNothing() {
        val filter = VolumeKeyFilter()

        assertTrue(filter.isKeyPress(nowMs = 0))
    }
}
