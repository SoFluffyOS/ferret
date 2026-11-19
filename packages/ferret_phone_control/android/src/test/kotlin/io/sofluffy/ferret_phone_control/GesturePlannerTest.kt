package io.sofluffy.ferret_phone_control

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class GesturePlannerTest {
    private var now = 0L
    private val planner = GesturePlanner(streaming = true, clock = { now })

    private val a = GesturePoint(100f, 200f)
    private val b = GesturePoint(110f, 260f)
    private val c = GesturePoint(120f, 320f)
    private val d = GesturePoint(130f, 380f)

    @Test
    fun aTapIsAShortStrokeThenItsLift() {
        val first = assertNotNull(planner.down(a))
        assertEquals(GestureStroke(listOf(a), GesturePlanner.FIRST_MS, continued = false, continues = true), first)

        assertNull(planner.up(a))
        val lift = assertNotNull(planner.onStrokeDone(completed = true))
        assertEquals(listOf(a, a), lift.points)
        assertTrue(lift.continued)
        assertFalse(lift.continues)

        assertNull(planner.onStrokeDone(completed = true))
        assertFalse(planner.isBusy)
    }

    @Test
    fun aDragRunsThroughThePointsThatCameInMeanwhile() {
        planner.down(a)
        now = 10
        planner.move(b)
        now = 20
        planner.move(c)
        now = 40

        val link = assertNotNull(planner.onStrokeDone(completed = true))
        assertEquals(listOf(a, b, c), link.points)
        assertEquals(30L, link.durationMs)
        assertTrue(link.continues)

        planner.up(d)
        val lift = assertNotNull(planner.onStrokeDone(completed = true))
        assertEquals(listOf(c, d), lift.points)
        assertFalse(lift.continues)
    }

    @Test
    fun aFingerStandingStillIsHeldInPieces() {
        planner.down(a)

        val hold = assertNotNull(planner.onStrokeDone(completed = true))

        assertEquals(GestureStroke(listOf(a), GesturePlanner.HOLD_MS, continued = true, continues = true), hold)
        assertTrue(planner.isBusy)
    }

    @Test
    fun aTouchAndroidCutShortDropsTheRestOfIt() {
        planner.down(a)

        assertNull(planner.onStrokeDone(completed = false))
        assertNull(planner.move(b))
        assertNull(planner.up(b))
        assertFalse(planner.isBusy)
    }

    @Test
    fun aSecondTapWhileTheFirstLiftsWaitsItsTurn() {
        planner.down(a)
        planner.up(a)
        assertNull(planner.down(b))
        assertNull(planner.up(b))

        val firstLift = assertNotNull(planner.onStrokeDone(completed = true))
        assertEquals(listOf(a, a), firstLift.points)

        val second = assertNotNull(planner.onStrokeDone(completed = true))
        assertEquals(listOf(b), second.points)
        assertFalse(second.continued)

        val secondLift = assertNotNull(planner.onStrokeDone(completed = true))
        assertEquals(listOf(b, b), secondLift.points)
        assertFalse(secondLift.continues)
    }

    @Test
    fun beforeAndroid8TheWholeTouchIsReplayedOnLift() {
        val old = GesturePlanner(streaming = false, clock = { now })

        assertNull(old.down(a))
        now = 50
        assertNull(old.move(b))
        now = 400
        val replay = assertNotNull(old.up(c))

        assertEquals(GestureStroke(listOf(a, b, c), 400L, continued = false, continues = false), replay)
    }

    @Test
    fun scrollingIsASwipeAndScrollsMeanwhileAddUp() {
        val start = GesturePoint(500f, 1000f)

        val first = assertNotNull(planner.scroll(start, 0f, -300f, 1080f, 2400f))
        assertEquals(listOf(start, GesturePoint(500f, 700f)), first.points)
        assertEquals(GesturePlanner.SCROLL_MS, first.durationMs)

        assertNull(planner.scroll(start, 0f, -300f, 1080f, 2400f))
        assertNull(planner.scroll(start, 0f, -300f, 1080f, 2400f))
        val next = assertNotNull(planner.onStrokeDone(completed = true))
        assertEquals(listOf(start, GesturePoint(500f, 400f)), next.points)
    }

    @Test
    fun aSwipeStaysOnTheScreen() {
        val swipe = assertNotNull(planner.scroll(GesturePoint(500f, 100f), 0f, -1000f, 1080f, 2400f))

        assertEquals(GesturePoint(500f, 0f), swipe.points.last())
    }

    @Test
    fun oneFingerCantScrollWhileItTouches() {
        planner.down(a)

        assertNull(planner.scroll(a, 0f, 100f, 1080f, 2400f))
    }
}
