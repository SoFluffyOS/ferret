package io.sofluffy.ferret_phone_control

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.graphics.Path
import android.hardware.display.DisplayManager
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.Display
import android.view.KeyEvent
import android.view.View
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * The standard way a computer controls this phone: an accessibility service
 * its owner turns on in the system settings. It does nothing unless
 * [armed], which the app sets only while the screen is shown to a computer
 * that was allowed control. What is typed passes through and is never
 * logged. Call everything from the main thread.
 */
class FerretControlService : AccessibilityService() {
    private val planner = GesturePlanner(streaming = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
    private val main = Handler(Looper.getMainLooper())
    private var lastStroke: GestureDescription.StrokeDescription? = null

    /** A password field can't be read back, so what was typed into it is remembered while it has the cursor. */
    private var passwordField: AccessibilityNodeInfo? = null
    private var passwordTyped = ""

    private val strokeResult = object : GestureResultCallback() {
        override fun onCompleted(gesture: GestureDescription?) = onStrokeDone(completed = true)

        override fun onCancelled(gesture: GestureDescription?) = onStrokeDone(completed = false)
    }

    override fun onServiceConnected() {
        instance = this
        listen(armed)
        onEnabledChanged?.invoke(true)
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        disconnected()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        disconnected()
        super.onDestroy()
    }

    /** Events only keep the system's view of the focused field fresh. Nothing is read from them. */
    override fun onAccessibilityEvent(event: AccessibilityEvent?) = Unit

    override fun onInterrupt() = Unit

    /** Control began or ended: the service hears about the screen only in between. */
    fun onArmedChanged(armed: Boolean) {
        listen(armed)
        if (armed) {
            return
        }

        planner.reset()
        lastStroke = null
        forgetPassword()
    }

    fun touch(action: ServiceTouch, x: Double, y: Double): Boolean {
        if (!armed) {
            return false
        }

        val point = pointOf(x, y)
        val stroke = when (action) {
            ServiceTouch.DOWN -> planner.down(point)
            ServiceTouch.MOVE -> planner.move(point)
            ServiceTouch.UP -> planner.up(point)
            ServiceTouch.CANCEL -> planner.cancel()
        }
        stroke?.let(::dispatch)
        return true
    }

    /** Wheel notches: positive [horizontal] is right, positive [vertical] is down. */
    fun scroll(x: Double, y: Double, horizontal: Double, vertical: Double): Boolean {
        if (!armed) {
            return false
        }

        val metrics = screen()
        val step = metrics.heightPixels * SCROLL_STEP
        val swipe = planner.scroll(
            pointOf(x, y),
            (-horizontal * step).toFloat(),
            (-vertical * step).toFloat(),
            metrics.widthPixels.toFloat(),
            metrics.heightPixels.toFloat(),
        )
        swipe?.let(::dispatch)
        return true
    }

    fun typeText(text: String): Boolean {
        if (!armed || text.isEmpty()) {
            return false
        }

        val field = focusedField() ?: return false
        return write(field, TextEdits.insert(contentOf(field), field.textSelectionStart, field.textSelectionEnd, text))
    }

    fun pressKey(key: ServiceKey): Boolean {
        if (!armed) {
            return false
        }

        return when (key) {
            ServiceKey.ESCAPE -> performGlobalAction(GLOBAL_ACTION_BACK)
            ServiceKey.PLAY_PAUSE -> mediaKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            ServiceKey.NEXT -> mediaKey(KeyEvent.KEYCODE_MEDIA_NEXT)
            ServiceKey.PREVIOUS -> mediaKey(KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            ServiceKey.VOLUME_UP -> volume(AudioManager.ADJUST_RAISE)
            ServiceKey.VOLUME_DOWN -> volume(AudioManager.ADJUST_LOWER)
            ServiceKey.VOLUME_MUTE -> volume(AudioManager.ADJUST_TOGGLE_MUTE)
            else -> editKey(key)
        }
    }

    fun pressButton(button: ServiceButton): Boolean {
        if (!armed) {
            return false
        }

        return when (button) {
            ServiceButton.BACK -> performGlobalAction(GLOBAL_ACTION_BACK)
            ServiceButton.HOME -> performGlobalAction(GLOBAL_ACTION_HOME)
            ServiceButton.RECENTS -> performGlobalAction(GLOBAL_ACTION_RECENTS)
            ServiceButton.NOTIFICATIONS -> performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)
            ServiceButton.LOCK_SCREEN -> lockScreen()
            ServiceButton.VOLUME_UP -> volume(AudioManager.ADJUST_RAISE)
            ServiceButton.VOLUME_DOWN -> volume(AudioManager.ADJUST_LOWER)
        }
    }

    private fun editKey(key: ServiceKey): Boolean {
        val field = focusedField() ?: return false
        val start = field.textSelectionStart
        val end = field.textSelectionEnd
        return when (key) {
            ServiceKey.ENTER -> enter(field)
            ServiceKey.BACKSPACE -> TextEdits.backspace(contentOf(field), start, end)?.let { write(field, it) } == true
            ServiceKey.DELETE -> TextEdits.delete(contentOf(field), start, end)?.let { write(field, it) } == true
            ServiceKey.TAB -> field.focusSearch(View.FOCUS_FORWARD)?.performAction(AccessibilityNodeInfo.ACTION_FOCUS) == true
            ServiceKey.ARROW_LEFT -> select(field, TextEdits.cursorAfter(contentOf(field), start, end, -1))
            ServiceKey.ARROW_RIGHT -> select(field, TextEdits.cursorAfter(contentOf(field), start, end, 1))
            ServiceKey.HOME -> select(field, 0)
            ServiceKey.END -> select(field, contentOf(field).length)
            ServiceKey.SELECT_ALL -> select(field, 0, contentOf(field).length)
            ServiceKey.COPY -> field.performAction(AccessibilityNodeInfo.ACTION_COPY)
            ServiceKey.CUT -> field.performAction(AccessibilityNodeInfo.ACTION_CUT).also { forgetPassword() }
            ServiceKey.PASTE -> field.performAction(AccessibilityNodeInfo.ACTION_PASTE).also { forgetPassword() }
            else -> false
        }
    }

    /** What the keyboard's own Enter does: search, send, next. A line break where Android can't press it. */
    private fun enter(field: AccessibilityNodeInfo): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return field.performAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_IME_ENTER.id)
        }
        if (!field.isMultiLine) {
            return false
        }
        return write(field, TextEdits.insert(contentOf(field), field.textSelectionStart, field.textSelectionEnd, "\n"))
    }

    private fun focusedField(): AccessibilityNodeInfo? {
        val focused = runCatching { findFocus(AccessibilityNodeInfo.FOCUS_INPUT) }.getOrNull() ?: return null
        runCatching { focused.refresh() }
        return focused.takeIf { it.isEditable }
    }

    private fun contentOf(field: AccessibilityNodeInfo): String {
        val shown = field.text?.toString().orEmpty()
        if (field.isPassword) {
            val known = field == passwordField && shown.length == passwordTyped.length
            return if (known) passwordTyped else ""
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && field.isShowingHintText) {
            return ""
        }
        return shown
    }

    private fun write(field: AccessibilityNodeInfo, edit: TextEdit): Boolean {
        val content = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, edit.text)
        }
        if (!field.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, content)) {
            return false
        }

        select(field, edit.cursor)
        if (field.isPassword) {
            passwordField = field
            passwordTyped = edit.text
        }
        return true
    }

    private fun select(field: AccessibilityNodeInfo, start: Int, end: Int = start): Boolean {
        val selection = Bundle().apply {
            putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_START_INT, start)
            putInt(AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_END_INT, end)
        }
        return field.performAction(AccessibilityNodeInfo.ACTION_SET_SELECTION, selection)
    }

    private fun forgetPassword() {
        passwordField = null
        passwordTyped = ""
    }

    private fun lockScreen(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return false
        }
        return performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
    }

    private fun volume(direction: Int): Boolean {
        val audio = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        return runCatching {
            audio.adjustSuggestedStreamVolume(direction, AudioManager.USE_DEFAULT_STREAM_TYPE, AudioManager.FLAG_SHOW_UI)
        }.isSuccess
    }

    private fun mediaKey(keyCode: Int): Boolean {
        val audio = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
        return true
    }

    private fun dispatch(stroke: GestureStroke) {
        val accepted = runCatching {
            val description = describe(stroke)
            lastStroke = description.takeIf { stroke.continues }
            dispatchGesture(GestureDescription.Builder().addStroke(description).build(), strokeResult, main)
        }.getOrDefault(false)
        if (!accepted) {
            onStrokeDone(completed = false)
        }
    }

    private fun describe(stroke: GestureStroke): GestureDescription.StrokeDescription {
        val first = stroke.points.first()
        val path = Path().apply {
            moveTo(first.x, first.y)
            // A finger standing still is a line to where it already is.
            for (point in stroke.points.drop(1).ifEmpty { listOf(first) }) {
                lineTo(point.x, point.y)
            }
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return GestureDescription.StrokeDescription(path, 0, stroke.durationMs)
        }

        val previous = lastStroke
        if (stroke.continued && previous != null) {
            return previous.continueStroke(path, 0, stroke.durationMs, stroke.continues)
        }
        return GestureDescription.StrokeDescription(path, 0, stroke.durationMs, stroke.continues)
    }

    private fun onStrokeDone(completed: Boolean) {
        if (!completed) {
            lastStroke = null
        }
        planner.onStrokeDone(completed)?.let(::dispatch)
    }

    private fun listen(listening: Boolean) {
        val info = serviceInfo ?: return
        info.eventTypes = if (listening) FRESHNESS_EVENTS else 0
        runCatching { serviceInfo = info }
        if (listening && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            runCatching { clearCache() }
        }
    }

    private fun pointOf(x: Double, y: Double): GesturePoint {
        val metrics = screen()
        return GesturePoint(
            (x.coerceIn(0.0, 1.0) * (metrics.widthPixels - 1)).toFloat(),
            (y.coerceIn(0.0, 1.0) * (metrics.heightPixels - 1)).toFloat(),
        )
    }

    /** The whole screen as it is turned right now, bars included: what the computer's picture shows. */
    private fun screen(): DisplayMetrics {
        val metrics = DisplayMetrics()
        val displays = getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
        @Suppress("DEPRECATION")
        displays?.getDisplay(Display.DEFAULT_DISPLAY)?.getRealMetrics(metrics)
        return metrics
    }

    private fun disconnected() {
        if (instance !== this) {
            return
        }

        instance = null
        onEnabledChanged?.invoke(false)
    }

    companion object {
        /** The running service, or null while it is turned off in the system settings. */
        @Volatile
        var instance: FerretControlService? = null
            private set

        /** Set by the app while a computer may control this phone. Everything else is refused. */
        @Volatile
        var armed = false

        var onEnabledChanged: ((Boolean) -> Unit)? = null

        /** One wheel notch scrolls this part of the screen's height. */
        private const val SCROLL_STEP = 0.08

        /** What keeps the focused field's text and cursor current while typing into it. */
        private const val FRESHNESS_EVENTS = AccessibilityEvent.TYPE_VIEW_FOCUSED or
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED or
            AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED or
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
            AccessibilityEvent.TYPE_WINDOWS_CHANGED
    }
}
