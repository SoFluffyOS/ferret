package io.sofluffy.ferret_media

import android.content.Context
import android.content.pm.PackageManager

/** Human names for media apps. */
internal object AppNames {
    private val cache = mutableMapOf<String, String>()

    private val knownNames = mapOf(
        "com.spotify.music" to "Spotify",
        "com.google.android.youtube" to "YouTube",
        "com.google.android.apps.youtube.music" to "YouTube Music",
        "com.android.chrome" to "Chrome",
        "org.mozilla.firefox" to "Firefox",
        "com.apple.android.music" to "Apple Music",
        "deezer.android.app" to "Deezer",
        "com.soundcloud.android" to "SoundCloud",
        "com.netflix.mediaclient" to "Netflix",
        "au.com.shiftyjelly.pocketcasts" to "Pocket Casts",
    )

    fun known(packageName: String): String? = knownNames[packageName]

    fun label(context: Context, packageName: String): String = cache.getOrPut(packageName) {
        try {
            val manager = context.packageManager
            val info = manager.getApplicationInfo(packageName, 0)
            manager.getApplicationLabel(info).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            known(packageName) ?: packageName
        }
    }
}
