package io.sofluffy.ferret_power.shell

import android.os.Bundle
import kotlin.system.exitProcess

/**
 * Ferret's helper inside Shizuku: a user service that Shizuku starts in its
 * own process as the shell user, and that only Ferret can reach. It dies with
 * the app.
 */
class PowerShellService : IPowerShellService.Stub() {
    private val clipboard = ShellClipboard()

    override fun destroy() {
        clipboard.unwatch()
        exitProcess(0)
    }

    override fun readClipboard(userId: Int): Bundle? =
        clipboard.read(userId)?.let(ShellClipboard::bundleOf)

    override fun watchClipboard(userId: Int, listener: IPowerClipListener?): Boolean {
        if (listener == null) {
            return false
        }

        return clipboard.watch(userId) {
            val clip = clipboard.read(userId) ?: return@watch
            listener.onClipChanged(ShellClipboard.bundleOf(clip))
        }
    }

    override fun unwatchClipboard() = clipboard.unwatch()

    override fun grant(grant: String?, packageName: String?, listenerComponent: String?): Boolean =
        ShellGrants.run(grant.orEmpty(), packageName.orEmpty(), listenerComponent.orEmpty())
}
