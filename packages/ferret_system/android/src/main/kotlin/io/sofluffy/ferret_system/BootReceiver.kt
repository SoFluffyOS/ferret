package io.sofluffy.ferret_system

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Brings Ferret back after an app update, and after a reboot when the user
 * keeps "Start when the phone starts" on.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = SystemPrefs(context)
        if (!shouldStart(intent.action, prefs.serviceEnabled, prefs.startOnBoot)) {
            return
        }

        FerretService.start(context)
    }

    companion object {
        /** Some makers send their own action after a fast boot, and no BOOT_COMPLETED. */
        private val BOOT_ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
        )

        /**
         * An update stops a running Ferret, so it starts again whenever the
         * service is on. Starting with the phone is the user's choice.
         */
        fun shouldStart(action: String?, serviceEnabled: Boolean, startOnBoot: Boolean): Boolean {
            if (!serviceEnabled) {
                return false
            }

            if (action == Intent.ACTION_MY_PACKAGE_REPLACED) {
                return true
            }

            return action in BOOT_ACTIONS && startOnBoot
        }
    }
}
