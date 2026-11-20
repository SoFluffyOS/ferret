package io.sofluffy.ferret_drop

import android.app.DownloadManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Share target, MediaStore saving, and opening received files on Android. */
class FerretDropPlugin :
    FlutterPlugin,
    FerretDropHostApi,
    ShareInbox.Listener {
    private var context: Context? = null
    private var flutterApi: FerretDropFlutterApi? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterApi = FerretDropFlutterApi(binding.binaryMessenger)
        FerretDropHostApi.setUp(binding.binaryMessenger, this)
        ShareInbox.setListener(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ShareInbox.setListener(null)
        FerretDropHostApi.setUp(binding.binaryMessenger, null)
        scope.cancel()
        flutterApi = null
        context = null
    }

    override fun onShared(items: SharedItems) {
        val api = flutterApi ?: return ShareInbox.keep(items)
        scope.launch {
            try {
                api.onShared(items)
            } catch (error: FlutterError) {
                ShareInbox.keep(items)
            }
        }
    }

    override fun takePendingShares(): List<SharedItems> = ShareInbox.takeAll()

    override fun setShareTargets(targets: List<ShareTarget>) {
        val context = context ?: return
        ShareShortcuts.publish(context, targets)
    }

    override fun canSaveToDownloads(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    override suspend fun saveToDownloads(
        sourcePath: String,
        fileName: String,
        mimeType: String,
        folder: String,
    ): SavedFile {
        val appContext = context ?: throw FlutterError("detached", "The plugin is not attached")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw FlutterError("unsupported", "MediaStore Downloads needs Android 10")
        }

        return withContext(Dispatchers.IO) {
            DownloadsSaver(appContext.contentResolver).save(File(sourcePath), fileName, mimeType, folder)
        }
    }

    override fun open(location: String, mimeType: String): Boolean {
        val appContext = context ?: return false
        val uri = uriFor(appContext, location) ?: return false
        val type = mimeType.ifEmpty { appContext.contentResolver.getType(uri) ?: "*/*" }
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, type)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)

        return start(appContext, Intent.createChooser(intent, null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    override fun reveal(location: String): Boolean {
        val appContext = context ?: return false
        val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        return start(appContext, intent)
    }

    private fun uriFor(appContext: Context, location: String): Uri? {
        if (location.startsWith("content://")) {
            return Uri.parse(location)
        }

        val file = File(location)
        if (!file.exists()) {
            return null
        }

        return try {
            FileProvider.getUriForFile(appContext, "${appContext.packageName}.ferret_drop.files", file)
        } catch (error: IllegalArgumentException) {
            null
        }
    }

    private fun start(appContext: Context, intent: Intent): Boolean =
        try {
            appContext.startActivity(intent)
            true
        } catch (error: ActivityNotFoundException) {
            false
        }
}
