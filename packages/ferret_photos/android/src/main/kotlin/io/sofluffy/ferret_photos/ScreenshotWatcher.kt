package io.sofluffy.ferret_photos

import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.provider.MediaStore
import java.util.concurrent.Executors

/** Tells [onScreenshot] about each screenshot added after [start], once,
 * through a MediaStore ContentObserver: nothing runs until a photo is
 * added, and nothing taken before is ever replayed. */
class ScreenshotWatcher(
    private val context: Context,
    private val store: MediaStoreReader,
    private val main: Handler,
    private val onScreenshot: (Map<String, Any>) -> Unit,
) {
    private val worker = Executors.newSingleThreadExecutor()
    private var startedAt = 0L
    private var lastId = 0L
    private var observer: ContentObserver? = null

    fun start() {
        startedAt = System.currentTimeMillis() / 1000
        worker.execute { lastId = runCatching { store.newestId() }.getOrDefault(0) }
        val watching = object : ContentObserver(main) {
            override fun onChange(selfChange: Boolean, uri: Uri?) = check()
        }
        observer = watching
        context.contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            watching,
        )
    }

    fun stop() {
        observer?.let { context.contentResolver.unregisterContentObserver(it) }
        observer = null
        worker.shutdown()
    }

    private fun check() {
        if (worker.isShutdown) {
            return
        }

        worker.execute {
            val found = runCatching { store.screenshotsSince(startedAt, lastId) }.getOrDefault(emptyList())
            for (entry in found) {
                val rowId = (entry["id"] as? String)?.drop(2)?.toLongOrNull() ?: continue
                lastId = maxOf(lastId, rowId)
                main.post { if (observer != null) onScreenshot(entry) }
            }
        }
    }
}
