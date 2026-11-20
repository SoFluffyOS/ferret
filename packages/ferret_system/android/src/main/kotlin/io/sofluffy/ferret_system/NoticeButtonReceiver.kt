package io.sofluffy.ferret_system

import android.app.NotificationManager
import android.app.RemoteInput
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * A tap on a notice button that doesn't open the app, such as Don't allow,
 * Stop or Reply, handed to the running Ferret as if the app had been open.
 *
 * The notification plugin sends these taps to its own receiver, which
 * starts a second Flutter engine for a background isolate. That engine
 * would register every plugin again, and Ferret's plugins keep
 * process-wide listeners, so the running app would stop hearing about
 * screen sharing, shared files and more. [FerretComponentFactory] puts this
 * receiver in its place, and the tap goes straight to the running engine.
 *
 * When Ferret isn't running the tap is dropped: what the notice asked about
 * ended with the app.
 */
class NoticeButtonReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TAPPED) {
            return
        }

        val notificationId = intent.getIntExtra(NOTIFICATION_ID, 0)
        val tag = intent.getStringExtra(NOTIFICATION_TAG)
        if (intent.getBooleanExtra(CANCEL_NOTIFICATION, false)) {
            context.getSystemService(NotificationManager::class.java)?.cancel(tag, notificationId)
        }

        val engine = FlutterEngineCache.getInstance().get(FerretRuntime.ENGINE_ID)
        if (engine == null) {
            Log.w(TAG, "Ferret is not running; dropped the tap on ${intent.getStringExtra(ACTION_ID)}")
            return
        }

        val response = mapOf(
            NOTIFICATION_ID to notificationId,
            NOTIFICATION_TAG to tag,
            ACTION_ID to intent.getStringExtra(ACTION_ID),
            PAYLOAD to intent.getStringExtra(PAYLOAD),
            INPUT to RemoteInput.getResultsFromIntent(intent)?.getCharSequence(INPUT_RESULT)?.toString(),
            RESPONSE_TYPE to SELECTED_ACTION,
        )
        MethodChannel(engine.dartExecutor.binaryMessenger, PLUGIN_CHANNEL)
            .invokeMethod("didReceiveNotificationResponse", response)
    }

    /** The notification plugin's names for what a tap carries. */
    companion object {
        const val PLUGIN_RECEIVER = "com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver"
        private const val TAG = "FerretNotices"
        private const val ACTION_TAPPED = "$PLUGIN_RECEIVER.ACTION_TAPPED"
        private const val PLUGIN_CHANNEL = "dexterous.com/flutter/local_notifications"
        private const val NOTIFICATION_ID = "notificationId"
        private const val NOTIFICATION_TAG = "notificationTag"
        private const val CANCEL_NOTIFICATION = "cancelNotification"
        private const val ACTION_ID = "actionId"
        private const val PAYLOAD = "payload"
        private const val INPUT = "input"
        private const val INPUT_RESULT = "FlutterLocalNotificationsPluginInputResult"
        private const val RESPONSE_TYPE = "notificationResponseType"
        private const val SELECTED_ACTION = 1
    }
}
