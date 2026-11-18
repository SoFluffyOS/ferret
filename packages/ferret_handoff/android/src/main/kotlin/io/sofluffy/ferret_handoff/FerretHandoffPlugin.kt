package io.sofluffy.ferret_handoff

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.service.voice.VoiceInteractionService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * Handoff on Android: the share target and the assistant hand what the user
 * picked to Dart, and Dart can open links in a given app.
 */
class FerretHandoffPlugin : FlutterPlugin, HandoffHostApi {
    private var context: Context? = null
    internal var events: HandoffEventsApi? = null
        private set
    internal val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        events = HandoffEventsApi(binding.binaryMessenger)
        HandoffHostApi.setUp(binding.binaryMessenger, this)
        synchronized(attached) { attached.add(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        synchronized(attached) { attached.remove(this) }
        HandoffHostApi.setUp(binding.binaryMessenger, null)
        scope.cancel()
        events = null
        context = null
    }

    override fun setDevices(devices: List<HandoffDevice>) {
        val context = context ?: return
        HandoffStore(context).setDevices(devices)
    }

    override fun takePending(): List<SharedItem> {
        val context = context ?: return emptyList()
        return HandoffStore(context).takePending()
    }

    override suspend fun openInApp(uri: String, appId: String): Boolean {
        val context = context ?: return false
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri))
            .setPackage(appId)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        return try {
            context.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    override fun isAssistantEnabled(): Boolean {
        val context = context ?: return false
        val component = ComponentName(context, FerretAssistService::class.java)
        return VoiceInteractionService.isActiveService(context, component)
    }

    override fun openAssistantSettings() {
        val context = context ?: return
        val candidates = listOf(
            Settings.ACTION_VOICE_INPUT_SETTINGS,
            Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS,
            Settings.ACTION_SETTINGS,
        )

        for (action in candidates) {
            try {
                context.startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            } catch (_: ActivityNotFoundException) {
                continue
            }
        }
    }

    override suspend fun currentBrowserTab(): BrowserTab? = null

    override suspend fun browserAccess(): BrowserAccess = BrowserAccess.UNSUPPORTED

    override fun setBrowserWatch(enabled: Boolean) {}

    internal companion object {
        private val attached = mutableListOf<FerretHandoffPlugin>()

        /** The most recently attached plugin whose Flutter side can take items. */
        val active: FerretHandoffPlugin?
            get() = synchronized(attached) { attached.lastOrNull { it.events != null } }
    }
}
