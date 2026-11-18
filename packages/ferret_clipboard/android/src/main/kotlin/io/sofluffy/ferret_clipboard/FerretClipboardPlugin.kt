package io.sofluffy.ferret_clipboard

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.net.Uri
import android.os.PersistableBundle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Reads and writes the Android clipboard. Since Android 10 only the app in
 * front (or the keyboard) can read it, so reads return null in the background
 * and change events only fire for copies made while Ferret is in front.
 */
class FerretClipboardPlugin : FlutterPlugin, ClipboardHostApi {
    private var context: Context? = null
    private var clipboard: ClipboardManager? = null
    private var flutterApi: ClipboardFlutterApi? = null
    private var scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var watching = false

    private val listener = ClipboardManager.OnPrimaryClipChangedListener {
        val api = flutterApi ?: return@OnPrimaryClipChangedListener
        scope.launch { runCatching { api.onChanged() } }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        clipboard = binding.applicationContext.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        flutterApi = ClipboardFlutterApi(binding.binaryMessenger)
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        ClipboardHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopWatching()
        ClipboardHostApi.setUp(binding.binaryMessenger, null)
        scope.cancel()
        flutterApi = null
        clipboard = null
        context = null
    }

    override fun read(): PlatformClip? {
        val context = context ?: return null
        val clip = clipboard?.primaryClip ?: return null
        if (clip.itemCount == 0) {
            return null
        }

        val description = clip.description
        val sensitive = description.extras?.getBoolean(EXTRA_IS_SENSITIVE, false) == true
        val item = clip.getItemAt(0)

        val text = item.text?.toString()
        if (!text.isNullOrEmpty()) {
            return PlatformClip(text = text, sensitive = sensitive)
        }

        val uri = item.uri
        if (uri != null) {
            val mime = context.contentResolver.getType(uri) ?: imageMimeOf(description)
            if (mime != null && mime.startsWith("image/")) {
                val bytes = readLimited(context, uri) ?: return null
                return PlatformClip(image = bytes, imageMime = mime, sensitive = sensitive)
            }
        }

        val coerced = item.coerceToText(context)?.toString()
        if (coerced.isNullOrEmpty()) {
            return null
        }
        return PlatformClip(text = coerced, sensitive = sensitive)
    }

    override fun write(clip: PlatformClip) {
        val context = context ?: throw FlutterError("detached", "The plugin is not attached.")
        val manager = clipboard ?: throw FlutterError("unavailable", "No clipboard on this device.")

        val text = clip.text
        val image = clip.image
        val data = when {
            text != null -> ClipData.newPlainText(LABEL, text)
            image != null -> {
                val mime = clip.imageMime ?: "image/png"
                val uri = ClipImageProvider.store(context, image, mime)
                ClipData(LABEL, arrayOf(mime), ClipData.Item(uri))
            }
            else -> return
        }

        if (clip.sensitive) {
            data.description.extras = PersistableBundle().apply {
                putBoolean(EXTRA_IS_SENSITIVE, true)
            }
        }

        manager.setPrimaryClip(data)
    }

    override fun startWatching() {
        if (watching) {
            return
        }

        clipboard?.addPrimaryClipChangedListener(listener)
        watching = true
    }

    override fun stopWatching() {
        if (!watching) {
            return
        }

        clipboard?.removePrimaryClipChangedListener(listener)
        watching = false
    }

    private fun imageMimeOf(description: ClipDescription): String? {
        for (index in 0 until description.mimeTypeCount) {
            val mime = description.getMimeType(index)
            if (mime.startsWith("image/")) {
                return mime
            }
        }
        return null
    }

    private fun readLimited(context: Context, uri: Uri): ByteArray? = runCatching {
        context.contentResolver.openInputStream(uri)?.use { input ->
            val bytes = input.readNBytesCompat(MAX_READ_BYTES + 1)
            if (bytes.size > MAX_READ_BYTES) null else bytes
        }
    }.getOrNull()

    private fun java.io.InputStream.readNBytesCompat(limit: Int): ByteArray {
        val output = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(64 * 1024)
        while (output.size() < limit) {
            val read = read(buffer, 0, minOf(buffer.size, limit - output.size()))
            if (read < 0) {
                break
            }
            output.write(buffer, 0, read)
        }
        return output.toByteArray()
    }

    companion object {
        private const val LABEL = "Ferret"

        /** ClipDescription.EXTRA_IS_SENSITIVE, public from Android 13. */
        const val EXTRA_IS_SENSITIVE = "android.content.extra.IS_SENSITIVE"

        /** Larger images are not read at all; Dart applies the user's limit. */
        private const val MAX_READ_BYTES = 32 * 1024 * 1024
    }
}
