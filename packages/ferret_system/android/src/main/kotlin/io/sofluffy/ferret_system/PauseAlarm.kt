package io.sofluffy.ferret_system

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Ends a timed pause even if Dart's own timer didn't run, such as when the
 * phone dozed or Android restarted the process meanwhile.
 */
object PauseAlarm {
    fun schedule(context: Context, untilMs: Long?) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = pendingIntent(context)
        alarms.cancel(intent)
        if (untilMs == null) {
            return
        }

        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, untilMs, intent)
    }

    private fun pendingIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, PauseEndReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

class PauseEndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        FerretRuntime.setPauseFromSystem(context, PauseMessage(paused = false))
    }
}
