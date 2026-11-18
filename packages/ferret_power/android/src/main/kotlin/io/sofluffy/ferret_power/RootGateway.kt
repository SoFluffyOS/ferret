package io.sofluffy.ferret_power

import android.content.Context
import android.content.pm.PackageManager
import io.sofluffy.ferret_power.shell.ShellClip
import io.sofluffy.ferret_power.shell.ShellLines
import io.sofluffy.ferret_power.shell.ShellOptions
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Root on this phone: finding it, asking for it, and running Ferret's helper
 * through `su`. Finding never runs `su`; only [request] and the capabilities
 * do, and Dart calls those only after the user turned root on. Every call
 * that runs `su` blocks, so call them off the main thread.
 */
internal class RootGateway(
    private val context: Context,
    private val options: ShellOptions,
    private val onClip: (ShellClip) -> Unit,
    private val onWatchStopped: () -> Unit,
) {
    private var session: RootSession? = null
    private var watching = false

    /** `su` answered as root since the app started. */
    @Volatile
    var granted = false
        private set

    val manager: PlatformRootManager
        get() {
            for ((packageName, manager) in MANAGERS) {
                if (isInstalled(packageName)) {
                    return manager
                }
            }
            return if (suPath() != null) PlatformRootManager.UNKNOWN else PlatformRootManager.NONE
        }

    /** KernelSU and APatch hide `su` from apps they haven't allowed yet, so their manager app counts too. */
    val found: Boolean
        get() = manager != PlatformRootManager.NONE

    /** Runs `su -c id`, which makes the root manager ask the user the first time. */
    fun request(): Boolean {
        granted = runCatching { askForRoot() }.getOrDefault(false)
        return granted
    }

    @Synchronized
    fun read(): ShellClip? {
        val session = open() ?: return null
        val reply = session.request(ShellLines.READ)
        closeUnlessWatching()
        return reply?.let { ShellLines.parseClip(ShellLines.CLIP, it) }
    }

    @Synchronized
    fun watch(): Boolean {
        val session = open() ?: return false
        watching = session.request(ShellLines.WATCH) == ShellLines.OK
        closeUnlessWatching()
        return watching
    }

    @Synchronized
    fun unwatch() {
        watching = false
        closeUnlessWatching()
    }

    @Synchronized
    fun grant(grant: String): Boolean {
        val session = open() ?: return false
        val reply = session.request("${ShellLines.GRANT} $grant")
        closeUnlessWatching()
        return reply == ShellLines.OK
    }

    private fun open(): RootSession? {
        session?.let { open -> if (open.isOpen) return open }

        val command = RootCommand.helper(context.applicationInfo.sourceDir, options)
        for (launcher in RootCommand.launchers(command)) {
            val started = runCatching {
                RootSession(ProcessBuilder(launcher).start(), onClip, ::onSessionClosed)
            }.getOrNull() ?: continue
            if (started.awaitReady()) {
                session = started
                return started
            }
            started.close()
        }

        granted = false
        return null
    }

    private fun closeUnlessWatching() {
        if (watching) {
            return
        }

        val closing = session ?: return
        session = null
        closing.close()
    }

    private fun onSessionClosed(closed: RootSession) {
        val stoppedWatch = synchronized(this) {
            if (session !== closed) {
                return
            }
            session = null
            val wasWatching = watching
            watching = false
            wasWatching
        }
        if (stoppedWatch) {
            onWatchStopped()
        }
    }

    private fun askForRoot(): Boolean {
        val process = ProcessBuilder("su", "-c", "id -u").redirectErrorStream(true).start()
        process.outputStream.close()
        val reader = Executors.newSingleThreadExecutor()
        try {
            val output = reader.submit<String> { process.inputStream.bufferedReader().readText() }
            return output.get(PROMPT_TIMEOUT_SECONDS, TimeUnit.SECONDS).trim() == "0"
        } finally {
            process.destroy()
            reader.shutdownNow()
        }
    }

    private fun suPath(): String? {
        val folders = System.getenv("PATH").orEmpty().split(':') + SU_FOLDERS
        return folders.filter { it.isNotEmpty() }
            .map { File(it, "su") }
            .firstOrNull { runCatching { it.exists() }.getOrDefault(false) }
            ?.path
    }

    private fun isInstalled(packageName: String): Boolean = try {
        context.packageManager.getPackageInfo(packageName, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private companion object {
        /** Long enough to read and answer the root manager's prompt. */
        const val PROMPT_TIMEOUT_SECONDS = 60L

        val MANAGERS = listOf(
            "com.topjohnwu.magisk" to PlatformRootManager.MAGISK,
            "me.weishu.kernelsu" to PlatformRootManager.KERNEL_SU,
            "me.bmax.apatch" to PlatformRootManager.A_PATCH,
        )

        val SU_FOLDERS = listOf("/system/bin", "/system/xbin", "/sbin", "/debug_ramdisk", "/product/bin")
    }
}
