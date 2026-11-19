package io.sofluffy.ferret_system

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Runs a Ferret action Tasker fires (the Locale plugin API's
 * `FIRE_SETTING`). Starts Ferret if it isn't running, and hands the
 * request to Dart, which answers it like `ferret-cli` would.
 */
class TaskerFireReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TaskerEditActivity.ACTION_FIRE_SETTING) {
            return
        }

        val bundle = intent.getBundleExtra(TaskerEditActivity.EXTRA_BUNDLE) ?: return
        val values = bundle.keySet().associateWith { key -> bundle.getString(key) }
        val action = TaskerRequest.toAction(values, TaskerSecret.get(context))
        if (action == null) {
            Log.w(TAG, "Ignored a Tasker request that wasn't made in Ferret")
            return
        }

        FerretRuntime.wake(context)
        FerretRuntime.dispatch(action)
    }

    private companion object {
        const val TAG = "FerretTasker"
    }
}
