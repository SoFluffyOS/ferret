package io.sofluffy.ferret_drop

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.Executors

/**
 * Picks files to send with the system's document picker and copies them
 * into the cache with streams. A picker that hands the bytes over the
 * platform channel runs out of memory at about 100 MB picked.
 */
internal class FilePickChannel(
    messenger: BinaryMessenger,
    private val context: Context,
) : MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener {
    private val channel = MethodChannel(messenger, NAME)
    private val copier = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var activity: Activity? = null
    private var pending: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    fun attach(activity: Activity?) {
        this.activity = activity
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pending?.success(emptyList<String>())
        pending = null
        copier.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFiles" -> pickFiles(result)
            else -> result.notImplemented()
        }
    }

    private fun pickFiles(result: MethodChannel.Result) {
        val host = activity ?: return result.error("no_activity", "Picking files needs Ferret on screen", null)
        if (pending != null) {
            return result.error("busy", "A picker is already open", null)
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
            .putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        try {
            pending = result
            host.startActivityForResult(intent, REQUEST_CODE)
        } catch (error: ActivityNotFoundException) {
            pending = null
            result.error("no_picker", "No document picker on this device", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) {
            return false
        }

        val result = pending ?: return true
        pending = null
        val uris = if (resultCode == Activity.RESULT_OK) urisOf(data) else emptyList()
        if (uris.isEmpty()) {
            result.success(emptyList<String>())
            return true
        }

        copier.execute {
            val paths = SharedFileCopier(context, "picked").copyAll(uris)
            main.post { result.success(paths) }
        }
        return true
    }

    private fun urisOf(data: Intent?): List<Uri> {
        val clip = data?.clipData
        if (clip != null) {
            return (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
        }

        return listOfNotNull(data?.data)
    }

    private companion object {
        const val NAME = "io.sofluffy.ferret_drop/pick"
        const val REQUEST_CODE = 0x4644
    }
}
