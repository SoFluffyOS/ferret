package io.sofluffy.ferret

import android.content.Context
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
}
