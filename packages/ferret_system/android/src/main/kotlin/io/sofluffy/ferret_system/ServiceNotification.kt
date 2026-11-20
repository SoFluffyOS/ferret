package io.sofluffy.ferret_system

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.text.format.DateFormat
import java.util.Date

/** The quiet notification Android requires while the service runs. */
object ServiceNotification {
    const val CHANNEL_ID = "ferret.service"
    const val ID = 47640

    private const val REQUEST_OPEN = 1
    private const val REQUEST_CLIPBOARD = 2
    private const val REQUEST_PAUSE = 3
    private const val REQUEST_RESUME = 4
    private const val REQUEST_HIDDEN = 5

    /**
     * True once the user swiped the notice away (Android 14+ lets them).
     * Ferret then leaves it hidden instead of posting it again at every
     * connect, until the service starts afresh.
     */
    @Volatile
    var hidden = false

    /** Whether to post the notice now: never again over a swipe, once running. */
    fun shouldPost(inForeground: Boolean): Boolean = !(inForeground && hidden)

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.ferret_system_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.ferret_system_channel_description)
            setShowBadge(false)
            setSound(null, null)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    fun build(context: Context): Notification {
        ensureChannel(context)

        val pause = FerretRuntime.pauseState(context)
        val devices = FerretRuntime.connectedDevices
        val (title, text) = texts(context, pause, devices)
        val builder = builder(context)
            .setSmallIcon(R.drawable.ferret_system_status)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PUBLIC)

        openAppIntent(context)?.let(builder::setContentIntent)
        builder.setDeleteIntent(
            PendingIntent.getBroadcast(
                context,
                REQUEST_HIDDEN,
                Intent(context, NoticeHiddenReceiver::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }

        if (pause.paused) {
            builder.addAction(action(context, R.string.ferret_system_action_resume, serviceIntent(context, FerretService.ACTION_RESUME, REQUEST_RESUME)))
            return builder.build()
        }

        builder
            .addAction(action(context, R.string.ferret_system_action_send_clipboard, ClipboardActivity.pendingIntent(context, REQUEST_CLIPBOARD, "notification")))
            .addAction(action(context, R.string.ferret_system_action_pause, serviceIntent(context, FerretService.ACTION_PAUSE, REQUEST_PAUSE)))
        return builder.build()
    }

    private fun texts(context: Context, pause: PauseMessage, devices: List<String>): Pair<String, String> {
        if (pause.paused) {
            val until = pause.untilMs
            val text = when (until) {
                null -> context.getString(R.string.ferret_system_paused_until_resumed)
                else -> context.getString(
                    R.string.ferret_system_paused_until,
                    DateFormat.getTimeFormat(context).format(Date(until)),
                )
            }
            return context.getString(R.string.ferret_system_paused_title) to text
        }

        val first = devices.firstOrNull()
            ?: return context.getString(R.string.ferret_system_waiting_title) to
                context.getString(R.string.ferret_system_waiting_text)

        val others = devices.size - 1
        val title = when (others) {
            0 -> context.getString(R.string.ferret_system_connected_one, first)
            else -> context.resources.getQuantityString(R.plurals.ferret_system_connected_many, others, first, others)
        }
        return title to context.getString(R.string.ferret_system_connected_text)
    }

    @Suppress("DEPRECATION")
    private fun builder(context: Context): Notification.Builder {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return Notification.Builder(context, CHANNEL_ID)
        }

        return Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
    }

    private fun action(context: Context, title: Int, intent: PendingIntent): Notification.Action =
        Notification.Action.Builder(
            Icon.createWithResource(context, R.drawable.ferret_system_status),
            context.getString(title),
            intent,
        ).build()

    private fun serviceIntent(context: Context, action: String, requestCode: Int): PendingIntent =
        PendingIntent.getService(
            context,
            requestCode,
            Intent(context, FerretService::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    fun openAppIntent(context: Context, requestCode: Int = REQUEST_OPEN): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
        return PendingIntent.getActivity(
            context,
            requestCode,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
