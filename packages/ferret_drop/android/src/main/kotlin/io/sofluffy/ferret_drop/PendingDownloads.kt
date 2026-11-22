package io.sofluffy.ferret_drop

import android.content.ContentResolver
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import java.io.FileNotFoundException

/**
 * Files in Downloads/<folder> that are still arriving. Each one is a
 * MediaStore item marked pending, so no other app sees it until [publish]
 * after its checksum matched; [delete] throws away one that won't finish.
 * Android also deletes a pending item left behind after a week.
 */
@RequiresApi(Build.VERSION_CODES.Q)
internal class PendingDownloads(private val resolver: ContentResolver) {
    private val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

    fun create(fileName: String, mimeType: String, folder: String): Uri {
        val relativePath = DownloadNames.relativePath(Environment.DIRECTORY_DOWNLOADS, folder)
        val name = DownloadNames.free(fileName) { exists(relativePath, it) }
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            put(MediaStore.Downloads.MIME_TYPE, mimeType.ifEmpty { "application/octet-stream" })
            put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        return resolver.insert(collection, values)
            ?: throw FlutterError("storage", "MediaStore refused the file")
    }

    /** A file descriptor open for reading and writing, which the caller closes. */
    fun openForWriting(uri: Uri): Int {
        val descriptor = try {
            resolver.openFileDescriptor(uri, "rw")
        } catch (error: FileNotFoundException) {
            null
        } ?: throw FlutterError("gone", "The file is no longer in Downloads")

        return descriptor.detachFd()
    }

    /** Bytes in the file, or -1 when it is gone. */
    fun size(uri: Uri): Long =
        try {
            resolver.openFileDescriptor(uri, "r")?.use { it.statSize } ?: -1
        } catch (error: FileNotFoundException) {
            -1
        }

    fun sha256(uri: Uri): ByteArray {
        val input = resolver.openInputStream(uri) ?: throw FlutterError("gone", "The file is no longer in Downloads")
        return input.use { StreamDigest.sha256(it) }
    }

    /** Shows the file in Downloads. */
    fun publish(uri: Uri): SavedFile {
        val values = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
        if (resolver.update(uri, values, null, null) == 0) {
            throw FlutterError("gone", "The file is no longer in Downloads")
        }

        return SavedFile(location = uri.toString(), name = savedName(uri) ?: "")
    }

    fun delete(uri: Uri) {
        resolver.delete(uri, null, null)
    }

    private fun exists(relativePath: String, name: String): Boolean {
        val selection = "${MediaStore.Downloads.RELATIVE_PATH}=? AND ${MediaStore.Downloads.DISPLAY_NAME}=?"
        val cursor = resolver.query(collection, arrayOf(MediaStore.Downloads._ID), selection, arrayOf(relativePath, name), null)

        return cursor?.use { it.count > 0 } ?: false
    }

    private fun savedName(uri: Uri): String? =
        resolver.query(uri, arrayOf(MediaStore.Downloads.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }
}
