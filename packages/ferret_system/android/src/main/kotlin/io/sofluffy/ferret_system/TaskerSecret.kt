package io.sofluffy.ferret_system

import android.content.Context
import android.util.Base64
import java.security.SecureRandom

/** A random secret made once per install, put in every Tasker bundle. */
object TaskerSecret {
    private const val PREFS = "ferret_tasker"
    private const val KEY = "secret"

    fun get(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.getString(KEY, null)?.let { return it }

        val bytes = ByteArray(24).also { SecureRandom().nextBytes(it) }
        val secret = Base64.encodeToString(bytes, Base64.NO_WRAP or Base64.URL_SAFE)
        prefs.edit().putString(KEY, secret).apply()
        return secret
    }
}
