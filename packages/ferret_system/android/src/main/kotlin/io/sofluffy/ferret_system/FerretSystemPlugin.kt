package io.sofluffy.ferret_system

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.app.StatusBarManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.net.wifi.WifiManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlin.coroutines.resume
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine

class FerretSystemPlugin :
    FlutterPlugin,
    ActivityAware,
    SystemHostApi,
    FerretRuntime.Listener,
    PluginRegistry.RequestPermissionsResultListener {
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var flutterApi: SystemFlutterApi? = null
    private var networkWatcher: NetworkWatcher? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    private var permissionResult: ((Boolean) -> Unit)? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val activity: Activity?
        get() = activityBinding?.activity

    /** An activity when one is showing, so system screens open in its task. */
    private val uiContext: Context?
        get() = activity ?: context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterApi = SystemFlutterApi(binding.binaryMessenger)
        SystemHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SystemHostApi.setUp(binding.binaryMessenger, null)
        FerretRuntime.clearListener(this)
        networkWatcher?.stop()
        networkWatcher = null
        releaseMulticastLock()
        scope.cancel()
        flutterApi = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        permissionResult?.invoke(false)
        permissionResult = null
    }

    override fun acquireMulticastLock() {
        if (multicastLock?.isHeld == true) {
            return
        }

        val wifi = context?.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return
        multicastLock = wifi.createMulticastLock("ferret-discovery").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    override fun releaseMulticastLock() {
        multicastLock?.takeIf { it.isHeld }?.release()
        multicastLock = null
    }

    override fun isMulticastLockHeld(): Boolean = multicastLock?.isHeld == true

    override fun listenForActions() {
        FerretRuntime.setListener(this)
    }

    override fun setNetworkWatching(watching: Boolean) {
        val appContext = context ?: return
        if (!watching) {
            networkWatcher?.stop()
            networkWatcher = null
            return
        }

        if (networkWatcher != null) {
            return
        }

        networkWatcher = NetworkWatcher(appContext) { change ->
            scope.launch { runCatching { flutterApi?.onNetworkChange(change) } }
        }.also { it.start() }
    }

    override fun startService() {
        val appContext = context ?: return
        SystemPrefs(appContext).serviceEnabled = true
        FerretService.start(appContext)
    }

    override fun stopService() {
        val appContext = context ?: return
        SystemPrefs(appContext).serviceEnabled = false
        FerretService.stop(appContext)
    }

    override fun isServiceRunning(): Boolean = FerretService.isRunning

    override fun setStartOnBoot(enabled: Boolean) {
        val appContext = context ?: return
        SystemPrefs(appContext).startOnBoot = enabled
    }

    override fun updateStatus(connectedDevices: List<String>) {
        val appContext = context ?: return
        FerretRuntime.updateStatus(appContext, connectedDevices)
    }

    override fun setPause(pause: PauseMessage) {
        val appContext = context ?: return
        FerretRuntime.setPauseFromDart(appContext, pause)
    }

    override fun pauseState(): PauseMessage {
        val appContext = context ?: return PauseMessage(paused = false)
        return FerretRuntime.pauseState(appContext)
    }

    override fun isIgnoringBatteryOptimizations(): Boolean {
        val appContext = context ?: return false
        return BatterySettings.isIgnoringOptimizations(appContext)
    }

    override fun requestIgnoreBatteryOptimizations(): Boolean {
        val target = uiContext ?: return false
        return BatterySettings.requestExemption(target)
    }

    override fun manufacturer(): String = BatterySettings.manufacturer()

    override fun openMakerBatterySettings(): Boolean {
        val target = uiContext ?: return false
        return BatterySettings.openMakerSettings(target)
    }

    override fun isBackgroundRestricted(): Boolean {
        val appContext = context ?: return false
        return BatterySettings.isBackgroundRestricted(appContext)
    }

    override fun openAppSettings(): Boolean {
        val target = uiContext ?: return false
        return BatterySettings.openAppSettings(target)
    }

    override fun recentServiceStops(): List<Long> {
        val appContext = context ?: return emptyList()
        return ServiceStops.recent(appContext)
    }

    override fun canRequestAddTile(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && activity != null

    override suspend fun requestAddTile(): AddTileResult {
        val current = activity
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || current == null) {
            return AddTileResult.UNSUPPORTED
        }

        val statusBar = current.getSystemService(StatusBarManager::class.java) ?: return AddTileResult.UNSUPPORTED
        return suspendCancellableCoroutine { continuation ->
            statusBar.requestAddTileService(
                FerretTileService.component(current),
                current.getString(R.string.ferret_system_tile_label),
                Icon.createWithResource(current, R.drawable.ferret_system_status),
                current.mainExecutor,
            ) { code ->
                val result = when (code) {
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED -> AddTileResult.ADDED
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED -> AddTileResult.ALREADY_ADDED
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED -> AddTileResult.NOT_ADDED
                    else -> AddTileResult.UNSUPPORTED
                }
                if (continuation.isActive) {
                    continuation.resume(result)
                }
            }
        }
    }

    override fun areNotificationsAllowed(): Boolean {
        val appContext = context ?: return false
        val manager = appContext.getSystemService(NotificationManager::class.java) ?: return false
        return manager.areNotificationsEnabled()
    }

    override suspend fun requestNotificationPermission(): Boolean {
        val current = activity
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || current == null) {
            return areNotificationsAllowed()
        }

        if (current.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            return true
        }

        return suspendCancellableCoroutine { continuation ->
            permissionResult?.invoke(false)
            permissionResult = { granted ->
                if (continuation.isActive) {
                    continuation.resume(granted)
                }
            }
            current.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
        }
    }

    /** A phone in someone's hand has no other account in front; computers ask. */
    override fun isScreenSessionActive(): Boolean = true

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_NOTIFICATIONS) {
            return false
        }

        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        permissionResult?.invoke(granted)
        permissionResult = null
        context?.let { FerretService.refreshNotification(it) }
        return true
    }

    override fun onAction(action: SystemActionMessage) {
        scope.launch { runCatching { flutterApi?.onAction(action) } }
    }

    override fun onPauseChanged(pause: PauseMessage) {
        scope.launch { runCatching { flutterApi?.onPauseChanged(pause) } }
    }

    override fun onReconnectDue() {
        scope.launch { runCatching { flutterApi?.onNetworkChange(NetworkChange.WAKE) } }
    }

    private companion object {
        const val REQUEST_NOTIFICATIONS = 47641
    }
}
