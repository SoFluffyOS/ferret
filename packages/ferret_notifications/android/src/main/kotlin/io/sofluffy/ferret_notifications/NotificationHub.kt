package io.sofluffy.ferret_notifications

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService.RankingMap
import android.service.notification.StatusBarNotification
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors

/**
 * Connects the listener service, which the system starts on its own, with the
 * plugin instances attached to Flutter engines. Nothing is read while no
 * engine listens.
 */
object NotificationHub {
    interface Sink {
        fun onPosted(notification: PlatformNotification)

        fun onRemoved(key: String)

        fun onListenerChanged(connected: Boolean)
    }

    private val sinks = CopyOnWriteArrayList<Sink>()
    private val reader = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun add(sink: Sink) {
        sinks.addIfAbsent(sink)
    }

    fun remove(sink: Sink) {
        sinks.remove(sink)
    }

    internal fun posted(context: Context, sbn: StatusBarNotification, rankingMap: RankingMap?) {
        if (sinks.isEmpty()) {
            return
        }

        val ranking = NotificationReader.rankingOf(sbn, rankingMap)
        val appContext = context.applicationContext
        reader.execute {
            val notification = runCatching { NotificationReader.read(appContext, sbn, ranking) }
                .getOrNull() ?: return@execute
            main.post { sinks.forEach { it.onPosted(notification) } }
        }
    }

    internal fun removed(key: String) {
        main.post { sinks.forEach { it.onRemoved(key) } }
    }

    internal fun listenerChanged(connected: Boolean) {
        main.post { sinks.forEach { it.onListenerChanged(connected) } }
    }
}
