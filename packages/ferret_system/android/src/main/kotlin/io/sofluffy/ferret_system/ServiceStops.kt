package io.sofluffy.ferret_system

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.os.Build
import android.os.SystemClock
import kotlin.math.abs

/**
 * Counts the times Android stopped the service without being asked, so the
 * app can say "Android stopped Ferret 3 times today" and point to the fix.
 */
object ServiceStops {
    private const val WEEK_MS = 7L * 24 * 60 * 60 * 1000
    private const val MAX_KEPT = 200
    private const val SAME_BOOT_SLACK_MS = 60_000L

    /** Exits that were the user's or the app's own doing, not a battery killer. */
    private val CHOSEN_EXITS = setOf(
        ApplicationExitInfo.REASON_USER_REQUESTED,
        ApplicationExitInfo.REASON_USER_STOPPED,
        ApplicationExitInfo.REASON_PACKAGE_UPDATED,
        ApplicationExitInfo.REASON_PACKAGE_STATE_CHANGE,
        ApplicationExitInfo.REASON_EXIT_SELF,
        ApplicationExitInfo.REASON_CRASH,
        ApplicationExitInfo.REASON_CRASH_NATIVE,
    )

    fun onServiceCreated(context: Context) {
        val prefs = SystemPrefs(context)
        val now = System.currentTimeMillis()
        val bootedAt = now - SystemClock.elapsedRealtime()
        val killed = wasKilled(
            wasRunning = prefs.serviceRunning,
            previousBootAt = prefs.bootStartedAt,
            bootAt = bootedAt,
            exitReason = lastExitReason(context),
        )
        if (killed) {
            prefs.serviceStops = keepRecent(prefs.serviceStops + now, now)
        }

        prefs.bootStartedAt = bootedAt
        prefs.serviceRunning = true
    }

    fun onServiceStopped(context: Context) {
        SystemPrefs(context).serviceRunning = false
    }

    fun recent(context: Context): List<Long> {
        val prefs = SystemPrefs(context)
        return keepRecent(prefs.serviceStops, System.currentTimeMillis())
    }

    /**
     * The service was still marked running when it started again, on the same
     * boot (a reboot isn't a kill), and the last exit wasn't the user's.
     */
    fun wasKilled(wasRunning: Boolean, previousBootAt: Long, bootAt: Long, exitReason: Int?): Boolean {
        if (!wasRunning) {
            return false
        }

        if (abs(bootAt - previousBootAt) > SAME_BOOT_SLACK_MS) {
            return false
        }

        return exitReason == null || exitReason !in CHOSEN_EXITS
    }

    fun keepRecent(stops: List<Long>, now: Long): List<Long> =
        stops.filter { now - it in 0..WEEK_MS }.takeLast(MAX_KEPT)

    private fun lastExitReason(context: Context): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return null
        }

        val activities = context.getSystemService(ActivityManager::class.java) ?: return null
        return try {
            activities.getHistoricalProcessExitReasons(context.packageName, 0, 1).firstOrNull()?.reason
        } catch (error: RuntimeException) {
            null
        }
    }
}
