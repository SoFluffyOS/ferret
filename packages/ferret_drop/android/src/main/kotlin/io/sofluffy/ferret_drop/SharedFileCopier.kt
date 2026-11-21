package io.sofluffy.ferret_drop

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import java.io.File
import java.io.IOException

/**
 * Copies shared or picked content URIs into the app cache with streams, so
 * no file is ever held in memory whole.
 */
internal class SharedFileCopier(
    private val context: Context,
    private val subfolder: String = "shared",
) {
    fun copyAll(uris: List<Uri>): List<String> {
        if (uris.isEmpty()) {
            return emptyList()
        }

        val folder = File(context.cacheDir, "ferret_drop/$subfolder/${System.currentTimeMillis()}")
        if (!folder.mkdirs() && !folder.isDirectory) {
            Log.w(TAG, "Could not create the share cache folder")
            return emptyList()
        }

        val used = mutableSetOf<String>()
        return uris.mapIndexedNotNull { index, uri -> copy(uri, folder, uniqueName(displayName(uri, index), used)) }
    }

    private fun copy(uri: Uri, folder: File, name: String): String? {
        val target = File(folder, name)
        return try {
            val input = context.contentResolver.openInputStream(uri) ?: return null
            input.use { source ->
                target.outputStream().use { sink -> source.copyTo(sink, BUFFER_SIZE) }
            }
            target.absolutePath
        } catch (error: IOException) {
            Log.w(TAG, "Could not copy a shared file", error)
            target.delete()
            null
        } catch (error: SecurityException) {
            Log.w(TAG, "No permission to read a shared file", error)
            target.delete()
            null
        }
    }

    private fun displayName(uri: Uri, index: Int): String {
        val queried = try {
            context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                val column = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (column >= 0 && cursor.moveToFirst()) cursor.getString(column) else null
            }
        } catch (error: Exception) {
            null
        }

        val fallback = uri.lastPathSegment ?: "shared-${index + 1}"
        return sanitize(queried ?: fallback)
    }

    private fun sanitize(name: String): String {
        val cleaned = name.substringAfterLast('/').replace(Regex("[\\u0000-\\u001f\\\\:]"), "_").trim()
        if (cleaned.isEmpty() || cleaned == "." || cleaned == "..") {
            return "shared"
        }

        return cleaned
    }

    private fun uniqueName(name: String, used: MutableSet<String>): String {
        if (used.add(name)) {
            return name
        }

        val dot = name.lastIndexOf('.').takeIf { it > 0 } ?: name.length
        val stem = name.substring(0, dot)
        val extension = name.substring(dot)
        var counter = 1
        while (!used.add("$stem ($counter)$extension")) {
            counter++
        }

        return "$stem ($counter)$extension"
    }

    private companion object {
        const val TAG = "FerretDrop"
        const val BUFFER_SIZE = 256 * 1024
    }
}
