package io.sofluffy.ferret_media

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class FerretMediaPluginTest {
    @Test
    fun contentUriKeepsSpotifyAndWebLinks() {
        assertEquals("spotify:track:abc", PlayerSnapshots.contentUriFrom("spotify:track:abc"))
        assertEquals("https://youtu.be/x", PlayerSnapshots.contentUriFrom("https://youtu.be/x"))
    }

    @Test
    fun contentUriDropsOpaqueMediaIds() {
        assertNull(PlayerSnapshots.contentUriFrom("12345"))
        assertNull(PlayerSnapshots.contentUriFrom(null))
    }

    @Test
    fun knownAppNamesFallBackToThePackage() {
        assertEquals("Spotify", AppNames.known("com.spotify.music"))
        assertNull(AppNames.known("org.example.player"))
    }
}
