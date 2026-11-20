package io.sofluffy.ferret_mirroring

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class CameraPlanTest {
    private val sizes = listOf(
        CaptureSize(4032, 3024),
        CaptureSize(1920, 1080),
        CaptureSize(1440, 1080),
        CaptureSize(1280, 960),
        CaptureSize(1280, 720),
        CaptureSize(640, 480),
    )

    @Test
    fun picksTheBiggestWideSizeThatFits() {
        assertEquals(CaptureSize(1280, 720), CameraPlan.size(sizes, 1280, 720))
        assertEquals(CaptureSize(1920, 1080), CameraPlan.size(sizes, 1920, 1080))
    }

    @Test
    fun takesAnotherShapeWhenNothingWideFits() {
        assertEquals(CaptureSize(640, 480), CameraPlan.size(sizes, 800, 600))
        assertNull(CameraPlan.size(sizes, 320, 240))
    }

    @Test
    fun picksTheSteadiestFrameRate() {
        val ranges = listOf(15 to 15, 15 to 30, 30 to 30, 7 to 60)
        assertEquals(30 to 30, CameraPlan.fpsRange(ranges, 30))
        assertEquals(15 to 30, CameraPlan.fpsRange(listOf(15 to 30, 7 to 30), 30))
        assertEquals(24 to 24, CameraPlan.fpsRange(listOf(24 to 24, 15 to 15), 30))
        assertNull(CameraPlan.fpsRange(emptyList(), 30))
    }

    @Test
    fun turnsTheBackCameraWithThePhone() {
        assertEquals(90, CameraPlan.turn(sensorOrientation = 90, deviceDegrees = 0, front = false))
        assertEquals(180, CameraPlan.turn(sensorOrientation = 90, deviceDegrees = 90, front = false))
        assertEquals(0, CameraPlan.turn(sensorOrientation = 90, deviceDegrees = 270, front = false))
    }

    @Test
    fun turnsTheFrontCameraTheOtherWay() {
        assertEquals(270, CameraPlan.turn(sensorOrientation = 270, deviceDegrees = 0, front = true))
        assertEquals(180, CameraPlan.turn(sensorOrientation = 270, deviceDegrees = 90, front = true))
        assertEquals(0, CameraPlan.turn(sensorOrientation = 270, deviceDegrees = 270, front = true))
    }

    @Test
    fun holdsItsQuarterUntilThePhoneClearlyTips() {
        assertEquals(0, CameraPlan.snap(40, current = 0))
        assertEquals(0, CameraPlan.snap(320, current = 0))
        assertEquals(90, CameraPlan.snap(75, current = 0))
        assertEquals(270, CameraPlan.snap(280, current = 0))
        assertEquals(90, CameraPlan.snap(50, current = 90))
        assertEquals(0, CameraPlan.snap(10, current = 90))
        assertEquals(180, CameraPlan.snap(-1, current = 180))
    }
}
