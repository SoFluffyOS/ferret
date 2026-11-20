package io.sofluffy.ferret_drop

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class ShareTargetsTest {
    @Test
    fun linkFromChrome_sendsTheLinkNotThePreviewImage() {
        val files = SharedContent.files(
            streams = emptyList(),
            clipItems = listOf("content://chrome/preview.png"),
            text = "https://example.com/",
        )

        assertEquals(emptyList(), files)
    }

    @Test
    fun photo_sendsTheStream() {
        val files = SharedContent.files(
            streams = listOf("content://media/1"),
            clipItems = listOf("content://media/1"),
            text = "caption",
        )

        assertEquals(listOf("content://media/1"), files)
    }

    @Test
    fun clipDataOnly_sendsItsItems() {
        val files = SharedContent.files(
            streams = emptyList(),
            clipItems = listOf("content://a", "content://b", "content://a"),
            text = null,
        )

        assertEquals(listOf("content://a", "content://b"), files)
    }

    @Test
    fun shortcutId_namesTheDevice() {
        val id = ShareShortcuts.shortcutId("oucz-nlh4")

        assertEquals("oucz-nlh4", ShareShortcuts.deviceId(id))
        assertNull(ShareShortcuts.deviceId("other"))
        assertNull(ShareShortcuts.deviceId("device:"))
        assertNull(ShareShortcuts.deviceId(null))
    }

    @Test
    fun stale_dropsOnlyOurShortcutsForGoneDevices() {
        val stale = ShareShortcuts.stale(
            published = listOf("device:mac", "device:pc", "pinned:other"),
            targets = listOf("mac"),
        )

        assertEquals(listOf("device:pc"), stale)
    }
}
