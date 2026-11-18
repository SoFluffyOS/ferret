package io.sofluffy.ferret_handoff

import android.content.Context
import android.content.Intent
import android.widget.Toast
import kotlinx.coroutines.launch

/**
 * Hands a shared item to Dart when Ferret is running, or queues it and opens
 * Ferret so it goes out once Dart starts.
 */
internal object HandoffDelivery {
    fun deliver(context: Context, item: SharedItem, deviceName: String?) {
        val appContext = context.applicationContext
        val plugin = FerretHandoffPlugin.active
        val events = plugin?.events
        if (plugin == null || events == null) {
            queueAndOpenApp(appContext, item)
            return
        }

        if (deviceName != null) {
            toast(appContext, appContext.getString(R.string.ferret_handoff_sending, deviceName))
        }

        plugin.scope.launch {
            val sent = try {
                events.onShared(item)
            } catch (_: Throwable) {
                null
            }

            when (sent) {
                null -> queueAndOpenApp(appContext, item)
                true -> deviceName?.let {
                    toast(appContext, appContext.getString(R.string.ferret_handoff_sent, it))
                }
                false -> toast(
                    appContext,
                    appContext.getString(
                        R.string.ferret_handoff_not_sent,
                        deviceName ?: appContext.getString(R.string.ferret_handoff_assistant_label),
                    ),
                )
            }
        }
    }

    fun openApp(context: Context) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(launch)
        } catch (_: Exception) {
            return
        }
    }

    private fun queueAndOpenApp(context: Context, item: SharedItem) {
        HandoffStore(context).addPending(item)
        toast(context, context.getString(R.string.ferret_handoff_queued))
        openApp(context)
    }

    private fun toast(context: Context, message: String) {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }
}
