package io.sofluffy.ferret_drop

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.os.StatFs
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Free space where received files land, and the system's storage settings. */
internal class FreeSpaceChannel(
    messenger: BinaryMessenger,
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, NAME)

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "freeBytes" -> result.success(freeBytes(call.arguments as? String))
            "openStorageSettings" -> result.success(openStorageSettings())
            else -> result.notImplemented()
        }
    }

    private fun freeBytes(path: String?): Long? {
        if (path == null) {
            return null
        }

        return try {
            StatFs(path).availableBytes
        } catch (error: IllegalArgumentException) {
            null
        }
    }

    private fun openStorageSettings(): Boolean =
        try {
            context.startActivity(
                Intent(Settings.ACTION_INTERNAL_STORAGE_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        } catch (error: ActivityNotFoundException) {
            false
        }

    private companion object {
        const val NAME = "io.sofluffy.ferret_drop/space"
    }
}
