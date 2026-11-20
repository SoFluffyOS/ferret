package io.sofluffy.ferret_system

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/**
 * Android 17's local network permission. It only applies to apps that
 * target Android 17: older targets keep the network through INTERNET.
 */
internal object LocalNetwork {
    const val PERMISSION = "android.permission.ACCESS_LOCAL_NETWORK"

    /** Android 17 is API level 37. */
    private const val ANDROID_17 = 37

    private const val PREFS = "ferret_local_network"
    private const val TURNED_DOWN = "turned_down"

    /** Whether Android asks this app about the local network at all. */
    fun isAsked(context: Context): Boolean =
        Build.VERSION.SDK_INT >= ANDROID_17 &&
            context.applicationInfo.targetSdkVersion >= ANDROID_17

    /**
     * Turned down with "Don't ask again" (or twice): Android shows no
     * question any more. Forgotten once it is granted, such as in Settings.
     */
    fun wasTurnedDown(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (context.checkSelfPermission(PERMISSION) == PackageManager.PERMISSION_GRANTED) {
            prefs.edit().remove(TURNED_DOWN).apply()
            return false
        }

        return prefs.getBoolean(TURNED_DOWN, false)
    }

    fun rememberTurnedDown(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(TURNED_DOWN, true)
            .apply()
    }
}
