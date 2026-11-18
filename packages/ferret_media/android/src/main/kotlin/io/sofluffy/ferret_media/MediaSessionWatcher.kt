package io.sofluffy.ferret_media

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import kotlin.math.roundToInt

/**
 * Follows the active media sessions of other apps. Android only hands them to
 * an app whose notification listener is enabled, so this uses the listener
 * that the notifications plugin declares.
 */
internal class MediaSessionWatcher(
    private val context: Context,
    private val onPlayersChanged: (List<PlayerInfo>) -> Unit,
    private val onAccessChanged: (MediaAccess) -> Unit,
) {
    private val handler = Handler(Looper.getMainLooper())
    private val sessionManager =
        context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    private val listenerComponent = ComponentName(context.packageName, LISTENER_CLASS)
    private val controllers = mutableMapOf<String, Tracked>()
    private val snapshots = PlayerSnapshots(context)
    private var watching = false
    private var lastAccess: MediaAccess? = null
    private val emitRunnable = Runnable { emit() }

    private val sessionsListener =
        MediaSessionManager.OnActiveSessionsChangedListener { active ->
            track(active.orEmpty())
        }

    fun access(): MediaAccess {
        val access = when (isListenerEnabled()) {
            true -> MediaAccess.GRANTED
            false -> MediaAccess.NOT_GRANTED
        }
        if (access != lastAccess) {
            lastAccess = access
            if (watching && access == MediaAccess.GRANTED) {
                attach()
            }
        }
        return access
    }

    fun openAccessSettings() {
        val detail = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
        val intent = when (detail) {
            true -> Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                listenerComponent.flattenToString(),
            )
            false -> Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            context.startActivity(
                Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    fun start() {
        if (watching) {
            return
        }

        watching = true
        attach()
    }

    fun stop() {
        if (!watching) {
            return
        }

        watching = false
        handler.removeCallbacks(emitRunnable)
        try {
            sessionManager.removeOnActiveSessionsChangedListener(sessionsListener)
        } catch (_: Exception) {
            // Never added, such as when access was missing.
        }
        untrackAll()
    }

    fun players(): List<PlayerInfo> = controllers.values.mapNotNull { tracked ->
        snapshots.snapshot(tracked.key, tracked.controller)
    }

    fun command(playerId: String, action: PlayerAction, positionMs: Long, volume: Double): Boolean {
        val controller = controllers[playerId]?.controller ?: return false
        val controls = controller.transportControls

        return try {
            when (action) {
                PlayerAction.PLAY -> controls.play()
                PlayerAction.PAUSE -> controls.pause()
                PlayerAction.TOGGLE -> toggle(controller)
                PlayerAction.NEXT -> controls.skipToNext()
                PlayerAction.PREVIOUS -> controls.skipToPrevious()
                PlayerAction.SEEK -> controls.seekTo(positionMs)
                PlayerAction.SET_VOLUME -> setVolume(controller, volume)
            }
            true
        } catch (error: Exception) {
            Log.w(TAG, "Media command $action failed", error)
            false
        }
    }

    private fun toggle(controller: MediaController) {
        val playing = controller.playbackState?.state == PlaybackState.STATE_PLAYING
        if (playing) {
            controller.transportControls.pause()
            return
        }

        controller.transportControls.play()
    }

    private fun setVolume(controller: MediaController, volume: Double) {
        val info = controller.playbackInfo ?: return
        val target = (volume.coerceIn(0.0, 1.0) * info.maxVolume).roundToInt()
        controller.setVolumeTo(target, 0)
    }

    private fun attach() {
        if (!isListenerEnabled()) {
            lastAccess = MediaAccess.NOT_GRANTED
            onAccessChanged(MediaAccess.NOT_GRANTED)
            return
        }

        try {
            sessionManager.removeOnActiveSessionsChangedListener(sessionsListener)
            sessionManager.addOnActiveSessionsChangedListener(
                sessionsListener,
                listenerComponent,
                handler,
            )
            track(sessionManager.getActiveSessions(listenerComponent))
            lastAccess = MediaAccess.GRANTED
            onAccessChanged(MediaAccess.GRANTED)
        } catch (error: SecurityException) {
            Log.w(TAG, "No access to media sessions", error)
            lastAccess = MediaAccess.NOT_GRANTED
            onAccessChanged(MediaAccess.NOT_GRANTED)
        }
    }

    private fun track(active: List<MediaController>) {
        val activeKeys = mutableSetOf<String>()
        for (controller in active) {
            val key = keyFor(controller)
            activeKeys.add(key)
            if (controllers.containsKey(key)) {
                continue
            }

            val callback = ControllerCallback()
            controller.registerCallback(callback, handler)
            controllers[key] = Tracked(key, controller, callback)
        }

        val gone = controllers.keys - activeKeys
        for (key in gone) {
            controllers.remove(key)?.let { tracked ->
                tracked.controller.unregisterCallback(tracked.callback)
            }
            snapshots.forget(key)
        }

        scheduleEmit()
    }

    private fun untrackAll() {
        for (tracked in controllers.values) {
            tracked.controller.unregisterCallback(tracked.callback)
        }
        controllers.clear()
        snapshots.clear()
    }

    private fun scheduleEmit() {
        handler.removeCallbacks(emitRunnable)
        handler.postDelayed(emitRunnable, EMIT_DELAY_MS)
    }

    private fun emit() {
        if (!watching) {
            return
        }

        onPlayersChanged(players())
    }

    private fun isListenerEnabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val manager = context.getSystemService(NotificationManager::class.java)
            return manager?.isNotificationListenerAccessGranted(listenerComponent) == true
        }

        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        return enabled.split(':').any { flattened ->
            ComponentName.unflattenFromString(flattened) == listenerComponent
        }
    }

    private fun keyFor(controller: MediaController): String =
        "${controller.packageName}:${controller.sessionToken.hashCode()}"

    private inner class ControllerCallback : MediaController.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadata?) = scheduleEmit()

        override fun onPlaybackStateChanged(state: PlaybackState?) = scheduleEmit()

        override fun onAudioInfoChanged(info: MediaController.PlaybackInfo) = scheduleEmit()

        override fun onSessionDestroyed() = scheduleEmit()
    }

    private class Tracked(
        val key: String,
        val controller: MediaController,
        val callback: MediaController.Callback,
    )

    companion object {
        private const val TAG = "FerretMedia"
        private const val LISTENER_CLASS =
            "io.sofluffy.ferret_notifications.FerretNotificationListener"

        // Players fire metadata and state callbacks in bursts; one update per
        // burst is enough.
        private const val EMIT_DELAY_MS = 250L
    }
}
