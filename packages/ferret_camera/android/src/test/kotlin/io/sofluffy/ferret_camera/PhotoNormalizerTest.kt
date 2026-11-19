package io.sofluffy.ferret_camera

import android.media.ExifInterface
import java.util.Calendar
import kotlin.test.Test
import kotlin.test.assertEquals

class PhotoNormalizerTest {
    @Test
    fun turnsByTheExifOrientation() {
        assertEquals(0f, PhotoNormalizer.degreesOf(ExifInterface.ORIENTATION_NORMAL))
        assertEquals(90f, PhotoNormalizer.degreesOf(ExifInterface.ORIENTATION_ROTATE_90))
        assertEquals(180f, PhotoNormalizer.degreesOf(ExifInterface.ORIENTATION_ROTATE_180))
        assertEquals(270f, PhotoNormalizer.degreesOf(ExifInterface.ORIENTATION_ROTATE_270))
        assertEquals(0f, PhotoNormalizer.degreesOf(ExifInterface.ORIENTATION_UNDEFINED))
    }

    @Test
    fun bringsTheLongSideDownToTheLimit() {
        assertEquals(1, PhotoNormalizer.sampleFor(4000))
        assertEquals(1, PhotoNormalizer.sampleFor(PhotoNormalizer.MAX_SIDE))
        assertEquals(2, PhotoNormalizer.sampleFor(8160))
        assertEquals(4, PhotoNormalizer.sampleFor(12000))
    }

    @Test
    fun namesThePhotoByWhenItWasTaken() {
        val taken = Calendar.getInstance().apply { set(2026, Calendar.NOVEMBER, 19, 14, 3, 7) }.time
        assertEquals("Photo 2026-11-19 at 14.03.07.jpg", PhotoNormalizer.fileName(taken))
    }
}
