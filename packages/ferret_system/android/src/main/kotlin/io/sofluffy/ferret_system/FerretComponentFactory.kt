package io.sofluffy.ferret_system

import android.content.BroadcastReceiver
import android.content.Intent
import androidx.core.app.CoreComponentFactory

/**
 * Builds the app's components, with [NoticeButtonReceiver] in place of the
 * notification plugin's button receiver. Set it as the app's
 * `android:appComponentFactory` (with `tools:replace`).
 */
class FerretComponentFactory : CoreComponentFactory() {
    override fun instantiateReceiver(cl: ClassLoader, className: String, intent: Intent?): BroadcastReceiver {
        if (className == NoticeButtonReceiver.PLUGIN_RECEIVER) {
            return NoticeButtonReceiver()
        }

        return super.instantiateReceiver(cl, className, intent)
    }
}
