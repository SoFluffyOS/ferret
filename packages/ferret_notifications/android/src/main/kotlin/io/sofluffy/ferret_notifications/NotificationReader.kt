package io.sofluffy.ferret_notifications

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.service.notification.NotificationListenerService.Ranking
import android.service.notification.NotificationListenerService.RankingMap
import android.service.notification.StatusBarNotification

/** Turns a [StatusBarNotification] into what Dart sees. */
internal object NotificationReader {
    private const val UNKNOWN_IMPORTANCE = -1000

    data class RankingInfo(val importance: Int, val isConversation: Boolean)

    fun rankingOf(sbn: StatusBarNotification, rankingMap: RankingMap?): RankingInfo {
        val ranking = Ranking()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            rankingMap?.getRanking(sbn.key, ranking) == true
        ) {
            val isConversation = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && ranking.isConversation
            return RankingInfo(ranking.importance, isConversation)
        }

        return RankingInfo(legacyImportance(sbn.notification), false)
    }

    fun read(context: Context, sbn: StatusBarNotification, ranking: RankingInfo): PlatformNotification {
        val notification = sbn.notification
        val extras = notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)
            ?: extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)
        val text = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT)
        val isConversation = ranking.isConversation ||
            notification.category == Notification.CATEGORY_MESSAGE ||
            extras.containsKey(Notification.EXTRA_MESSAGES)

        return PlatformNotification(
            key = sbn.key,
            packageName = sbn.packageName,
            appName = appName(context.packageManager, sbn.packageName),
            title = title?.toString().orEmpty(),
            text = text?.toString().orEmpty(),
            postedAtMs = sbn.postTime,
            appIcon = AppIcons.notificationIcon(context, sbn.packageName),
            isConversation = isConversation,
            isOngoing = sbn.isOngoing,
            isForegroundService = notification.flags and Notification.FLAG_FOREGROUND_SERVICE != 0,
            isGroupSummary = notification.flags and Notification.FLAG_GROUP_SUMMARY != 0,
            isMedia = extras.containsKey(Notification.EXTRA_MEDIA_SESSION) ||
                notification.category == Notification.CATEGORY_TRANSPORT,
            importance = ranking.importance.toLong(),
            actions = actionsOf(notification),
        )
    }

    fun appName(packageManager: PackageManager, packageName: String): String =
        runCatching {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(packageName, 0)).toString()
        }.getOrDefault(packageName)

    private fun actionsOf(notification: Notification): List<PlatformNotificationAction> =
        notification.actions.orEmpty().mapIndexedNotNull { index, action ->
            if (action.actionIntent == null) {
                return@mapIndexedNotNull null
            }

            PlatformNotificationAction(
                id = index.toString(),
                title = action.title?.toString().orEmpty(),
                isReply = action.remoteInputs.orEmpty().any { it.allowFreeFormInput },
            )
        }

    @Suppress("DEPRECATION")
    private fun legacyImportance(notification: Notification): Int = when {
        notification.priority <= Notification.PRIORITY_MIN -> NotificationManager.IMPORTANCE_MIN
        notification.priority == Notification.PRIORITY_LOW -> NotificationManager.IMPORTANCE_LOW
        notification.priority == Notification.PRIORITY_DEFAULT -> NotificationManager.IMPORTANCE_DEFAULT
        notification.priority >= Notification.PRIORITY_HIGH -> NotificationManager.IMPORTANCE_HIGH
        else -> UNKNOWN_IMPORTANCE
    }
}
