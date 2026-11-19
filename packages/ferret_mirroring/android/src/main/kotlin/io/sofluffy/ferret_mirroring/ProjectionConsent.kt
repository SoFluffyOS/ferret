package io.sofluffy.ferret_mirroring

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.lang.ref.WeakReference

/**
 * One question at a time: "may this screen be captured?". Android's own
 * prompt answers it, every time; nothing about the answer is kept after the
 * capture it allowed.
 */
internal object ProjectionConsent {
    private const val TAG = "FerretMirroring"
    private const val ASK_CHANNEL = "ferret_mirroring_ask"
    private const val ASK_NOTICE_ID = 7402

    private val main = Handler(Looper.getMainLooper())
    private var callback: ((NativeConsentResult) -> Unit)? = null
    private var timeout: Runnable? = null
    private var activity = WeakReference<ProjectionConsentActivity>(null)

    /** The words for the ongoing notice of the request being answered. */
    var texts: NativeConsentTexts? = null
        private set

    val isPending: Boolean
        get() = callback != null

    fun request(
        context: Context,
        texts: NativeConsentTexts,
        timeoutSeconds: Long,
        onResult: (NativeConsentResult) -> Unit,
    ) {
        complete(context, NativeConsentResult.TIMED_OUT)
        callback = onResult
        this.texts = texts
        val expire = Runnable { complete(context, NativeConsentResult.TIMED_OUT) }
        timeout = expire
        main.postDelayed(expire, timeoutSeconds * 1000)

        if (isInForeground() && openPrompt(context)) {
            return
        }

        if (!postNotice(context, texts)) {
            complete(context, NativeConsentResult.CANNOT_ASK)
        }
    }

    fun attach(prompt: ProjectionConsentActivity) {
        activity = WeakReference(prompt)
    }

    /** Answers the pending request, closing the prompt and the notice. */
    fun complete(context: Context, result: NativeConsentResult) {
        val pending = callback ?: return
        callback = null
        timeout?.let(main::removeCallbacks)
        timeout = null
        context.getSystemService(NotificationManager::class.java)?.cancel(ASK_NOTICE_ID)
        if (result != NativeConsentResult.GRANTED) {
            texts = null
        }

        activity.get()?.close()
        activity = WeakReference(null)
        pending(result)
    }

    /** Whether an activity of this app is in front, so another may be started. */
    private fun isInForeground(): Boolean {
        val state = ActivityManager.RunningAppProcessInfo()
        ActivityManager.getMyMemoryState(state)
        return state.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
    }

    private fun openPrompt(context: Context): Boolean {
        try {
            context.startActivity(ProjectionConsentActivity.intent(context))
            return true
        } catch (error: RuntimeException) {
            Log.w(TAG, "Could not open the screen capture prompt directly", error)
            return false
        }
    }

    /** From the background only a tap on a notice may open the prompt. */
    private fun postNotice(context: Context, texts: NativeConsentTexts): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return false
        if (!manager.areNotificationsEnabled()) {
            return false
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(ASK_CHANNEL, texts.askChannelName, NotificationManager.IMPORTANCE_HIGH),
            )
        }

        val open = PendingIntent.getActivity(
            context,
            ASK_NOTICE_ID,
            ProjectionConsentActivity.intent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notice = MirrorNotices.builder(context, ASK_CHANNEL)
            .setSmallIcon(R.drawable.ferret_mirroring_status)
            .setContentTitle(texts.askTitle)
            .setContentText(texts.askBody)
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        manager.notify(ASK_NOTICE_ID, notice)
        return true
    }
}
