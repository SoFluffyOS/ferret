package io.sofluffy.ferret_camera

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** Opens the phone's own camera app (ACTION_IMAGE_CAPTURE) for one photo,
 * into a file only Ferret and that app can reach. The person sees the
 * camera and presses the shutter; nothing is captured otherwise. Android
 * has no document scanner without Google's libraries, so scanning is
 * never available here. Never logs paths. */
class FerretCameraPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.RequestPermissionsResultListener {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private val main = Handler(Looper.getMainLooper())
    private val worker: ExecutorService = Executors.newSingleThreadExecutor()
    private var activityBinding: ActivityPluginBinding? = null
    private var pending: MethodChannel.Result? = null
    private var target: File? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "io.sofluffy.ferret_camera")
        methods.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        worker.shutdown()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    // The camera app may turn the screen; the answer then reaches the new
    // activity, so a waiting photo stays waiting.
    override fun onDetachedFromActivityForConfigChanges() = detach()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        detach()
        target?.delete()
        target = null
        finish(outcome("cancelled"))
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "abilities" -> result.success(mapOf("photo" to canTakePhoto(), "document" to false))
            "takePhoto" -> takePhoto(result)
            "scanDocument" -> result.success(outcome("unavailable"))
            else -> result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != CAPTURE_REQUEST) {
            return false
        }

        val file = target
        target = null
        if (resultCode != Activity.RESULT_OK || file == null || !file.exists() || file.length() == 0L) {
            file?.delete()
            finish(outcome("cancelled"))
            return true
        }

        worker.execute {
            val path = PhotoNormalizer.normalize(file)
            main.post {
                finish(
                    when (path) {
                        null -> outcome("failed")
                        else -> mapOf("outcome" to "taken", "path" to path, "mimeType" to "image/jpeg")
                    },
                )
            }
        }
        return true
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST) {
            return false
        }

        val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        val activity = activityBinding?.activity
        if (!granted || activity == null) {
            finish(outcome("noPermission"))
            return true
        }

        launch(activity)
        return true
    }

    private fun takePhoto(result: MethodChannel.Result) {
        val activity = activityBinding?.activity
        if (pending != null) {
            result.success(outcome("failed"))
            return
        }

        if (activity == null || !canTakePhoto()) {
            result.success(outcome("unavailable"))
            return
        }

        pending = result
        if (needsCameraPermission()) {
            ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.CAMERA), PERMISSION_REQUEST)
            return
        }

        launch(activity)
    }

    private fun launch(activity: Activity) {
        try {
            val folder = File(context.cacheDir, FOLDER).apply { mkdirs() }
            val file = File(folder, "capture-${System.currentTimeMillis()}.jpg")
            val uri = FileProvider.getUriForFile(context, "${context.packageName}.ferret_camera", file)
            val intent = captureIntent()
                .putExtra(MediaStore.EXTRA_OUTPUT, uri)
                .addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            intent.clipData = ClipData.newRawUri("", uri)
            target = file
            activity.startActivityForResult(intent, CAPTURE_REQUEST)
        } catch (error: ActivityNotFoundException) {
            target = null
            finish(outcome("unavailable"))
        } catch (error: SecurityException) {
            target = null
            finish(outcome("noPermission"))
        } catch (error: Exception) {
            target = null
            finish(outcome("failed"))
        }
    }

    /** Some app in the same APK (here: scanning a pairing code) declares
     * CAMERA. Android then refuses ACTION_IMAGE_CAPTURE until it is
     * granted, so it is asked for right after the person pressed Take
     * photo. */
    private fun needsCameraPermission(): Boolean {
        val declared = try {
            context.packageManager
                .getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
                .requestedPermissions
                ?.contains(Manifest.permission.CAMERA) == true
        } catch (error: PackageManager.NameNotFoundException) {
            false
        }

        return declared &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) !=
            PackageManager.PERMISSION_GRANTED
    }

    private fun canTakePhoto(): Boolean {
        val manager = context.packageManager
        return manager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY) &&
            captureIntent().resolveActivity(manager) != null
    }

    private fun detach() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    private fun finish(answer: Map<String, Any>) {
        val result = pending ?: return
        pending = null
        result.success(answer)
    }

    private fun captureIntent() = Intent(MediaStore.ACTION_IMAGE_CAPTURE)

    private fun outcome(name: String) = mapOf("outcome" to name)

    private companion object {
        const val FOLDER = "ferret_camera"
        const val CAPTURE_REQUEST = 0x4643
        const val PERMISSION_REQUEST = 0x4644
    }
}
