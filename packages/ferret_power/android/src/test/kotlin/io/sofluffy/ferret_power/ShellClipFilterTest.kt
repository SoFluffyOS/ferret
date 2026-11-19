package io.sofluffy.ferret_power

import io.sofluffy.ferret_power.shell.ShellClipFilter
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class ShellClipFilterTest {
    private val now = 1_800_000_000_000L
    private val text = listOf("text/plain")

    @Test
    fun aCopyInAnotherAppIsRead() {
        assertTrue(ShellClipFilter.shouldRead("Chrome", 0L, text, now))
        assertTrue(ShellClipFilter.shouldRead(null, 0L, listOf("text/html"), now))
    }

    @Test
    fun ferretsOwnFreshWriteIsNotRead() {
        assertFalse(ShellClipFilter.shouldRead("Ferret", now - 500, text, now))
    }

    @Test
    fun aFerretLabelFromAnotherAppIsStillRead() {
        assertTrue(ShellClipFilter.shouldRead("Ferret", 0L, text, now))
    }

    @Test
    fun ferretsWriteOutsideTheWindowIsRead() {
        assertTrue(ShellClipFilter.shouldRead("Ferret", now - ShellClipFilter.WINDOW_MS - 1, text, now))
        assertTrue(ShellClipFilter.shouldRead("Ferret", now + ShellClipFilter.WINDOW_MS + 1, text, now))
    }

    @Test
    fun clipsWithoutTextAreNotRead() {
        assertFalse(ShellClipFilter.shouldRead("Photos", 0L, listOf("image/png"), now))
        assertFalse(ShellClipFilter.shouldRead("Files", 0L, listOf("text/uri-list"), now))
    }

    @Test
    fun aDescriptionWithoutTypesIsRead() {
        assertTrue(ShellClipFilter.shouldRead("Odd", 0L, emptyList(), now))
    }

    @Test
    fun markersMatchFerretClipboard() {
        assertEquals("Ferret", ShellClipFilter.OWN_LABEL)
        assertEquals("io.sofluffy.ferret.extra.WRITTEN_AT", ShellClipFilter.EXTRA_WRITTEN_AT)
    }
}
