package io.sofluffy.ferret_phone_control

import kotlin.math.max

/** A place on the screen, in pixels. */
data class GesturePoint(val x: Float, val y: Float)

/**
 * One piece of a touch for `dispatchGesture`: the finger runs through
 * [points] in [durationMs]. [continued] says it picks up where the last
 * piece ended; [continues] that the finger stays down after it.
 */
data class GestureStroke(
    val points: List<GesturePoint>,
    val durationMs: Long,
    val continued: Boolean,
    val continues: Boolean,
)

/**
 * Turns a finger that goes down, moves and lifts somewhere else (on a
 * computer) into the strokes an accessibility service can dispatch.
 *
 * Android takes a touch from a service only as finished strokes, one at a
 * time. So while the far finger is down, this keeps a short stroke in
 * flight and chains the next one to it: through the points that came in
 * meanwhile, or standing still, which is what makes a long press. The lift
 * is the last link. With [streaming] off (before Android 8, which can't
 * chain strokes) the whole touch is replayed once the finger lifts.
 *
 * Give it each stroke's end through [onStrokeDone], and dispatch whatever a
 * call returns. It never touches Android itself.
 */
class GesturePlanner(
    private val streaming: Boolean = true,
    private val clock: () -> Long = System::currentTimeMillis,
) {
    private var touching = false
    private var inFlight = false
    private var lifting = false
    private var last = GesturePoint(0f, 0f)
    private val waiting = mutableListOf<GesturePoint>()
    private var waitingSince = 0L
    private var downAt = 0L

    /** A touch that began while the one before it was still finishing. */
    private var queuedDown: GesturePoint? = null
    private val queuedPoints = mutableListOf<GesturePoint>()
    private var queuedLift = false

    private var scrollAt: GesturePoint? = null
    private var scrollDx = 0f
    private var scrollDy = 0f
    private var scrollWidth = 0f
    private var scrollHeight = 0f

    /** A finger is down, or its last stroke is still being carried out. */
    val isBusy: Boolean
        get() = touching || inFlight

    fun down(point: GesturePoint): GestureStroke? {
        // A touch that is lifting still has a stroke in flight: the new one waits for it.
        if ((touching && !lifting) || queuedDown != null) {
            return null
        }
        if (inFlight) {
            queuedDown = point
            queuedPoints.clear()
            queuedLift = false
            return null
        }
        return flying(begin(point))
    }

    fun move(point: GesturePoint): GestureStroke? {
        if (queuedDown != null) {
            if (!queuedLift) {
                keep(queuedPoints, point)
            }
            return null
        }
        if (!touching || lifting) {
            return null
        }

        remember(point)
        return null
    }

    fun up(point: GesturePoint): GestureStroke? {
        if (queuedDown != null) {
            if (!queuedLift) {
                keep(queuedPoints, point)
                queuedLift = true
            }
            return null
        }
        if (!touching || lifting) {
            return null
        }

        remember(point)
        if (!streaming) {
            return flying(replay())
        }

        lifting = true
        return null
    }

    /**
     * The touch is abandoned. A service can't take a finger back, only lift
     * it, so this lifts where the finger last was.
     */
    fun cancel(): GestureStroke? = up(queuedPoints.lastOrNull() ?: queuedDown ?: waiting.lastOrNull() ?: last)

    /**
     * A swipe that scrolls what is under [point]: the finger travels
     * ([dx], [dy]) pixels, kept inside a [width] by [height] screen. Scrolls
     * that come in while a swipe is under way add up into the next one.
     * While a touch is under way they are left out: one finger can't do
     * both.
     */
    fun scroll(point: GesturePoint, dx: Float, dy: Float, width: Float, height: Float): GestureStroke? {
        if (touching || queuedDown != null || (dx == 0f && dy == 0f)) {
            return null
        }

        scrollAt = point
        scrollDx = (scrollDx + dx).coerceIn(-width * MAX_SCROLL_PART, width * MAX_SCROLL_PART)
        scrollDy = (scrollDy + dy).coerceIn(-height * MAX_SCROLL_PART, height * MAX_SCROLL_PART)
        scrollWidth = width
        scrollHeight = height
        if (inFlight) {
            return null
        }
        return flying(swipe())
    }

    /**
     * The stroke last handed out ended. [completed] is false when Android
     * cut it short, such as when the owner touched the screen: the touch is
     * over then, and what the far finger does until it lifts is dropped.
     */
    fun onStrokeDone(completed: Boolean): GestureStroke? {
        inFlight = false
        if (!completed) {
            reset()
            return null
        }
        if (touching && lifting) {
            return flying(link(continues = false).also { finish() })
        }
        if (touching) {
            return flying(link(continues = true))
        }
        return flying(afterTouch())
    }

    /** Forgets everything, such as when control ends with a finger down. */
    fun reset() {
        touching = false
        inFlight = false
        lifting = false
        waiting.clear()
        queuedDown = null
        queuedPoints.clear()
        queuedLift = false
        scrollAt = null
        scrollDx = 0f
        scrollDy = 0f
    }

    private fun flying(stroke: GestureStroke?): GestureStroke? {
        if (stroke != null) {
            inFlight = true
        }
        return stroke
    }

    private fun begin(point: GesturePoint): GestureStroke? {
        touching = true
        lifting = false
        last = point
        waiting.clear()
        downAt = clock()
        if (!streaming) {
            waiting.add(point)
            return null
        }

        return GestureStroke(listOf(point), FIRST_MS, continued = false, continues = true)
    }

    private fun remember(point: GesturePoint) {
        if (waiting.isEmpty()) {
            waitingSince = clock()
        }
        keep(waiting, point)
    }

    /** Adds [point], thinning the middle of a list that grew too long. */
    private fun keep(points: MutableList<GesturePoint>, point: GesturePoint) {
        if (points.size >= MAX_WAITING) {
            points.removeAt(points.size / 2)
        }
        points.add(point)
    }

    /** The next piece of the touch: through what came in, or standing still. */
    private fun link(continues: Boolean): GestureStroke {
        if (waiting.isEmpty()) {
            return GestureStroke(listOf(last), HOLD_MS, continued = true, continues = continues)
        }

        val points = listOf(last) + waiting
        val elapsed = clock() - waitingSince
        last = waiting.last()
        waiting.clear()
        return GestureStroke(points, elapsed.coerceIn(MIN_LINK_MS, MAX_LINK_MS), continued = true, continues = continues)
    }

    private fun replay(): GestureStroke {
        val points = waiting.toList()
        val duration = (clock() - downAt).coerceIn(FIRST_MS, MAX_REPLAY_MS)
        finish()
        return GestureStroke(points, duration, continued = false, continues = false)
    }

    private fun finish() {
        touching = false
        lifting = false
        waiting.clear()
    }

    /** What waited for the last touch to end: a new touch first, then a scroll. */
    private fun afterTouch(): GestureStroke? {
        val down = queuedDown ?: return swipe()
        queuedDown = null
        scrollAt = null
        val first = begin(down)
        queuedPoints.forEach(::remember)
        queuedPoints.clear()
        if (!queuedLift) {
            return first
        }

        queuedLift = false
        if (!streaming) {
            return replay()
        }
        lifting = true
        return first
    }

    private fun swipe(): GestureStroke? {
        val start = scrollAt ?: return null
        val end = GesturePoint(
            (start.x + scrollDx).coerceIn(0f, max(0f, scrollWidth - 1)),
            (start.y + scrollDy).coerceIn(0f, max(0f, scrollHeight - 1)),
        )
        scrollAt = null
        scrollDx = 0f
        scrollDy = 0f
        return GestureStroke(listOf(start, end), SCROLL_MS, continued = false, continues = false)
    }

    companion object {
        /** How long the finger rests before the first link: long enough to count as a touch. */
        const val FIRST_MS = 30L

        /** A finger standing still is kept down in pieces this long. */
        const val HOLD_MS = 50L
        const val MIN_LINK_MS = 16L
        const val MAX_LINK_MS = 120L
        const val SCROLL_MS = 120L
        const val MAX_REPLAY_MS = 5_000L
        const val MAX_WAITING = 64

        /** One swipe never travels more than this part of the screen. */
        const val MAX_SCROLL_PART = 0.6f
    }
}
