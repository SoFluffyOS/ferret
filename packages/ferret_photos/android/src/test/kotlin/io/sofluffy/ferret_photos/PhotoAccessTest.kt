package io.sofluffy.ferret_photos

import kotlin.test.Test
import kotlin.test.assertEquals

class PhotoAccessTest {
    @Test
    fun fullAccessOnAndroid13NeedsImages() {
        val granted = setOf("android.permission.READ_MEDIA_IMAGES")
        assertEquals(PhotoAccess.FULL, PhotoAccess.from(33, granted, asked = true))
    }

    @Test
    fun selectedPhotosOnAndroid14IsLimited() {
        val granted = setOf("android.permission.READ_MEDIA_VISUAL_USER_SELECTED")
        assertEquals(PhotoAccess.LIMITED, PhotoAccess.from(34, granted, asked = true))
    }

    @Test
    fun olderAndroidReadsStorage() {
        val granted = setOf("android.permission.READ_EXTERNAL_STORAGE")
        assertEquals(PhotoAccess.FULL, PhotoAccess.from(30, granted, asked = true))
        assertEquals(3, PhotoAccess.permissionsToAsk(34).size)
        assertEquals(1, PhotoAccess.permissionsToAsk(28).size)
    }

    @Test
    fun nothingGrantedIsDeniedOnlyAfterAsking() {
        assertEquals(PhotoAccess.NOT_ASKED, PhotoAccess.from(34, emptySet(), asked = false))
        assertEquals(PhotoAccess.DENIED, PhotoAccess.from(34, emptySet(), asked = true))
    }

    @Test
    fun cursorsRoundTrip() {
        val cursor = PageCursor(1700000000L, 42L)
        assertEquals(cursor, PageCursor.parse(cursor.encode()))
        assertEquals(null, PageCursor.parse("junk"))
        assertEquals(null, PageCursor.parse(null))
    }

    @Test
    fun screenshotsAreFoundByFolder() {
        assertEquals(true, MediaStoreReader.isScreenshotPath("Pictures/Screenshots/"))
        assertEquals(true, MediaStoreReader.isScreenshotPath("/storage/emulated/0/DCIM/Screenshots/a.png"))
        assertEquals(false, MediaStoreReader.isScreenshotPath("DCIM/Camera/"))
    }
}
