package io.sofluffy.ferret_photos

import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import java.io.ByteArrayOutputStream
import java.io.File

/** Where a page starts: the newest item not sent yet, by when it was added
 * and then by id, so pages never skip or repeat an item. */
data class PageCursor(val addedSeconds: Long, val id: Long) {
    fun encode(): String = "$addedSeconds:$id"

    companion object {
        fun parse(value: String?): PageCursor? {
            val parts = value?.split(":") ?: return null
            if (parts.size != 2) {
                return null
            }

            val added = parts[0].toLongOrNull() ?: return null
            val id = parts[1].toLongOrNull() ?: return null
            return PageCursor(added, id)
        }
    }
}

/** Reads photos and videos from MediaStore, newest first. Ids look like
 * `i:42` (an image) or `v:7` (a video). Read only. */
class MediaStoreReader(private val context: Context) {
    private val files: Uri = MediaStore.Files.getContentUri("external")

    fun page(cursor: String?, limit: Int): Map<String, Any> {
        val start = PageCursor.parse(cursor)
        val selection = StringBuilder(MEDIA_FILTER)
        val arguments = mutableListOf<String>()
        if (start != null) {
            selection.append(" AND (${MediaStore.MediaColumns.DATE_ADDED} < ? OR (${MediaStore.MediaColumns.DATE_ADDED} = ? AND ${MediaStore.MediaColumns._ID} < ?))")
            arguments += listOf(start.addedSeconds.toString(), start.addedSeconds.toString(), start.id.toString())
        }

        val entries = mutableListOf<Map<String, Any>>()
        var last: PageCursor? = null
        var hasMore = false
        query(selection.toString(), arguments.toTypedArray())?.use { rows ->
            while (rows.moveToNext()) {
                if (entries.size == limit) {
                    hasMore = true
                    break
                }

                val entry = entryOf(rows) ?: continue
                entries += entry
                last = PageCursor(rows.long(MediaStore.MediaColumns.DATE_ADDED), rows.long(MediaStore.MediaColumns._ID))
            }
        }

        val next = last?.takeIf { hasMore }?.encode() ?: ""
        return mapOf("entries" to entries, "nextCursor" to next)
    }

    /** Screenshots added at or after [sinceSeconds] with an id above
     * [afterId], oldest first. */
    fun screenshotsSince(sinceSeconds: Long, afterId: Long): List<Map<String, Any>> {
        val selection = "$MEDIA_FILTER AND ${MediaStore.MediaColumns.DATE_ADDED} >= ? AND ${MediaStore.MediaColumns._ID} > ?"
        val found = mutableListOf<Map<String, Any>>()
        query(selection, arrayOf(sinceSeconds.toString(), afterId.toString()))?.use { rows ->
            while (rows.moveToNext()) {
                val entry = entryOf(rows) ?: continue
                if (entry["kind"] == "screenshot") {
                    found += entry
                }
            }
        }

        return found.reversed()
    }

    /** The highest id in the library now, so a watcher starts after it. */
    fun newestId(): Long {
        query(MEDIA_FILTER, emptyArray())?.use { rows ->
            if (rows.moveToFirst()) {
                return rows.long(MediaStore.MediaColumns._ID)
            }
        }

        return 0
    }

    fun thumbnail(id: String, maxPx: Int): ByteArray? {
        val uri = uriOf(id) ?: return null
        val bitmap = when {
            Build.VERSION.SDK_INT >= 29 -> runCatching {
                context.contentResolver.loadThumbnail(uri, Size(maxPx, maxPx), null)
            }.getOrNull()
            id.startsWith(VIDEO_PREFIX) -> legacyVideoThumbnail(id)
            else -> decodeScaled(uri, maxPx)
        } ?: return null

        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, out)
        bitmap.recycle()
        return out.toByteArray()
    }

    /** Copies [id] into the app's cache, under its own name, and returns the
     * path. The copy keeps the photo's date. */
    fun export(id: String): String? {
        val uri = uriOf(id) ?: return null
        val (name, takenAt) = nameAndDate(uri) ?: return null
        val folder = File(context.cacheDir, "ferret_photos/${System.nanoTime()}")
        if (!folder.mkdirs()) {
            return null
        }

        val target = File(folder, safeName(name, id))
        val input = context.contentResolver.openInputStream(uri) ?: return null
        input.use { source -> target.outputStream().use { source.copyTo(it) } }
        if (takenAt > 0) {
            target.setLastModified(takenAt)
        }

        return target.path
    }

    private fun query(selection: String, arguments: Array<String>): Cursor? =
        context.contentResolver.query(files, PROJECTION, selection, arguments, SORT)

    private fun entryOf(rows: Cursor): Map<String, Any>? {
        val rowId = rows.long(MediaStore.MediaColumns._ID)
        val isVideo = rows.int(MediaStore.Files.FileColumns.MEDIA_TYPE) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
        val added = rows.long(MediaStore.MediaColumns.DATE_ADDED)
        val taken = rows.long(DATE_TAKEN).takeIf { it > 0 } ?: (added * 1000)
        val folder = rows.string(folderColumn()) ?: ""
        val kind = when {
            isVideo -> "video"
            isScreenshotPath(folder) -> "screenshot"
            else -> "photo"
        }
        val prefix = if (isVideo) VIDEO_PREFIX else IMAGE_PREFIX

        return mapOf(
            "id" to "$prefix$rowId",
            "takenAtMs" to taken,
            "kind" to kind,
            "width" to rows.int(MediaStore.MediaColumns.WIDTH),
            "height" to rows.int(MediaStore.MediaColumns.HEIGHT),
            "size" to rows.long(MediaStore.MediaColumns.SIZE),
            "name" to (rows.string(MediaStore.MediaColumns.DISPLAY_NAME) ?: ""),
            "durationMs" to if (isVideo) rows.long(DURATION) else 0L,
        )
    }

    private fun nameAndDate(uri: Uri): Pair<String, Long>? {
        val columns = arrayOf(MediaStore.MediaColumns.DISPLAY_NAME, DATE_TAKEN)
        context.contentResolver.query(uri, columns, null, null, null)?.use { rows ->
            if (rows.moveToFirst()) {
                return Pair(rows.string(MediaStore.MediaColumns.DISPLAY_NAME) ?: "", rows.long(DATE_TAKEN))
            }
        }

        return null
    }

    private fun uriOf(id: String): Uri? {
        val rowId = id.drop(2).toLongOrNull() ?: return null
        return when {
            id.startsWith(IMAGE_PREFIX) -> ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, rowId)
            id.startsWith(VIDEO_PREFIX) -> ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, rowId)
            else -> null
        }
    }

    private fun decodeScaled(uri: Uri, maxPx: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        context.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        val longest = maxOf(bounds.outWidth, bounds.outHeight)
        if (longest <= 0) {
            return null
        }

        var sample = 1
        while (longest / (sample * 2) >= maxPx) {
            sample *= 2
        }

        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        return context.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, options) }
    }

    @Suppress("DEPRECATION")
    private fun legacyVideoThumbnail(id: String): Bitmap? {
        val rowId = id.drop(2).toLongOrNull() ?: return null
        return MediaStore.Video.Thumbnails.getThumbnail(
            context.contentResolver,
            rowId,
            MediaStore.Video.Thumbnails.MINI_KIND,
            null,
        )
    }

    private fun safeName(name: String, id: String): String {
        val cleaned = name.replace(Regex("[/\\\\:\u0000]"), "_").trim()
        if (cleaned.isEmpty() || cleaned == "." || cleaned == "..") {
            return "photo_${id.drop(2)}"
        }

        return cleaned
    }

    private fun Cursor.long(column: String): Long {
        val index = getColumnIndex(column)
        if (index < 0 || isNull(index)) {
            return 0
        }

        return getLong(index)
    }

    private fun Cursor.int(column: String): Int = long(column).toInt()

    private fun Cursor.string(column: String): String? {
        val index = getColumnIndex(column)
        if (index < 0 || isNull(index)) {
            return null
        }

        return getString(index)
    }

    companion object {
        private const val IMAGE_PREFIX = "i:"
        private const val VIDEO_PREFIX = "v:"
        private const val JPEG_QUALITY = 80

        // Columns that exist on every supported Android, under their names,
        // so older releases don't need the newer constants.
        private const val DATE_TAKEN = "datetaken"
        private const val DURATION = "duration"
        private const val RELATIVE_PATH = "relative_path"
        private const val DATA = "_data"

        private const val SORT =
            "${MediaStore.MediaColumns.DATE_ADDED} DESC, ${MediaStore.MediaColumns._ID} DESC"

        private val MEDIA_FILTER by lazy {
            "${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (" +
                "${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE}, " +
                "${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO})" +
                pendingFilter()
        }

        private val PROJECTION by lazy {
            arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.MediaColumns.DATE_ADDED,
            DATE_TAKEN,
            MediaStore.MediaColumns.WIDTH,
            MediaStore.MediaColumns.HEIGHT,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DISPLAY_NAME,
            DURATION,
            folderColumn(),
            )
        }

        private fun pendingFilter(): String = when {
            Build.VERSION.SDK_INT >= 29 -> " AND is_pending = 0"
            else -> ""
        }

        private fun folderColumn(): String = when {
            Build.VERSION.SDK_INT >= 29 -> RELATIVE_PATH
            else -> DATA
        }

        /** Android and phone makers file screenshots in a "Screenshots"
         * folder, under Pictures or DCIM. */
        fun isScreenshotPath(path: String): Boolean =
            path.split('/').any { it.equals("Screenshots", ignoreCase = true) }
    }
}
