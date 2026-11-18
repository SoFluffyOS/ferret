package io.sofluffy.ferret_find

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** "Found it" on the ringing notification, or the notification swiped away. */
class FindActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            FindAlarm.ACTION_FOUND, FindAlarm.ACTION_DISMISSED -> FindAlarm.stop(FindAlarm.REASON_FOUND)
        }
    }
}
