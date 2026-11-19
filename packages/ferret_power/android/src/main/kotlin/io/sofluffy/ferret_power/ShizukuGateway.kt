package io.sofluffy.ferret_power

import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.IBinder
import io.sofluffy.ferret_power.shell.IPowerClipListener
import io.sofluffy.ferret_power.shell.IPowerShellService
import io.sofluffy.ferret_power.shell.PowerShellService
import io.sofluffy.ferret_power.shell.ShellClip
import io.sofluffy.ferret_power.shell.ShellClipboard
import io.sofluffy.ferret_power.shell.ShellInput
import io.sofluffy.ferret_power.shell.ShellOptions
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import rikka.shizuku.Shizuku

/**
 * Shizuku on this phone: whether it is installed, running and authorized,
 * and Ferret's helper service inside it. Call from the main thread; the
 * binder calls to the helper move to a background thread themselves.
 */
internal class ShizukuGateway(
    private val context: Context,
    private val options: ShellOptions,
    private val onStateChanged: () -> Unit,
    private val onClip: (ShellClip) -> Unit,
    private val onWatchStopped: () -> Unit,
) {
    private var service: IPowerShellService? = null
    private var connecting: CompletableDeferred<IPowerShellService?>? = null
    private var permission: CompletableDeferred<Boolean>? = null
    private var watching = false

    /** One thread, so a touch's down, moves and up reach the helper in order. */
    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    private val inputThread = Dispatchers.IO.limitedParallelism(1)

    private val binderReceived = Shizuku.OnBinderReceivedListener { onStateChanged() }

    private val binderDead = Shizuku.OnBinderDeadListener {
        onServiceLost()
        onStateChanged()
    }

    private val permissionResult = Shizuku.OnRequestPermissionResultListener { requestCode, result ->
        if (requestCode == PERMISSION_REQUEST) {
            permission?.complete(result == PackageManager.PERMISSION_GRANTED)
            permission = null
            onStateChanged()
        }
    }

    private val clipListener = object : IPowerClipListener.Stub() {
        override fun onClipChanged(clip: Bundle?) {
            ShellClipboard.clipOf(clip)?.let(onClip)
        }
    }

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            val connected = binder?.takeIf { it.pingBinder() }?.let(IPowerShellService.Stub::asInterface)
            service = connected
            connecting?.complete(connected)
            connecting = null
        }

        override fun onServiceDisconnected(name: ComponentName?) = onServiceLost()
    }

    private val serviceArgs: Shizuku.UserServiceArgs
        get() = Shizuku.UserServiceArgs(ComponentName(context.packageName, PowerShellService::class.java.name))
            .daemon(false)
            .processNameSuffix("power")
            .debuggable(false)
            .version(SERVICE_VERSION)

    /** The Shizuku app, or Sui, which has no app but answers the same way. */
    val installed: Boolean
        get() = running || isAppInstalled()

    val running: Boolean
        get() = runCatching { Shizuku.pingBinder() }.getOrDefault(false)

    val granted: Boolean
        get() = running && runCatching {
            !Shizuku.isPreV11() && Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
        }.getOrDefault(false)

    fun attach() {
        Shizuku.addBinderReceivedListenerSticky(binderReceived)
        Shizuku.addBinderDeadListener(binderDead)
        Shizuku.addRequestPermissionResultListener(permissionResult)
    }

    fun detach() {
        Shizuku.removeBinderReceivedListener(binderReceived)
        Shizuku.removeBinderDeadListener(binderDead)
        Shizuku.removeRequestPermissionResultListener(permissionResult)
        permission?.complete(false)
        permission = null
        connecting?.complete(null)
        connecting = null
        if (service != null) {
            runCatching { Shizuku.unbindUserService(serviceArgs, connection, true) }
        }
        service = null
        watching = false
    }

    /** Shows Shizuku's dialog. False when it isn't running, or the user said no. */
    suspend fun requestPermission(): Boolean {
        if (granted) {
            return true
        }

        val refusedForGood = runCatching {
            Shizuku.isPreV11() || Shizuku.shouldShowRequestPermissionRationale()
        }.getOrDefault(true)
        if (!running || refusedForGood) {
            return false
        }

        val answer = CompletableDeferred<Boolean>()
        permission?.complete(false)
        permission = answer
        val asked = runCatching { Shizuku.requestPermission(PERMISSION_REQUEST) }.isSuccess
        if (!asked) {
            permission = null
            return false
        }
        return answer.await()
    }

    suspend fun read(): ShellClip? {
        val service = connect() ?: return null
        return onBinderThread { ShellClipboard.clipOf(service.readClipboard(options.userId)) }
    }

    suspend fun watch(): Boolean {
        val service = connect() ?: return false
        watching = onBinderThread { service.watchClipboard(options.userId, clipListener) } == true
        return watching
    }

    suspend fun unwatch() {
        watching = false
        val service = service ?: return
        onBinderThread { service.unwatchClipboard() }
    }

    suspend fun grant(grant: String): Boolean {
        val service = connect() ?: return false
        return onBinderThread {
            service.grant(grant, options.packageName, options.listenerComponent)
        } == true
    }

    /** Injects [input] through the helper, in the order the calls are made. */
    suspend fun inject(input: ShellInput): Boolean {
        val service = connect() ?: return false
        return withContext(inputThread) {
            runCatching {
                when (input) {
                    is ShellInput.Touch -> service.injectTouch(input.action, input.x, input.y)
                    is ShellInput.Scroll -> service.injectScroll(input.x, input.y, input.horizontal, input.vertical)
                    is ShellInput.Key -> service.injectKey(input.keyCode, input.down, input.metaState)
                    is ShellInput.Text -> service.injectText(input.text)
                }
            }.getOrDefault(false)
        }
    }

    suspend fun releaseInput() {
        val service = service ?: return
        withContext(inputThread) { runCatching { service.releaseInput() } }
    }

    private suspend fun connect(): IPowerShellService? {
        service?.let { bound -> if (bound.asBinder().pingBinder()) return bound }
        if (!granted) {
            return null
        }

        val pending = connecting ?: CompletableDeferred<IPowerShellService?>().also { waiting ->
            connecting = waiting
            val bound = runCatching { Shizuku.bindUserService(serviceArgs, connection) }.isSuccess
            if (!bound) {
                connecting = null
                waiting.complete(null)
            }
        }
        return withTimeoutOrNull(CONNECT_TIMEOUT_MS) { pending.await() }
    }

    private suspend fun <T> onBinderThread(call: () -> T): T? = withContext(Dispatchers.IO) {
        runCatching(call).getOrNull()
    }

    private fun onServiceLost() {
        service = null
        if (!watching) {
            return
        }

        watching = false
        onWatchStopped()
    }

    private fun isAppInstalled(): Boolean = try {
        context.packageManager.getPackageInfo(SHIZUKU_PACKAGE, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    companion object {
        const val SHIZUKU_PACKAGE = "moe.shizuku.privileged.api"
        private const val PERMISSION_REQUEST = 0x4645
        private const val SERVICE_VERSION = 3
        private const val CONNECT_TIMEOUT_MS = 10_000L
    }
}
