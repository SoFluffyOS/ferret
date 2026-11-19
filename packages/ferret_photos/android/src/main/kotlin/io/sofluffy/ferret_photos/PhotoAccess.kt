package io.sofluffy.ferret_photos

import android.Manifest
import android.os.Build

/** What the system lets Ferret read, named as Dart's PhotoLibraryAccess. */
enum class PhotoAccess(val wireName: String) {
    FULL("full"),
    LIMITED("limited"),
    DENIED("denied"),
    NOT_ASKED("notAsked");

    val canRead: Boolean
        get() = this == FULL || this == LIMITED

    companion object {
        private const val IMAGES = "android.permission.READ_MEDIA_IMAGES"
        private const val VIDEO = "android.permission.READ_MEDIA_VIDEO"
        private const val SELECTED = "android.permission.READ_MEDIA_VISUAL_USER_SELECTED"
        private const val STORAGE = Manifest.permission.READ_EXTERNAL_STORAGE

        /** What to ask for on this Android. On 14 and later, asking again
         * while only some photos are allowed lets the person pick more. */
        fun permissionsToAsk(sdk: Int = Build.VERSION.SDK_INT): Array<String> = when {
            sdk >= 34 -> arrayOf(IMAGES, VIDEO, SELECTED)
            sdk >= 33 -> arrayOf(IMAGES, VIDEO)
            else -> arrayOf(STORAGE)
        }

        /** Reads [granted] permissions as an access level. Android 14 grants
         * only READ_MEDIA_VISUAL_USER_SELECTED for "Selected photos". */
        fun from(sdk: Int, granted: Set<String>, asked: Boolean): PhotoAccess = when {
            sdk >= 33 && IMAGES in granted -> FULL
            sdk >= 34 && SELECTED in granted -> LIMITED
            sdk < 33 && STORAGE in granted -> FULL
            asked -> DENIED
            else -> NOT_ASKED
        }
    }
}
