package io.sofluffy.ferret_mirroring

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AnnexBTest {
    private fun bytes(hex: String): ByteArray = hex.chunked(2).map { it.toInt(16).toByte() }.toByteArray()

    /** x264's set for 640×360 High: 368 rows of macroblocks, 8 cut off at the bottom. */
    private val sps = bytes("6764001eacb405017fcb8088000003000800000301e478b175")

    @Test
    fun findsUnitsBehindBothStartCodes() {
        val data = bytes("00000001" + "6742" + "000001" + "68ce" + "00000001" + "65888400")
        val units = AnnexB.units(data)

        assertEquals(listOf(4..5, 9..10, 15..18), units)
        assertEquals(listOf(7, 8, 5), units.map { AnnexB.kindOf(data, it) })
        assertTrue(AnnexB.hasIdr(data))
        assertFalse(AnnexB.hasIdr(bytes("00000001" + "419a00")))
    }

    @Test
    fun readsTheShownSizeAndTheCodedOne() {
        val size = SpsSize.parse(sps)

        assertEquals(SpsSize(640, 368, 0, 0, 640, 360), size)
    }

    @Test
    fun readsABaselineSetWithoutCropping() {
        val baseline = bytes("6742c01fd9005005bb0110000003001000000303c0f1832480")

        assertEquals(SpsSize(1280, 720, 0, 0, 1280, 720), SpsSize.parse(baseline))
    }

    @Test
    fun readsAPortraitPhoneScreen() {
        // A Pixel 7 held upright: 1080 is not whole macroblocks.
        val portrait = bytes("674d4032eca0220096f2f80880000003008000001e078c18cb")

        assertEquals(SpsSize(1088, 2400, 0, 0, 1080, 2400), SpsSize.parse(portrait))
    }

    @Test
    fun givesUpOnASetCutShort() {
        assertNull(SpsSize.parse(bytes("6764")))
    }
}
