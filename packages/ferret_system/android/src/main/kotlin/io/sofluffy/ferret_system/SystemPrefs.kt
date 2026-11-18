package io.sofluffy.ferret_system

import android.content.Context
import android.content.SharedPreferences

/**
 * What the service, the boot receiver and the tile need before Dart runs.
 * Dart's own settings live in a file these can't read, so the parts that
 * matter here are mirrored into SharedPreferences.
 */
class SystemPrefs(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(NAME, Context.MODE_PRIVATE)

    var serviceEnabled: Boolean
        get() = prefs.getBoolean(SERVICE_ENABLED, false)
        set(value) = prefs.edit().putBoolean(SERVICE_ENABLED, value).apply()

    var startOnBoot: Boolean
        get() = prefs.getBoolean(START_ON_BOOT, false)
        set(value) = prefs.edit().putBoolean(START_ON_BOOT, value).apply()

    val paused: Boolean
        get() = prefs.getBoolean(PAUSED, false)

    val pausedUntil: Long?
        get() = prefs.getLong(PAUSED_UNTIL, NONE).takeIf { it != NONE }

    fun setPause(paused: Boolean, untilMs: Long?) {
        prefs.edit()
            .putBoolean(PAUSED, paused)
            .putLong(PAUSED_UNTIL, untilMs ?: NONE)
            .apply()
    }

    /** Set while the service runs; still set at the next start means it was killed. */
    var serviceRunning: Boolean
        get() = prefs.getBoolean(SERVICE_RUNNING, false)
        set(value) {
            // Written synchronously: the process may be killed right after.
            prefs.edit().putBoolean(SERVICE_RUNNING, value).commit()
        }

    var bootStartedAt: Long
        get() = prefs.getLong(BOOT_STARTED_AT, NONE)
        set(value) = prefs.edit().putLong(BOOT_STARTED_AT, value).apply()

    var serviceStops: List<Long>
        get() = prefs.getString(SERVICE_STOPS, "")
            .orEmpty()
            .split(',')
            .mapNotNull { it.toLongOrNull() }
        set(value) = prefs.edit().putString(SERVICE_STOPS, value.joinToString(",")).apply()

    private companion object {
        const val NAME = "ferret_system"
        const val NONE = -1L
        const val SERVICE_ENABLED = "service_enabled"
        const val START_ON_BOOT = "start_on_boot"
        const val PAUSED = "paused"
        const val PAUSED_UNTIL = "paused_until"
        const val SERVICE_RUNNING = "service_running"
        const val BOOT_STARTED_AT = "boot_started_at"
        const val SERVICE_STOPS = "service_stops"
    }
}
