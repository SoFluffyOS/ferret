package io.sofluffy.ferret_handoff

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class DeepLinksTest {
    @Test
    fun webLinksAreWeb() {
        assertTrue(DeepLinks.isWeb("https://example.org/page"))
        assertTrue(DeepLinks.isWeb("HTTP://example.org"))
        assertFalse(DeepLinks.isWeb("spotify:track:1"))
    }

    @Test
    fun phoneOnlyUrisAreNotForwarded() {
        assertFalse(DeepLinks.isForwardable("content://media/external/images/1"))
        assertFalse(DeepLinks.isForwardable("file:///sdcard/a.txt"))
        assertFalse(DeepLinks.isForwardable("intent://scan/#Intent;end"))
        assertFalse(DeepLinks.isForwardable("no scheme here"))
        assertTrue(DeepLinks.isForwardable("spotify:track:1"))
        assertTrue(DeepLinks.isForwardable("https://example.org"))
    }

    @Test
    fun schemesAreParsedStrictly() {
        assertEquals("geo", DeepLinks.scheme("geo:48.85,2.35"))
        assertNull(DeepLinks.scheme(":nothing"))
        assertNull(DeepLinks.scheme("1abc:x"))
    }
}
