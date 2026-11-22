package io.sofluffy.ferret_drop

import android.content.ContentResolver
import android.os.Build
import androidx.annotation.RequiresApi
import java.io.File
import java.io.IOException

/** Moves a finished file into Downloads/<folder> through MediaStore. */
@RequiresApi(Build.VERSION_CODES.Q)
internal class DownloadsSaver(private val resolver: ContentResolver) {
    private val pending = PendingDownloads(resolver)

    fun save(source: File, fileName: String, mimeType: String, folder: String): SavedFile {
        if (!source.isFile) {
            throw FlutterError("missing", "The received file is gone")
        }

        val uri = pending.create(fileName, mimeType, folder)
        val saved = try {
            val output = resolver.openOutputStream(uri) ?: throw IOException("No output stream")
            output.use { sink -> source.inputStream().use { it.copyTo(sink, BUFFER_SIZE) } }
            pending.publish(uri)
        } catch (error: Exception) {
            pending.delete(uri)
            throw FlutterError("storage", error.message ?: "Could not write to Downloads")
        }

        source.delete()
        return SavedFile(location = saved.location, name = saved.name.ifEmpty { fileName })
    }

    private companion object {
        const val BUFFER_SIZE = 256 * 1024
    }
}
