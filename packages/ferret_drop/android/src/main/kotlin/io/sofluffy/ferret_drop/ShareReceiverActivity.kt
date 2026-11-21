package io.sofluffy.ferret_drop

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.core.content.pm.ShortcutManagerCompat
import java.util.concurrent.Executors

/**
 * The "Send with Ferret" share target. It keeps the permission to read the
 * shared URIs and hands them to Dart, which reads them while sending. Picked as Ferret, it opens
 * Ferret to ask where; picked as a device in the share sheet's top row, it
 * sends there without opening Ferret, when Ferret is already running.
 */
class ShareReceiverActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
        val uris = sharedUris(intent, sharedText)
        val text = sharedText?.takeIf { uris.isEmpty() }
        val appContext = applicationContext
        val deviceId = ShareShortcuts.deviceId(intent.getStringExtra(ShortcutManagerCompat.EXTRA_SHORTCUT_ID))

        if (deviceId != null) {
            ShareShortcuts.reportUsed(appContext, deviceId)
        }
        val name = deviceId?.let(ShareShortcuts::name)
        if (name != null && ShareInbox.isListening) {
            Toast.makeText(appContext, getString(R.string.ferret_drop_sending_to, name), Toast.LENGTH_SHORT).show()
        } else {
            packageManager.getLaunchIntentForPackage(packageName)?.let { launch ->
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                startActivity(launch)
            }
        }

        if (uris.isEmpty() && text.isNullOrEmpty()) {
            finish()
            return
        }

        // A URI whose grant can't be kept is copied into the cache instead,
        // before this activity finishes: its grant ends with the activity.
        val kept = uris.map { uri -> uri to SharePermissions.keep(appContext, uri) }
        if (kept.all { it.second }) {
            ShareInbox.deliver(SharedItems(paths = uris.map(Uri::toString), text = text, deviceId = deviceId))
            finish()
            return
        }

        copier.execute {
            val paths = kept.mapNotNull { (uri, readable) ->
                if (readable) uri.toString() else SharedFileCopier(appContext).copyAll(listOf(uri)).firstOrNull()
            }
            if (paths.isNotEmpty() || !text.isNullOrEmpty()) {
                ShareInbox.deliver(SharedItems(paths = paths, text = text, deviceId = deviceId))
            }
            runOnUiThread { finish() }
        }
    }

    private fun sharedUris(intent: Intent, text: String?): List<Uri> {
        val streams = when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(streamExtra(intent))
            Intent.ACTION_SEND_MULTIPLE -> streamListExtra(intent).orEmpty()
            else -> emptyList()
        }
        val clip = intent.clipData
        val clipItems = when (clip) {
            null -> emptyList()
            else -> (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
        }

        return SharedContent.files(streams, clipItems, text)
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    @Suppress("DEPRECATION")
    private fun streamListExtra(intent: Intent): List<Uri>? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        }

    private companion object {
        val copier = Executors.newSingleThreadExecutor()
    }
}
