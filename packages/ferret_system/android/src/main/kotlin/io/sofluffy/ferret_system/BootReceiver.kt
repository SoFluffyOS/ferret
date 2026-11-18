package io.sofluffy.ferret_system

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Starts Ferret after a reboot or an app update, only if the user asked for it. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in STARTING_ACTIONS) {
            return
        }

        val prefs = SystemPrefs(context)
        if (!prefs.startOnBoot || !prefs.serviceEnabled) {
            return
        }

        FerretService.start(context)
    }

    private companion object {
        val STARTING_ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
        )
    }
}
