package io.sofluffy.ferret_clipboard

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class OwnClipTest {
    private val now = 1_800_000_000_000L

    @Test
    fun ferretsFreshWriteIsItsOwn() {
        assertTrue(OwnClip.isOwn("Ferret", now - 200, now))
    }

    @Test
    fun anotherAppsLabelIsNot() {
        assertFalse(OwnClip.isOwn("Chrome", now - 200, now))
        assertFalse(OwnClip.isOwn(null, now - 200, now))
    }

    @Test
    fun aFerretLabelWithoutTheWriteTimeIsNot() {
        assertFalse(OwnClip.isOwn("Ferret", 0L, now))
    }

    @Test
    fun anOldWriteIsReadAgain() {
        assertTrue(OwnClip.isOwn("Ferret", now - OwnClip.WINDOW_MS, now))
        assertFalse(OwnClip.isOwn("Ferret", now - OwnClip.WINDOW_MS - 1, now))
        assertFalse(OwnClip.isOwn("Ferret", now + OwnClip.WINDOW_MS + 1, now))
    }

    @Test
    fun markersMatchTheShellHelper() {
        assertEquals("Ferret", OwnClip.LABEL)
        assertEquals("io.sofluffy.ferret.extra.WRITTEN_AT", OwnClip.EXTRA_WRITTEN_AT)
    }
}
