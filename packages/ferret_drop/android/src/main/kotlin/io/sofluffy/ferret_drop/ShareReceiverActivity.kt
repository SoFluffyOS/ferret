package io.sofluffy.ferret_drop

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import java.util.concurrent.Executors

/**
 * The "Send with Ferret" share target. It opens Ferret right away, copies the
 * shared content into the cache in the background, then hands it to Dart.
 */
class ShareReceiverActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val uris = sharedUris(intent)
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)?.takeIf { uris.isEmpty() }
        val appContext = applicationContext

        packageManager.getLaunchIntentForPackage(packageName)?.let { launch ->
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            startActivity(launch)
        }

        if (uris.isNotEmpty() || !text.isNullOrEmpty()) {
            copier.execute {
                val paths = SharedFileCopier(appContext).copyAll(uris)
                if (paths.isNotEmpty() || !text.isNullOrEmpty()) {
                    ShareInbox.deliver(SharedItems(paths = paths, text = text))
                }
            }
        }

        finish()
    }

    private fun sharedUris(intent: Intent): List<Uri> {
        val uris = linkedSetOf<Uri>()
        when (intent.action) {
            Intent.ACTION_SEND -> streamExtra(intent)?.let { uris.add(it) }
            Intent.ACTION_SEND_MULTIPLE -> streamListExtra(intent)?.let { uris.addAll(it) }
        }

        val clip = intent.clipData
        if (clip != null && uris.isEmpty()) {
            for (index in 0 until clip.itemCount) {
                clip.getItemAt(index).uri?.let { uris.add(it) }
            }
        }

        return uris.toList()
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
