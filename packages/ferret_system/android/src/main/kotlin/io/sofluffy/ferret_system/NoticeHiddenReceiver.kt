package io.sofluffy.ferret_system

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** The user swiped the "Connected to…" notice away. */
class NoticeHiddenReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ServiceNotification.hidden = true
    }
}
