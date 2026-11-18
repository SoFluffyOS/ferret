package io.sofluffy.ferret_media

import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/** Media sessions of other apps, through the notification listener's access. */
class FerretMediaPlugin : FlutterPlugin, MediaHostApi {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var watcher: MediaSessionWatcher? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val api = MediaFlutterApi(binding.binaryMessenger)
        watcher = MediaSessionWatcher(
            context = binding.applicationContext,
            onPlayersChanged = { players -> deliver { api.onPlayersChanged(players) } },
            onAccessChanged = { access -> deliver { api.onAccessChanged(access) } },
        )
        MediaHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MediaHostApi.setUp(binding.binaryMessenger, null)
        watcher?.stop()
        watcher = null
        scope.cancel()
    }

    override fun access(): MediaAccess = requireWatcher().access()

    override suspend fun requestAccess(): MediaAccess {
        val current = requireWatcher().access()
        if (current != MediaAccess.GRANTED) {
            requireWatcher().openAccessSettings()
        }
        return current
    }

    override fun openAccessSettings() = requireWatcher().openAccessSettings()

    override fun startWatching() = requireWatcher().start()

    override fun stopWatching() = requireWatcher().stop()

    override suspend fun players(): List<PlayerInfo> = requireWatcher().players()

    override suspend fun command(
        playerId: String,
        action: PlayerAction,
        positionMs: Long,
        volume: Double,
    ): Boolean = requireWatcher().command(playerId, action, positionMs, volume)

    private fun requireWatcher(): MediaSessionWatcher =
        watcher ?: throw FlutterError("detached", "The media plugin is not attached", null)

    private fun deliver(call: suspend () -> Unit) {
        scope.launch {
            try {
                call()
            } catch (_: FlutterError) {
                // The Dart side isn't listening yet; the next change or a
                // players() call brings it up to date.
            }
        }
    }
}
