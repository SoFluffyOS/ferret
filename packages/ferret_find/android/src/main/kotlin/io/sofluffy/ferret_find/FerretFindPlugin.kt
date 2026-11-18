package io.sofluffy.ferret_find

import android.app.Activity
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/** Rings this phone for Dart, and shows the app over the lock screen while it rings. */
class FerretFindPlugin :
    FlutterPlugin,
    ActivityAware,
    FindHostApi,
    FindAlarm.Listener {
    private var context: Context? = null
    private var activity: Activity? = null
    private var flutterApi: FindFlutterApi? = null
    private var scope: CoroutineScope? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterApi = FindFlutterApi(binding.binaryMessenger)
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        FindHostApi.setUp(binding.binaryMessenger, this)
        FindAlarm.listener = this
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (FindAlarm.listener === this) {
            FindAlarm.listener = null
        }
        FindHostApi.setUp(binding.binaryMessenger, null)
        scope?.cancel()
        scope = null
        flutterApi = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (FindAlarm.isRinging) {
            showOverLockScreen(true)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onStopped(reason: String) {
        showOverLockScreen(false)
        val api = flutterApi ?: return
        scope?.launch { runCatching { api.onAlertStopped(reason) } }
    }

    override fun abilities(): PlatformRingAbilities {
        val context = requireContext()
        val control = AudioControl(context)
        val fullScreenAllowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            context.getSystemService(NotificationManager::class.java)?.canUseFullScreenIntent() != false
        } else {
            true
        }

        return PlatformRingAbilities(
            controlsVolume = control.controlsVolume,
            needsDndAccess = true,
            dndAccessGranted = control.dndAccessGranted,
            fullScreenAllowed = fullScreenAllowed,
            hasTorch = TorchBlinker.hasTorch(context),
            ringsInBackground = true,
            showsOwnAlert = true,
        )
    }

    override fun readAudio(): PlatformAudio? = AudioControl(requireContext()).read()

    override fun applyAudio(audio: PlatformAudio) {
        FindAlarm.volumeKeys.ownChange(SystemClock.elapsedRealtime())
        AudioControl(requireContext()).apply(audio)
        FindAlarm.volumeKeys.ownChange(SystemClock.elapsedRealtime())
    }

    override fun startAlert(alert: PlatformAlert) {
        FindAlarm.start(requireContext(), alert)
        showOverLockScreen(true)
    }

    override fun stopAlert() {
        FindAlarm.release()
        showOverLockScreen(false)
    }

    override fun openDndAccessSettings() {
        if (!start(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))) {
            throw FlutterError("unavailable", "This phone has no Do Not Disturb access page.")
        }
    }

    override fun openFullScreenSettings() {
        val context = requireContext()
        val packageUri = Uri.fromParts("package", context.packageName, null)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            start(Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, packageUri))
        ) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            start(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName))
        ) {
            return
        }

        if (!start(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri))) {
            throw FlutterError("unavailable", "This phone has no notification settings page for Ferret.")
        }
    }

    /** Lets the ringing screen with "Found it" show without unlocking. */
    @Suppress("DEPRECATION")
    private fun showOverLockScreen(show: Boolean) {
        val activity = activity ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            activity.setShowWhenLocked(show)
            activity.setTurnScreenOn(show)
            return
        }

        val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        if (show) {
            activity.window.addFlags(flags)
            return
        }

        activity.window.clearFlags(flags)
    }

    private fun start(intent: Intent): Boolean {
        val context = requireContext()
        return try {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (error: ActivityNotFoundException) {
            false
        } catch (error: SecurityException) {
            false
        }
    }

    private fun requireContext(): Context =
        context ?: throw FlutterError("detached", "The find plugin is not attached.")
}
