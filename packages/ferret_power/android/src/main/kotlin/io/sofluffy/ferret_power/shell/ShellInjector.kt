package io.sofluffy.ferret_power.shell

import android.os.SystemClock
import android.view.InputDevice
import android.view.InputEvent
import android.view.KeyCharacterMap
import android.view.KeyEvent
import android.view.MotionEvent
import java.lang.reflect.Method

/**
 * Injects touches, keys and text as the shell user, which holds
 * `INJECT_EVENTS`. It goes through the input manager's own
 * `injectInputEvent`, the call `adb shell input` makes, so there is no
 * command line. What is typed passes through and is never logged.
 */
class ShellInjector {
    private val manager: Any? by lazy { runCatching { connect() }.getOrNull() }
    private val injectMethod: Method? by lazy {
        manager?.javaClass?.methods?.firstOrNull { method ->
            method.name == "injectInputEvent" && method.parameterTypes.size == 2
        }
    }
    private val keyMap: KeyCharacterMap? by lazy {
        runCatching { KeyCharacterMap.load(KeyCharacterMap.VIRTUAL_KEYBOARD) }.getOrNull()
    }
    private var touchDownAt = 0L

    @Synchronized
    fun run(input: ShellInput): Boolean = when (val checked = ShellInput.checked(input)) {
        is ShellInput.Touch -> touch(checked)
        is ShellInput.Scroll -> scroll(checked)
        is ShellInput.Key -> key(checked)
        is ShellInput.Text -> text(checked)
        null -> false
    }

    /** Lifts a finger that was left down, so nothing stays pressed. */
    @Synchronized
    fun release() {
        if (touchDownAt == 0L) {
            return
        }

        touch(ShellInput.Touch(ShellInput.ACTION_CANCEL, 0f, 0f))
    }

    private fun touch(input: ShellInput.Touch): Boolean {
        val now = SystemClock.uptimeMillis()
        if (input.action == ShellInput.ACTION_DOWN) {
            touchDownAt = now
        }
        if (touchDownAt == 0L) {
            return false
        }

        val lifted = input.action == ShellInput.ACTION_UP || input.action == ShellInput.ACTION_CANCEL
        val event = motion(
            downAt = touchDownAt,
            now = now,
            action = input.action,
            x = input.x,
            y = input.y,
            pressure = if (lifted) 0f else 1f,
            source = InputDevice.SOURCE_TOUCHSCREEN,
            toolType = MotionEvent.TOOL_TYPE_FINGER,
        )
        if (lifted) {
            touchDownAt = 0L
        }
        return inject(event)
    }

    private fun scroll(input: ShellInput.Scroll): Boolean {
        val now = SystemClock.uptimeMillis()
        val event = motion(
            downAt = now,
            now = now,
            action = MotionEvent.ACTION_SCROLL,
            x = input.x,
            y = input.y,
            pressure = 0f,
            source = InputDevice.SOURCE_MOUSE,
            toolType = MotionEvent.TOOL_TYPE_MOUSE,
            horizontal = input.horizontal,
            vertical = input.vertical,
        )
        return inject(event)
    }

    private fun key(input: ShellInput.Key): Boolean {
        val now = SystemClock.uptimeMillis()
        val action = if (input.down) KeyEvent.ACTION_DOWN else KeyEvent.ACTION_UP
        return inject(
            KeyEvent(
                now,
                now,
                action,
                input.keyCode,
                0,
                input.metaState,
                KeyCharacterMap.VIRTUAL_KEYBOARD,
                0,
                0,
                InputDevice.SOURCE_KEYBOARD,
            ),
        )
    }

    /** Types what the virtual keyboard's key map can type. False when a character has no key. */
    private fun text(input: ShellInput.Text): Boolean {
        val keyMap = keyMap ?: return false
        var typedAll = true
        for (character in input.text) {
            val events = runCatching { keyMap.getEvents(charArrayOf(character)) }.getOrNull()
            if (events == null) {
                typedAll = false
                continue
            }
            for (event in events) {
                typedAll = inject(KeyEvent.changeTimeRepeat(event, SystemClock.uptimeMillis(), 0)) && typedAll
            }
        }
        return typedAll
    }

    private fun motion(
        downAt: Long,
        now: Long,
        action: Int,
        x: Float,
        y: Float,
        pressure: Float,
        source: Int,
        toolType: Int,
        horizontal: Float = 0f,
        vertical: Float = 0f,
    ): MotionEvent {
        val properties = MotionEvent.PointerProperties().apply {
            id = 0
            this.toolType = toolType
        }
        val coordinates = MotionEvent.PointerCoords().apply {
            this.x = x
            this.y = y
            this.pressure = pressure
            size = 1f
            setAxisValue(MotionEvent.AXIS_HSCROLL, horizontal)
            setAxisValue(MotionEvent.AXIS_VSCROLL, vertical)
        }
        return MotionEvent.obtain(
            downAt,
            now,
            action,
            1,
            arrayOf(properties),
            arrayOf(coordinates),
            0,
            0,
            1f,
            1f,
            0,
            0,
            source,
            0,
        )
    }

    private fun inject(event: InputEvent): Boolean {
        val manager = manager ?: return false
        val method = injectMethod ?: return false
        return runCatching { method.invoke(manager, event, INJECT_ASYNC) == true }.getOrDefault(false)
    }

    /** Android 14 moved the instance behind `InputManagerGlobal`; older ones keep it on `InputManager`. */
    private fun connect(): Any? {
        for (className in MANAGER_CLASSES) {
            val found = runCatching {
                Class.forName(className).getDeclaredMethod("getInstance").invoke(null)
            }.getOrNull()
            if (found != null) {
                return found
            }
        }
        return null
    }

    private companion object {
        /** `InputManager.INJECT_INPUT_EVENT_MODE_ASYNC`. */
        const val INJECT_ASYNC = 0

        val MANAGER_CLASSES = listOf(
            "android.hardware.input.InputManagerGlobal",
            "android.hardware.input.InputManager",
        )
    }
}
