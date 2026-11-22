package io.sofluffy.ferret_drop

import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Received files written straight into Downloads on Android 10 and newer:
 * Dart writes to the file descriptor this hands out, and the file shows in
 * Downloads only once it checked out.
 */
internal class DownloadsChannel(
    messenger: BinaryMessenger,
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, NAME)
    private val io = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.notImplemented()
            return
        }

        val pending = PendingDownloads(context.contentResolver)
        when (call.method) {
            "create" -> background(result) {
                val uri = pending.create(
                    fileName = call.argument<String>("name") ?: "received",
                    mimeType = call.argument<String>("mime") ?: "",
                    folder = call.argument<String>("folder") ?: "",
                )
                try {
                    mapOf("uri" to uri.toString(), "fd" to pending.openForWriting(uri))
                } catch (error: Exception) {
                    pending.delete(uri)
                    throw error
                }
            }
            "open" -> background(result) { pending.openForWriting(uriOf(call)) }
            "size" -> background(result) { pending.size(uriOf(call)) }
            "sha256" -> background(result) { pending.sha256(uriOf(call)) }
            "publish" -> background(result) {
                val saved = pending.publish(uriOf(call))
                mapOf("location" to saved.location, "name" to saved.name)
            }
            "delete" -> background(result) {
                pending.delete(uriOf(call))
                null
            }
            else -> result.notImplemented()
        }
    }

    private fun uriOf(call: MethodCall): Uri = Uri.parse(call.arguments as String)

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (error: FlutterError) {
                main.post { result.error(error.code, error.message, null) }
            } catch (error: Exception) {
                main.post { result.error("storage", error.message, null) }
            }
        }
    }

    private companion object {
        const val NAME = "io.sofluffy.ferret_drop/downloads"
    }
}
