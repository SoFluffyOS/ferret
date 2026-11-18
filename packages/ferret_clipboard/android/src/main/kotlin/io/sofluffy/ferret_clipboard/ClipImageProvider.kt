package io.sofluffy.ferret_clipboard

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import java.io.File

/**
 * Serves the one image Ferret last put on the clipboard, since Android
 * clipboards hold images as content URIs. Read-only; the clipboard service
 * grants other apps access when they paste.
 */
class ClipImageProvider : ContentProvider() {
    override fun onCreate(): Boolean = true

    override fun getType(uri: Uri): String? = fileFor(uri)?.let { mimeOf(it.name) }

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor? {
        if (mode != "r") {
            throw SecurityException("Clipboard images are read-only")
        }

        val file = fileFor(uri) ?: throw java.io.FileNotFoundException(uri.toString())
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? {
        val file = fileFor(uri) ?: return null
        val columns = arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        return MatrixCursor(columns, 1).apply { addRow(arrayOf<Any>(file.name, file.length())) }
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0

    private fun fileFor(uri: Uri): File? {
        val context = context ?: return null
        val name = uri.lastPathSegment ?: return null
        if (name.contains('/') || name.startsWith(".")) {
            return null
        }

        val file = File(directory(context), name)
        return file.takeIf { it.isFile }
    }

    companion object {
        private const val DIRECTORY = "ferret_clipboard"

        fun authority(context: Context): String = "${context.packageName}.ferret_clipboard.images"

        /** Saves [bytes] as the current clipboard image, replacing the last one. */
        fun store(context: Context, bytes: ByteArray, mime: String): Uri {
            val directory = directory(context)
            directory.mkdirs()
            directory.listFiles()?.forEach { it.delete() }

            val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) ?: "png"
            val file = File(directory, "clip-${System.currentTimeMillis()}.$extension")
            file.writeBytes(bytes)

            return Uri.Builder()
                .scheme("content")
                .authority(authority(context))
                .appendPath(file.name)
                .build()
        }

        private fun directory(context: Context): File = File(context.cacheDir, DIRECTORY)

        private fun mimeOf(name: String): String {
            val extension = name.substringAfterLast('.', "")
            return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "image/png"
        }
    }
}
