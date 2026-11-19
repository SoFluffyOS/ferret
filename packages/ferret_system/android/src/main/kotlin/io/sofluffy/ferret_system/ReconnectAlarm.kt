package io.sofluffy.ferret_system

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock

/**
 * Looks for the user's devices again now and then while none is connected.
 * Ferret stops redialling a few minutes after a device goes away; with the
 * screen off nothing else would start it again. The alarm is inexact and
 * doesn't wake the phone, so in Doze it runs in Android's maintenance
 * windows and costs no wake-up of its own.
 */
object ReconnectAlarm {
    const val INTERVAL_MS = 15L * 60 * 1000

    /** Only while the service runs, Ferret isn't paused and nobody is connected. */
    fun isNeeded(serviceRunning: Boolean, paused: Boolean, connectedDevices: Int): Boolean =
        serviceRunning && !paused && connectedDevices == 0

    fun update(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = pendingIntent(context)
        alarms.cancel(intent)

        val needed = isNeeded(
            serviceRunning = FerretService.isRunning,
            paused = FerretRuntime.pauseState(context).paused,
            connectedDevices = FerretRuntime.connectedDevices.size,
        )
        if (!needed) {
            return
        }

        alarms.set(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + INTERVAL_MS, intent)
    }

    private fun pendingIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, ReconnectReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

class ReconnectReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        FerretRuntime.reconnectDue()
        ReconnectAlarm.update(context)
    }
}
