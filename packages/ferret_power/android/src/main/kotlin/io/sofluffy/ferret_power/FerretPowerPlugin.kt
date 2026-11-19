package io.sofluffy.ferret_power

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.display.DisplayManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.Display
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.sofluffy.ferret_power.shell.ShellClip
import io.sofluffy.ferret_power.shell.ShellGrants
import io.sofluffy.ferret_power.shell.ShellInput
import io.sofluffy.ferret_power.shell.ShellOptions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Finds Shizuku and root, and runs the few things Ferret asks of them. This
 * class only does what Dart tells it: `PowerCapabilities` decides whether a
 * tier may be used. Clipboard text passes through and is never logged.
 */
class FerretPowerPlugin : FlutterPlugin, PowerHostApi {
    private var context: Context? = null
    private var flutterApi: PowerFlutterApi? = null
    private var shizuku: ShizukuGateway? = null
    private var root: RootGateway? = null
    private var scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val main = Handler(Looper.getMainLooper())

    /** One thread, so a touch's down, moves and up reach the root helper in order. */
    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    private val rootInput = Dispatchers.IO.limitedParallelism(1)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        val options = ShellOptions(
            userId = Process.myUserHandle().hashCode(),
            packageName = context.packageName,
            listenerComponent = "${context.packageName}/$NOTIFICATION_LISTENER",
        )

        this.context = context
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        flutterApi = PowerFlutterApi(binding.binaryMessenger)
        shizuku = ShizukuGateway(context, options, ::notifyState, ::notifyClip, ::notifyWatchStopped).also {
            it.attach()
        }
        root = RootGateway(context, options, ::notifyClip, ::notifyWatchStopped)
        PowerHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PowerHostApi.setUp(binding.binaryMessenger, null)
        shizuku?.detach()
        root?.let { gateway -> Thread { gateway.unwatch() }.start() }
        scope.cancel()
        shizuku = null
        root = null
        flutterApi = null
        context = null
    }

    override fun getState(): PlatformPowerState {
        val context = context
        val shizuku = shizuku
        val root = root
        return PlatformPowerState(
            shizukuInstalled = shizuku?.installed == true,
            shizukuRunning = shizuku?.running == true,
            shizukuGranted = shizuku?.granted == true,
            rootFound = root?.found == true,
            rootGranted = root?.granted == true,
            rootManager = root?.manager ?: PlatformRootManager.NONE,
            notificationAccess = context != null && hasNotificationAccess(context),
            messagesAndCalls = context != null && hasMessagesOrCalls(context),
            batteryUnrestricted = context != null && isBatteryUnrestricted(context),
        )
    }

    override suspend fun requestShizukuPermission(): Boolean = shizuku?.requestPermission() == true

    override fun openShizuku(): Boolean {
        val context = context ?: return false
        val intent = context.packageManager.getLaunchIntentForPackage(ShizukuGateway.SHIZUKU_PACKAGE) ?: return false
        return open(context, intent)
    }

    override fun openNotificationAccessSettings(): Boolean {
        val context = context ?: return false
        return open(context, Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }

    override fun openAppSettings(): Boolean {
        val context = context ?: return false
        val details = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        )
        return open(context, details)
    }

    override suspend fun requestRoot(): Boolean {
        val root = root ?: return false
        return withContext(Dispatchers.IO) { root.request() }
    }

    override suspend fun readClipboard(backend: PlatformPowerBackend): PlatformPowerClip? {
        val clip = when (backend) {
            PlatformPowerBackend.SHIZUKU -> shizuku?.read()
            PlatformPowerBackend.ROOT -> root?.let { gateway -> withContext(Dispatchers.IO) { gateway.read() } }
        }
        return clip?.let { PlatformPowerClip(text = it.text, sensitive = it.sensitive) }
    }

    override suspend fun startClipboardWatch(backend: PlatformPowerBackend) {
        stopClipboardWatch()
        val started = when (backend) {
            PlatformPowerBackend.SHIZUKU -> shizuku?.watch() == true
            PlatformPowerBackend.ROOT -> root?.let { gateway -> withContext(Dispatchers.IO) { gateway.watch() } } == true
        }
        if (!started) {
            throw FlutterError("watch_failed", "The clipboard watch could not start.")
        }
    }

    override suspend fun stopClipboardWatch() {
        shizuku?.unwatch()
        root?.let { gateway -> withContext(Dispatchers.IO) { gateway.unwatch() } }
    }

    override suspend fun grant(backend: PlatformPowerBackend, grant: PlatformPowerGrant): Boolean {
        val name = when (grant) {
            PlatformPowerGrant.NOTIFICATION_ACCESS -> ShellGrants.NOTIFICATION_ACCESS
            PlatformPowerGrant.BATTERY_UNRESTRICTED -> ShellGrants.BATTERY_UNRESTRICTED
        }
        return when (backend) {
            PlatformPowerBackend.SHIZUKU -> shizuku?.grant(name) == true
            PlatformPowerBackend.ROOT -> root?.let { gateway -> withContext(Dispatchers.IO) { gateway.grant(name) } } == true
        }
    }

    override suspend fun injectTouch(
        backend: PlatformPowerBackend,
        action: PlatformTouchAction,
        x: Double,
        y: Double,
    ): Boolean {
        val (pixelX, pixelY) = pixelsOf(x, y) ?: return false
        val code = when (action) {
            PlatformTouchAction.DOWN -> ShellInput.ACTION_DOWN
            PlatformTouchAction.MOVE -> ShellInput.ACTION_MOVE
            PlatformTouchAction.UP -> ShellInput.ACTION_UP
            PlatformTouchAction.CANCEL -> ShellInput.ACTION_CANCEL
        }
        return inject(backend, ShellInput.Touch(code, pixelX, pixelY))
    }

    override suspend fun injectScroll(
        backend: PlatformPowerBackend,
        x: Double,
        y: Double,
        horizontal: Double,
        vertical: Double,
    ): Boolean {
        val (pixelX, pixelY) = pixelsOf(x, y) ?: return false
        return inject(backend, ShellInput.Scroll(pixelX, pixelY, horizontal.toFloat(), vertical.toFloat()))
    }

    override suspend fun injectKey(
        backend: PlatformPowerBackend,
        keyCode: Long,
        down: Boolean,
        metaState: Long,
    ): Boolean = inject(backend, ShellInput.Key(keyCode.toInt(), down, metaState.toInt()))

    override suspend fun injectText(backend: PlatformPowerBackend, text: String): Boolean =
        inject(backend, ShellInput.Text(text))

    override suspend fun releaseInput() {
        shizuku?.releaseInput()
        root?.let { gateway -> withContext(rootInput) { gateway.releaseInput() } }
    }

    private suspend fun inject(backend: PlatformPowerBackend, input: ShellInput): Boolean {
        val checked = ShellInput.checked(input) ?: return false
        return when (backend) {
            PlatformPowerBackend.SHIZUKU -> shizuku?.inject(checked) == true
            PlatformPowerBackend.ROOT -> root?.let { gateway -> withContext(rootInput) { gateway.inject(checked) } } == true
        }
    }

    /** A place given as fractions of the screen, in pixels of the screen as it is turned right now. */
    private fun pixelsOf(x: Double, y: Double): Pair<Float, Float>? {
        val displays = context?.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager ?: return null
        val display = displays.getDisplay(Display.DEFAULT_DISPLAY) ?: return null
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        display.getRealMetrics(metrics)
        val pixelX = (x.coerceIn(0.0, 1.0) * (metrics.widthPixels - 1)).toFloat()
        val pixelY = (y.coerceIn(0.0, 1.0) * (metrics.heightPixels - 1)).toFloat()
        return pixelX to pixelY
    }

    private fun notifyState() = onMain { api -> api.onStateChanged(getState()) }

    private fun notifyClip(clip: ShellClip) = onMain { api ->
        api.onClipboardChanged(PlatformPowerClip(text = clip.text, sensitive = clip.sensitive))
    }

    private fun notifyWatchStopped() = onMain { api -> api.onClipboardWatchStopped() }

    /** Gateways call back from binder and reader threads; Flutter wants the main one. */
    private fun onMain(send: suspend (PowerFlutterApi) -> Unit) {
        main.post {
            val api = flutterApi ?: return@post
            scope.launch { runCatching { send(api) } }
        }
    }

    private fun open(context: Context, intent: Intent): Boolean = runCatching {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }.isSuccess

    private fun hasNotificationAccess(context: Context): Boolean {
        val listeners = Settings.Secure.getString(context.contentResolver, ENABLED_LISTENERS).orEmpty()
        return listeners.split(':').any { it.startsWith("${context.packageName}/") }
    }

    private fun hasMessagesOrCalls(context: Context): Boolean =
        listOf(Manifest.permission.READ_SMS, Manifest.permission.READ_PHONE_STATE).any { permission ->
            context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        }

    private fun isBatteryUnrestricted(context: Context): Boolean {
        val power = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return false
        return power.isIgnoringBatteryOptimizations(context.packageName)
    }

    private companion object {
        /** The listener the notifications plugin declares; see the feature contract. */
        const val NOTIFICATION_LISTENER = "io.sofluffy.ferret_notifications.FerretNotificationListener"
        const val ENABLED_LISTENERS = "enabled_notification_listeners"
    }
}
