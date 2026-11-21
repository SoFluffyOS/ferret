package io.sofluffy.ferret_drop

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log

/**
 * Keeps the permission to read a shared or picked URI for as long as the
 * send needs it.
 *
 * The grant a share intent carries belongs to the activity that received
 * it and ends when that activity finishes, which [ShareReceiverActivity]
 * does at once; a picker's grant ends with Ferret's activity. The send runs
 * later, in the foreground service, so Ferret grants the URI to itself: a
 * grant with no activity behind it lasts until [release] (or a reboot).
 */
internal object SharePermissions {
    private const val TAG = "FerretDrop"
    private const val READ = Intent.FLAG_GRANT_READ_URI_PERMISSION

    /** Whether [uri] stays readable after the activity that got it is gone. */
    fun keep(context: Context, uri: Uri): Boolean {
        if (uri.scheme != "content") {
            return false
        }

        return try {
            context.grantUriPermission(context.packageName, uri, READ)
            true
        } catch (error: SecurityException) {
            Log.w(TAG, "Could not keep the permission to read a shared file", error)
            false
        } catch (error: IllegalArgumentException) {
            false
        }
    }

    /** Lets go of the grant [keep] made. */
    fun release(context: Context, uri: Uri) {
        try {
            context.revokeUriPermission(uri, READ)
        } catch (error: SecurityException) {
            Log.w(TAG, "Could not release a shared file", error)
        } catch (error: IllegalArgumentException) {
            return
        }
    }
}
