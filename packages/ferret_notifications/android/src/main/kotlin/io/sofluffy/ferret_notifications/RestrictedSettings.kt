package io.sofluffy.ferret_notifications

/**
 * Best-effort guess whether Android 13+ "restricted settings" blocks the
 * notification access toggle. Android greys it out for apps installed from a
 * file or by some app stores until the person allows it in App info.
 */
internal object RestrictedSettings {
    const val OP_NAME = "android:access_restricted_settings"

    private const val TIRAMISU = 33
    private const val MODE_ALLOWED = 0
    private const val MODE_IGNORED = 1
    private const val MODE_ERRORED = 2
    private const val SOURCE_STORE = 2
    private const val SOURCE_DOWNLOADED_FILE = 3
    private const val SOURCE_LOCAL_FILE = 4

    /**
     * [opMode] is the app op mode of [OP_NAME] and [packageSource] the
     * `PackageInstaller.PACKAGE_SOURCE_*` of this app; either is null when it
     * could not be read.
     */
    fun isLikelyRestricted(sdk: Int, accessGranted: Boolean, opMode: Int?, packageSource: Int?): Boolean {
        if (sdk < TIRAMISU || accessGranted || opMode == MODE_ALLOWED) {
            return false
        }

        val opDenies = opMode == MODE_IGNORED || opMode == MODE_ERRORED
        return when (packageSource) {
            SOURCE_DOWNLOADED_FILE, SOURCE_LOCAL_FILE -> true
            SOURCE_STORE -> false
            else -> opDenies
        }
    }
}
