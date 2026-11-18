package io.sofluffy.ferret_handoff

import android.app.assist.AssistContent
import android.app.assist.AssistStructure
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle

/** Turns what the assistant sees on screen into a [SharedItem]. */
internal object AssistReader {
    fun read(
        context: Context,
        data: Bundle?,
        structure: AssistStructure?,
        content: AssistContent?,
    ): SharedItem? {
        val webUri = content?.webUri?.toString()?.takeIf { DeepLinks.isWeb(it) }
        val deepLink = content?.intent?.data?.toString()?.takeIf { DeepLinks.isForwardable(it) }
        val structuredData = content?.structuredData?.takeIf { it.isNotBlank() }
        val clipText = content?.clipData
            ?.takeIf { it.itemCount > 0 }
            ?.getItemAt(0)
            ?.coerceToText(context)
            ?.toString()
            ?.takeIf { it.isNotBlank() }
        if (webUri == null && deepLink == null && structuredData == null && clipText == null) {
            return null
        }

        val appPackage = data?.getString(Intent.EXTRA_ASSIST_PACKAGE)
            ?: structure?.activityComponent?.packageName
        val title = structure
            ?.takeIf { it.windowNodeCount > 0 }
            ?.getWindowNodeAt(0)
            ?.title
            ?.toString()
            ?.takeIf { it.isNotBlank() }

        return SharedItem(
            origin = ShareOrigin.ASSISTANT,
            createdAtMs = System.currentTimeMillis(),
            text = clipText,
            webUri = webUri,
            deepLink = deepLink,
            appPackage = appPackage,
            appName = appPackage?.let { appLabel(context, it) },
            structuredData = structuredData,
            title = title,
        )
    }

    private fun appLabel(context: Context, packageName: String): String? = try {
        val info = context.packageManager.getApplicationInfo(packageName, 0)
        context.packageManager.getApplicationLabel(info).toString()
    } catch (_: PackageManager.NameNotFoundException) {
        null
    }
}

/** Which URIs are worth sending to another device. */
internal object DeepLinks {
    private val local = setOf("content", "file", "android.resource", "intent", "javascript", "data")

    fun isWeb(uri: String): Boolean = when (scheme(uri)) {
        "http", "https" -> true
        else -> false
    }

    /** False for URIs that only mean something on this phone, such as content://. */
    fun isForwardable(uri: String): Boolean {
        val scheme = scheme(uri) ?: return false
        return scheme !in local
    }

    fun scheme(uri: String): String? {
        val colon = uri.indexOf(':')
        if (colon <= 0) {
            return null
        }

        val scheme = uri.substring(0, colon).lowercase()
        val valid = scheme.first().isLetter() &&
            scheme.all { it.isLetterOrDigit() || it == '+' || it == '-' || it == '.' }
        if (!valid) {
            return null
        }

        return scheme
    }
}
