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
    private val injector = ShellInjector()

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
            val clip = clipboard.readChange(userId) ?: return@watch
            listener.onClipChanged(ShellClipboard.bundleOf(clip))
        }
    }

    override fun unwatchClipboard() = clipboard.unwatch()

    override fun injectTouch(action: Int, x: Float, y: Float): Boolean =
        injector.run(ShellInput.Touch(action, x, y))

    override fun injectScroll(x: Float, y: Float, horizontal: Float, vertical: Float): Boolean =
        injector.run(ShellInput.Scroll(x, y, horizontal, vertical))

    override fun injectKey(keyCode: Int, down: Boolean, metaState: Int): Boolean =
        injector.run(ShellInput.Key(keyCode, down, metaState))

    override fun injectText(text: String?): Boolean = injector.run(ShellInput.Text(text.orEmpty()))

    override fun releaseInput() = injector.release()

    override fun grant(grant: String?, packageName: String?, listenerComponent: String?): Boolean =
        ShellGrants.run(grant.orEmpty(), packageName.orEmpty(), listenerComponent.orEmpty())
}
