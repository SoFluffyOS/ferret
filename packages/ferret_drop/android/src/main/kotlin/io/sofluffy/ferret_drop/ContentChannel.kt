package io.sofluffy.ferret_drop

import android.content.Context
import android.content.res.AssetFileDescriptor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/**
 * Reads shared and picked `content://` URIs straight from the app that has
 * them while they are sent, so a share never waits for a copy into the
 * cache or needs room for one.
 */
internal class ContentChannel(
    messenger: BinaryMessenger,
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, NAME)
    private val io = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())
    private val streams = ConcurrentHashMap<Int, InputStream>()
    private val nextHandle = AtomicInteger(1)

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        streams.values.forEach { runCatching { it.close() } }
        streams.clear()
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "describe" -> background(result) { describe(Uri.parse(call.arguments as String)) }
            "open" -> background(result) { open(Uri.parse(call.arguments as String)) }
            "read" -> background(result) {
                val handle = call.argument<Int>("handle") ?: -1
                val length = call.argument<Int>("length") ?: 0
                val input = streams[handle] ?: throw IllegalStateException("Not open")
                BlockReads.read(input, length)
            }
            "close" -> background(result) {
                streams.remove(call.arguments as Int)?.close()
                null
            }
            "copy" -> background(result) {
                val uri = Uri.parse(call.arguments as String)
                val path = SharedFileCopier(context).copyAll(listOf(uri)).firstOrNull()
                SharePermissions.release(context, uri)
                path
            }
            "release" -> background(result) {
                SharePermissions.release(context, Uri.parse(call.arguments as String))
                null
            }
            else -> result.notImplemented()
        }
    }

    private fun describe(uri: Uri): Map<String, Any?> {
        val resolver = context.contentResolver
        var name: String? = null
        var size = -1L
        var modified = 0L
        resolver.query(uri, null, null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return@use
            }

            cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME).takeIf { it >= 0 }?.let {
                name = cursor.getString(it)
            }
            cursor.getColumnIndex(OpenableColumns.SIZE).takeIf { it >= 0 && !cursor.isNull(it) }?.let {
                size = cursor.getLong(it)
            }
            cursor.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
                .takeIf { it >= 0 && !cursor.isNull(it) }
                ?.let { modified = cursor.getLong(it) }
        }
        if (size < 0) {
            size = runCatching {
                resolver.openAssetFileDescriptor(uri, "r")?.use { it.length }
            }.getOrNull() ?: AssetFileDescriptor.UNKNOWN_LENGTH
        }

        return mapOf(
            "name" to (name ?: uri.lastPathSegment?.substringAfterLast('/') ?: "shared"),
            "size" to size,
            "mime" to (resolver.getType(uri) ?: ""),
            "modified" to modified,
        )
    }

    /** Opens [uri] at its start; "length" is what the app reports, or -1. */
    private fun open(uri: Uri): Map<String, Any> {
        val resolver = context.contentResolver
        val described = runCatching { resolver.openAssetFileDescriptor(uri, "r") }.getOrNull()
        val (input, length) = when (described) {
            null -> (resolver.openInputStream(uri) ?: throw IllegalStateException("No stream")) to -1L
            else -> described.createInputStream() to described.length
        }
        val handle = nextHandle.getAndIncrement()
        streams[handle] = input
        return mapOf("handle" to handle, "length" to length)
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (error: Exception) {
                main.post { result.error("unreadable", error.message, null) }
            }
        }
    }

    private companion object {
        const val NAME = "io.sofluffy.ferret_drop/content"
    }
}
