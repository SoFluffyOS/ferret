package io.sofluffy.ferret_notifications

import android.content.ComponentName
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Receives other apps' notifications once the person turns on notification
 * access for the app, and hands them to [NotificationHub].
 *
 * Other plugins that need the same access (such as media sessions) use
 * [componentName] or [CLASS_NAME].
 */
class FerretNotificationListener : NotificationListenerService() {
    companion object {
        const val CLASS_NAME = "io.sofluffy.ferret_notifications.FerretNotificationListener"

        /** The listener as a component of the app that bundles this plugin. */
        fun componentName(context: Context): ComponentName =
            ComponentName(context.packageName, CLASS_NAME)

        /** The listener the system is currently connected to, if any. */
        @Volatile
        var connected: FerretNotificationListener? = null
            private set
    }

    override fun onListenerConnected() {
        connected = this
        NotificationHub.listenerChanged(true)
    }

    override fun onListenerDisconnected() {
        if (connected == this) {
            connected = null
        }
        NotificationHub.listenerChanged(false)
        requestRebind(componentName(this))
    }

    override fun onDestroy() {
        if (connected == this) {
            connected = null
        }
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification, rankingMap: RankingMap?) {
        if (sbn.packageName == packageName) {
            return
        }

        NotificationHub.posted(this, sbn, rankingMap)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification, rankingMap: RankingMap?) {
        if (sbn.packageName == packageName) {
            return
        }

        NotificationHub.removed(sbn.key)
    }

    /** The notification [key] if it is still showing. */
    fun findActive(key: String): StatusBarNotification? =
        runCatching { getActiveNotifications(arrayOf(key)) }
            .getOrNull()
            ?.firstOrNull()
}
