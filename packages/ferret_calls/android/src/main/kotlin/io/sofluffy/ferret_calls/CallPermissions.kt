package io.sofluffy.ferret_calls

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/** The runtime permissions calls need, and whether the app holds them. */
internal object CallPermissions {
    private const val PREFERENCES = "ferret_calls"
    private const val ASKED_KEY = "asked_permissions"

    fun isGranted(context: Context, permission: String): Boolean =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    fun canAnswer(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            isGranted(context, Manifest.permission.ANSWER_PHONE_CALLS)

    /** Every permission of the feature this Android version knows. */
    fun all(): List<String> = buildList {
        add(Manifest.permission.READ_PHONE_STATE)
        add(Manifest.permission.READ_CALL_LOG)
        add(Manifest.permission.READ_CONTACTS)
        add(Manifest.permission.CALL_PHONE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            add(Manifest.permission.ANSWER_PHONE_CALLS)
        }
    }

    fun missing(context: Context): List<String> = all().filterNot { isGranted(context, it) }

    fun markAsked(context: Context) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(ASKED_KEY, true)
            .apply()
    }

    fun read(context: Context, activity: Activity?): PlatformCallPermissions =
        PlatformCallPermissions(
            phoneState = isGranted(context, Manifest.permission.READ_PHONE_STATE),
            callLog = isGranted(context, Manifest.permission.READ_CALL_LOG),
            contacts = isGranted(context, Manifest.permission.READ_CONTACTS),
            answerCalls = canAnswer(context),
            placeCalls = isGranted(context, Manifest.permission.CALL_PHONE),
            canAskAgain = canAskAgain(context, activity),
        )

    /**
     * Android never says "denied for good" directly: after a request, a
     * missing permission with no rationale to show is one it won't ask for
     * again. Before the first request there is no rationale either, so the
     * first request is remembered.
     */
    private fun canAskAgain(context: Context, activity: Activity?): Boolean {
        val asked = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(ASKED_KEY, false)
        if (!asked || activity == null) {
            return true
        }

        return missing(context).all { activity.shouldShowRequestPermissionRationale(it) }
    }
}
