package io.sofluffy.ferret_system

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * One Flutter engine for the whole process, shared by the activity, the
 * foreground service and the Quick Settings tile, so Dart `main()` runs once
 * whichever of them starts first.
 *
 * In the app's `MainActivity`, return [ensureEngine] from
 * `provideFlutterEngine` and `false` from `shouldDestroyEngineWithHost`.
 */
object FerretRuntime {
    const val ENGINE_ID = "ferret"

    /** Receives what happens outside Dart: the plugin of the running engine. */
    interface Listener {
        fun onAction(action: SystemActionMessage)

        fun onPauseChanged(pause: PauseMessage)
    }

    private const val MAX_QUEUED_ACTIONS = 8

    private val main = Handler(Looper.getMainLooper())
    private val queuedActions = ArrayDeque<SystemActionMessage>()
    private var listener: Listener? = null

    /** Names of the devices connected right now, as Dart last reported them. */
    var connectedDevices: List<String> = emptyList()
        private set

    /** Returns the running engine, starting it (and Dart `main()`) if needed. */
    @JvmStatic
    fun ensureEngine(context: Context): FlutterEngine {
        val cache = FlutterEngineCache.getInstance()
        cache.get(ENGINE_ID)?.let { return it }

        val engine = FlutterEngine(context.applicationContext)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        cache.put(ENGINE_ID, engine)
        return engine
    }

    fun isEngineRunning(): Boolean = FlutterEngineCache.getInstance().contains(ENGINE_ID)

    /** Starts the engine, and the service if the user keeps Ferret running. */
    fun wake(context: Context) {
        ensureEngine(context)
        if (SystemPrefs(context).serviceEnabled) {
            FerretService.start(context)
        }
    }

    fun setListener(value: Listener?) {
        listener = value
        if (value == null) {
            return
        }

        while (queuedActions.isNotEmpty()) {
            value.onAction(queuedActions.removeFirst())
        }
    }

    fun clearListener(value: Listener) {
        if (listener === value) {
            listener = null
        }
    }

    /** Sends [action] to Dart now, or once Dart starts listening. */
    fun dispatch(action: SystemActionMessage) {
        main.post {
            val current = listener
            if (current != null) {
                current.onAction(action)
                return@post
            }

            if (queuedActions.size >= MAX_QUEUED_ACTIONS) {
                queuedActions.removeFirst()
            }
            queuedActions.addLast(action)
        }
    }

    fun updateStatus(context: Context, devices: List<String>) {
        if (devices == connectedDevices) {
            return
        }

        connectedDevices = devices
        refreshSurfaces(context)
    }

    /** Pause chosen in Dart: show it, and wake Ferret up when it ends. */
    fun setPauseFromDart(context: Context, pause: PauseMessage) {
        applyPause(context, pause)
    }

    /** Pause chosen outside Dart (the notification, or a pause running out). */
    fun setPauseFromSystem(context: Context, pause: PauseMessage) {
        if (!applyPause(context, pause)) {
            return
        }

        main.post { listener?.onPauseChanged(pause) }
    }

    fun pauseState(context: Context): PauseMessage {
        val prefs = SystemPrefs(context)
        val until = prefs.pausedUntil
        if (prefs.paused && until != null && until <= System.currentTimeMillis()) {
            prefs.setPause(false, null)
        }

        return PauseMessage(paused = prefs.paused, untilMs = prefs.pausedUntil)
    }

    private fun applyPause(context: Context, pause: PauseMessage): Boolean {
        val prefs = SystemPrefs(context)
        val untilMs = pause.untilMs.takeIf { pause.paused }
        if (prefs.paused == pause.paused && prefs.pausedUntil == untilMs) {
            return false
        }

        prefs.setPause(pause.paused, untilMs)
        PauseAlarm.schedule(context, untilMs)
        refreshSurfaces(context)
        return true
    }

    private fun refreshSurfaces(context: Context) {
        FerretService.refreshNotification(context)
        FerretTileService.requestRefresh(context)
    }
}
