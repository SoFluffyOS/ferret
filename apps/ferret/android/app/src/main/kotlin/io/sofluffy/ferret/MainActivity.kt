package io.sofluffy.ferret

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.sofluffy.ferret_system.FerretRuntime

/**
 * Shows the engine the foreground service keeps running, so closing the app
 * doesn't stop Ferret and opening it again is instant.
 */
class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine = FerretRuntime.ensureEngine(context)

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val engineWasRunning = FerretRuntime.isEngineRunning()
        super.onCreate(savedInstanceState)
        if (engineWasRunning && savedInstanceState == null && isNoticeTap(intent)) {
            // The notification plugin reads a tap from the intent that starts
            // the app only when Dart starts with it; here Dart was already
            // running, so the tap goes in the way a tap on an open app does.
            flutterEngine?.activityControlSurface?.onNewIntent(intent)
        }
    }

    private fun isNoticeTap(intent: Intent?): Boolean {
        if (intent == null || intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) {
            return false
        }

        return intent.action == "SELECT_NOTIFICATION" || intent.action == "SELECT_FOREGROUND_NOTIFICATION"
    }
}
