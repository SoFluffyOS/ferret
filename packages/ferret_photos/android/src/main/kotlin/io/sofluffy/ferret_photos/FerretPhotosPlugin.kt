package io.sofluffy.ferret_photos

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** Reads MediaStore for Dart: pages of photos, thumbnails, a copy of one
 * photo, and new screenshots while Dart listens. Never deletes or changes a
 * photo, and never logs names or paths. */
class FerretPhotosPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private lateinit var events: EventChannel
    private lateinit var store: MediaStoreReader
    private val main = Handler(Looper.getMainLooper())
    private val worker: ExecutorService = Executors.newSingleThreadExecutor()
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingAccess: MethodChannel.Result? = null
    private var watcher: ScreenshotWatcher? = null

    private val activity: Activity?
        get() = activityBinding?.activity

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        store = MediaStoreReader(context)
        methods = MethodChannel(binding.binaryMessenger, "io.sofluffy.ferret_photos")
        methods.setMethodCallHandler(this)
        events = EventChannel(binding.binaryMessenger, "io.sofluffy.ferret_photos/screenshots")
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        onCancel(null)
        worker.shutdown()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        finishAccessRequest()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "access" -> result.success(access().wireName)
            "requestAccess" -> requestAccess(result)
            "list" -> background(result) {
                if (!access().canRead) {
                    return@background mapOf("entries" to emptyList<Any>())
                }

                val cursor = call.argument<String>("cursor")
                val limit = (call.argument<Int>("limit") ?: 60).coerceIn(1, MAX_PAGE)
                store.page(cursor, limit)
            }
            "thumbnail" -> background(result) {
                val id = call.argument<String>("id") ?: return@background null
                val maxPx = (call.argument<Int>("maxPx") ?: 256).coerceIn(32, MAX_THUMBNAIL)
                if (!access().canRead) {
                    return@background null
                }

                store.thumbnail(id, maxPx)
            }
            "export" -> background(result) {
                val id = call.argument<String>("id") ?: return@background null
                if (!access().canRead) {
                    return@background null
                }

                store.export(id)
            }
            "openSettings" -> result.success(openSettings())
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        onCancel(null)
        val started = ScreenshotWatcher(context, store, main) { entry -> sink.success(entry) }
        watcher = started
        started.start()
    }

    override fun onCancel(arguments: Any?) {
        watcher?.stop()
        watcher = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) {
            return false
        }

        finishAccessRequest()
        return true
    }

    private fun requestAccess(result: MethodChannel.Result) {
        val current = activity
        if (current == null) {
            result.success(access().wireName)
            return
        }

        finishAccessRequest()
        pendingAccess = result
        preferences().edit().putBoolean(ASKED_KEY, true).apply()
        current.requestPermissions(PhotoAccess.permissionsToAsk(), REQUEST_CODE)
    }

    private fun finishAccessRequest() {
        val waiting = pendingAccess ?: return
        pendingAccess = null
        waiting.success(access().wireName)
    }

    private fun access(): PhotoAccess {
        val granted = PhotoAccess.permissionsToAsk().filter { isGranted(it) }.toSet()
        val asked = preferences().getBoolean(ASKED_KEY, false)
        return PhotoAccess.from(Build.VERSION.SDK_INT, granted, asked)
    }

    private fun isGranted(permission: String): Boolean =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun openSettings(): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        return runCatching { context.startActivity(intent) }.isSuccess
    }

    private fun preferences() = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            val outcome = runCatching(work)
            main.post {
                outcome
                    .onSuccess { result.success(it) }
                    .onFailure { result.error("photos_failed", it.javaClass.simpleName, null) }
            }
        }
    }

    companion object {
        private const val REQUEST_CODE = 0x7f05
        private const val PREFERENCES = "io.sofluffy.ferret_photos"
        private const val ASKED_KEY = "asked"
        private const val MAX_PAGE = 200
        private const val MAX_THUMBNAIL = 2048
    }
}
