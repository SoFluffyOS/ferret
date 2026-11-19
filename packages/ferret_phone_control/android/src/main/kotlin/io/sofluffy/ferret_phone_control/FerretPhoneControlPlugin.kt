package io.sofluffy.ferret_phone_control

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * The app's line to [FerretControlService]: whether it is on, the way to its
 * switch in the system settings, and what to do on the phone. It only does
 * what Dart tells it, and the service refuses everything unless armed.
 */
class FerretPhoneControlPlugin : FlutterPlugin, ControlServiceHostApi {
    private var context: Context? = null
    private var flutterApi: ControlServiceFlutterApi? = null
    private var scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        flutterApi = ControlServiceFlutterApi(binding.binaryMessenger)
        FerretControlService.onEnabledChanged = { enabled ->
            scope.launch {
                try {
                    flutterApi?.onEnabledChanged(enabled)
                } catch (error: Throwable) {
                    android.util.Log.w(TAG, "Dart did not hear the service change", error)
                }
            }
        }
        ControlServiceHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ControlServiceHostApi.setUp(binding.binaryMessenger, null)
        FerretControlService.onEnabledChanged = null
        setArmed(false)
        scope.cancel()
        flutterApi = null
        context = null
    }

    override fun isEnabled(): Boolean = FerretControlService.instance != null

    /** Opens the Accessibility settings with Ferret's row brought into view, where Android does that. */
    override fun openSettings(): Boolean {
        val context = context ?: return false
        val component = ComponentName(context, FerretControlService::class.java).flattenToString()
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .putExtra(FRAGMENT_ARG_KEY, component)
            .putExtra(SHOW_FRAGMENT_ARGS, Bundle().apply { putString(FRAGMENT_ARG_KEY, component) })
        return runCatching { context.startActivity(intent) }.isSuccess
    }

    override fun setArmed(armed: Boolean) {
        FerretControlService.armed = armed
        FerretControlService.instance?.onArmedChanged(armed)
    }

    override fun touch(action: ServiceTouch, x: Double, y: Double): Boolean =
        FerretControlService.instance?.touch(action, x, y) == true

    override fun scroll(x: Double, y: Double, horizontal: Double, vertical: Double): Boolean =
        FerretControlService.instance?.scroll(x, y, horizontal, vertical) == true

    override fun typeText(text: String): Boolean = FerretControlService.instance?.typeText(text) == true

    override fun pressKey(key: ServiceKey): Boolean = FerretControlService.instance?.pressKey(key) == true

    override fun pressButton(button: ServiceButton): Boolean =
        FerretControlService.instance?.pressButton(button) == true

    private companion object {
        const val TAG = "FerretPhoneControl"
        const val FRAGMENT_ARG_KEY = ":settings:fragment_args_key"
        const val SHOW_FRAGMENT_ARGS = ":settings:show_fragment_args"
    }
}
