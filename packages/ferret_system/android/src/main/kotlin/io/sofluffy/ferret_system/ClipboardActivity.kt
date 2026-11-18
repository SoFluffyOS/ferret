package io.sofluffy.ferret_system

import android.app.Activity
import android.app.PendingIntent
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

/**
 * An invisible activity that reads the clipboard and hands it to Dart.
 * Android 10+ only lets the app in focus read the clipboard, so the tile and
 * the notification open this for a moment instead of reading it themselves.
 */
class ClipboardActivity : Activity() {
    private var handled = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FerretRuntime.wake(this)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus || handled) {
            return
        }

        handled = true
        sendClipboard()
        finish()
    }

    @Suppress("DEPRECATION")
    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }

    private fun sendClipboard() {
        val clipboard = getSystemService(ClipboardManager::class.java)
        val clip = clipboard?.primaryClip
        val text = when {
            clip == null || clip.itemCount == 0 -> null
            else -> clip.getItemAt(0).coerceToText(this)?.toString()
        }

        if (text.isNullOrEmpty()) {
            Toast.makeText(this, R.string.ferret_system_clipboard_empty, Toast.LENGTH_SHORT).show()
            return
        }

        val source = intent.getStringExtra(EXTRA_SOURCE) ?: "tile"
        FerretRuntime.dispatch(
            SystemActionMessage(id = ACTION_CLIPBOARD_SEND, data = mapOf("text" to text, "source" to source)),
        )
    }

    companion object {
        const val ACTION_CLIPBOARD_SEND = "clipboard.send"
        private const val EXTRA_SOURCE = "source"

        fun intent(context: Context, source: String): Intent =
            Intent(context, ClipboardActivity::class.java)
                .putExtra(EXTRA_SOURCE, source)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION)

        fun pendingIntent(context: Context, requestCode: Int, source: String): PendingIntent =
            PendingIntent.getActivity(
                context,
                requestCode,
                intent(context, source),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
    }
}
