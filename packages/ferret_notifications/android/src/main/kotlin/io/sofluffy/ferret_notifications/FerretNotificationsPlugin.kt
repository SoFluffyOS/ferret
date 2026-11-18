package io.sofluffy.ferret_notifications

import android.app.AppOpsManager
import android.app.KeyguardManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Reads, acts on and dismisses other apps' notifications for Dart. */
class FerretNotificationsPlugin :
    FlutterPlugin,
    NotificationsHostApi,
    NotificationHub.Sink {
    private var context: Context? = null
    private var flutterApi: NotificationsFlutterApi? = null
    private var scope: CoroutineScope? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterApi = NotificationsFlutterApi(binding.binaryMessenger)
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        NotificationsHostApi.setUp(binding.binaryMessenger, this)
        NotificationHub.add(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        NotificationHub.remove(this)
        NotificationsHostApi.setUp(binding.binaryMessenger, null)
        scope?.cancel()
        scope = null
        flutterApi = null
        context = null
    }

    override fun onPosted(notification: PlatformNotification) {
        deliver { it.onPosted(notification) }
    }

    override fun onRemoved(key: String) {
        deliver { it.onRemoved(key) }
    }

    override fun onListenerChanged(connected: Boolean) {
        deliver { it.onListenerChanged(connected) }
    }

    override fun isAccessGranted(): Boolean {
        val context = requireContext()
        val component = FerretNotificationListener.componentName(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val manager = context.getSystemService(NotificationManager::class.java)
            return manager?.isNotificationListenerAccessGranted(component) == true
        }

        val enabled = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
            ?: return false
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == component }
    }

    override fun mayBeRestricted(): Boolean {
        val context = requireContext()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return false
        }

        val opMode = runCatching {
            context.getSystemService(AppOpsManager::class.java)
                ?.unsafeCheckOpNoThrow(RestrictedSettings.OP_NAME, Process.myUid(), context.packageName)
        }.getOrNull()
        val packageSource = runCatching {
            context.packageManager.getInstallSourceInfo(context.packageName).packageSource
        }.getOrNull()

        return RestrictedSettings.isLikelyRestricted(
            sdk = Build.VERSION.SDK_INT,
            accessGranted = isAccessGranted(),
            opMode = opMode,
            packageSource = packageSource,
        )
    }

    override fun openAccessSettings() {
        val context = requireContext()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val detail = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                FerretNotificationListener.componentName(context).flattenToString(),
            )
            if (start(context, detail)) {
                return
            }
        }

        if (!start(context, Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))) {
            throw FlutterError("unavailable", "This device has no notification access settings page.")
        }
    }

    override fun openAppInfo() {
        val context = requireContext()
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        )
        if (!start(context, intent)) {
            throw FlutterError("unavailable", "This device has no App info page.")
        }
    }

    override fun isDeviceInUse(): Boolean {
        val context = requireContext()
        val power = context.getSystemService(PowerManager::class.java)
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        return power?.isInteractive == true && keyguard?.isKeyguardLocked != true
    }

    override suspend fun listApps(): List<PlatformApp> {
        val context = requireContext()

        return withContext(Dispatchers.IO) {
            val packageManager = context.packageManager
            val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)

            @Suppress("DEPRECATION")
            val activities = packageManager.queryIntentActivities(launcher, 0)
            activities
                .map { it.activityInfo.packageName }
                .distinct()
                .filter { it != context.packageName }
                .map { packageName ->
                    PlatformApp(
                        packageName = packageName,
                        name = NotificationReader.appName(packageManager, packageName),
                        icon = AppIcons.pickerIcon(context, packageName),
                    )
                }
                .sortedBy { it.name.lowercase() }
        }
    }

    override fun invokeAction(key: String, actionId: String, replyText: String?): Boolean {
        val context = requireContext()
        val listener = FerretNotificationListener.connected ?: return false
        val notification = listener.findActive(key)?.notification ?: return false
        val index = actionId.toIntOrNull() ?: return false
        val action = notification.actions?.getOrNull(index) ?: return false
        val intent = action.actionIntent ?: return false
        val inputs = action.remoteInputs.orEmpty().filter { it.allowFreeFormInput }

        return try {
            if (replyText == null || inputs.isEmpty()) {
                intent.send()
                return true
            }

            val results = Bundle()
            inputs.forEach { results.putCharSequence(it.resultKey, replyText) }
            val fillIn = Intent()
            RemoteInput.addResultsToIntent(inputs.toTypedArray(), fillIn, results)
            intent.send(context, 0, fillIn)
            true
        } catch (_: PendingIntent.CanceledException) {
            false
        }
    }

    override fun cancel(key: String): Boolean {
        val listener = FerretNotificationListener.connected ?: return false
        listener.cancelNotification(key)
        return true
    }

    private fun deliver(call: suspend (NotificationsFlutterApi) -> Unit) {
        val api = flutterApi ?: return
        scope?.launch { runCatching { call(api) } }
    }

    private fun requireContext(): Context =
        context ?: throw FlutterError("detached", "The plugin is not attached to an engine.")

    private fun start(context: Context, intent: Intent): Boolean =
        try {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
}
