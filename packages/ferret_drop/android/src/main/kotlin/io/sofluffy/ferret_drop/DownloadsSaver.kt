package io.sofluffy.ferret_drop

import android.content.ContentResolver
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import java.io.File
import java.io.IOException

/** Moves a finished file into Downloads/<folder> through MediaStore. */
@RequiresApi(Build.VERSION_CODES.Q)
internal class DownloadsSaver(private val resolver: ContentResolver) {
    fun save(source: File, fileName: String, mimeType: String, folder: String): SavedFile {
        if (!source.isFile) {
            throw FlutterError("missing", "The received file is gone")
        }

        val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/${folder.trim('/')}/"
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val name = freeName(collection, relativePath, fileName)
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            put(MediaStore.Downloads.MIME_TYPE, mimeType.ifEmpty { "application/octet-stream" })
            put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values)
            ?: throw FlutterError("storage", "MediaStore refused the file")

        try {
            val output = resolver.openOutputStream(uri) ?: throw IOException("No output stream")
            output.use { sink -> source.inputStream().use { it.copyTo(sink, BUFFER_SIZE) } }
            resolver.update(uri, ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }, null, null)
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw FlutterError("storage", error.message ?: "Could not write to Downloads")
        }

        source.delete()
        return SavedFile(location = uri.toString(), name = savedName(uri) ?: name)
    }

    private fun freeName(collection: Uri, relativePath: String, wanted: String): String {
        val dot = wanted.lastIndexOf('.').takeIf { it > 0 } ?: wanted.length
        val stem = wanted.substring(0, dot)
        val extension = wanted.substring(dot)
        var candidate = wanted
        var counter = 1
        while (exists(collection, relativePath, candidate)) {
            candidate = "$stem ($counter)$extension"
            counter++
        }

        return candidate
    }

    private fun exists(collection: Uri, relativePath: String, name: String): Boolean {
        val selection = "${MediaStore.Downloads.RELATIVE_PATH}=? AND ${MediaStore.Downloads.DISPLAY_NAME}=?"
        val cursor = resolver.query(collection, arrayOf(MediaStore.Downloads._ID), selection, arrayOf(relativePath, name), null)

        return cursor?.use { it.count > 0 } ?: false
    }

    private fun savedName(uri: Uri): String? =
        resolver.query(uri, arrayOf(MediaStore.Downloads.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }

    private companion object {
        const val BUFFER_SIZE = 256 * 1024
    }
}
