package io.sofluffy.ferret_messages

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Telephony

/**
 * Tells [onChanged] when messages change: the providers' observer for every
 * write, the incoming SMS broadcast because the default app writes new texts a
 * moment after they arrive, and delivery reports. Bursts merge into one call.
 */
class ChangeWatcher(private val context: Context, private val onChanged: () -> Unit) {
    private val handler = Handler(Looper.getMainLooper())
    private val notify = Runnable { onChanged() }
    private val lateNotify = Runnable { onChanged() }
    private var watching = false

    private val observer = object : ContentObserver(handler) {
        override fun onChange(selfChange: Boolean) = schedule(DEBOUNCE_MS)

        override fun onChange(selfChange: Boolean, uri: Uri?) = schedule(DEBOUNCE_MS)
    }

    private val incoming = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            schedule(DEBOUNCE_MS)
            handler.removeCallbacks(lateNotify)
            handler.postDelayed(lateNotify, LATE_WRITE_MS)
        }
    }

    private val delivered = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = schedule(DEBOUNCE_MS)
    }

    fun start() {
        if (watching) {
            return
        }

        watching = true
        context.contentResolver.registerContentObserver(MMS_SMS_URI, true, observer)
        val incomingFilter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
        val deliveredFilter = IntentFilter(SmsSender.DELIVERED_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Only the system holds BROADCAST_SMS, so the exported receiver hears no one else.
            context.registerReceiver(incoming, incomingFilter, BROADCAST_SMS, null, Context.RECEIVER_EXPORTED)
            context.registerReceiver(delivered, deliveredFilter, Context.RECEIVER_NOT_EXPORTED)
            return
        }

        context.registerReceiver(incoming, incomingFilter, BROADCAST_SMS, null)
        context.registerReceiver(delivered, deliveredFilter)
    }

    fun stop() {
        if (!watching) {
            return
        }

        watching = false
        handler.removeCallbacks(notify)
        handler.removeCallbacks(lateNotify)
        context.contentResolver.unregisterContentObserver(observer)
        runCatching { context.unregisterReceiver(incoming) }
        runCatching { context.unregisterReceiver(delivered) }
    }

    private fun schedule(delayMs: Long) {
        handler.removeCallbacks(notify)
        handler.postDelayed(notify, delayMs)
    }

    private companion object {
        val MMS_SMS_URI: Uri = Uri.parse("content://mms-sms/")
        const val BROADCAST_SMS = "android.permission.BROADCAST_SMS"
        const val DEBOUNCE_MS = 600L
        const val LATE_WRITE_MS = 3_000L
    }
}
