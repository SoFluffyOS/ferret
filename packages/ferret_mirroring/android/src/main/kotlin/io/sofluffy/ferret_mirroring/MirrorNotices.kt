package io.sofluffy.ferret_mirroring

import android.app.Notification
import android.content.Context
import android.os.Build

internal object MirrorNotices {
    @Suppress("DEPRECATION")
    fun builder(context: Context, channel: String): Notification.Builder {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return Notification.Builder(context, channel)
        }

        return Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
    }
}
