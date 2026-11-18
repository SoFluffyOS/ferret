package io.sofluffy.ferret_media

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.PlaybackState
import android.os.SystemClock
import java.io.ByteArrayOutputStream
import kotlin.math.max
import kotlin.math.roundToInt

/** Turns media controllers into [PlayerInfo]s and remembers per player what is slow to redo. */
internal class PlayerSnapshots(private val context: Context) {
    private val memory = mutableMapOf<String, Remembered>()

    fun snapshot(key: String, controller: MediaController): PlayerInfo? {
        val metadata = controller.metadata ?: return null
        val state = controller.playbackState
        val title = metadata.text(MediaMetadata.METADATA_KEY_TITLE)
            ?: metadata.text(MediaMetadata.METADATA_KEY_DISPLAY_TITLE)
            ?: return null

        val now = System.currentTimeMillis()
        val status = statusOf(state)
        val remembered = memory.getOrPut(key) { Remembered() }
        if (remembered.title != title || (status == PlayerStatus.PLAYING && remembered.status != PlayerStatus.PLAYING)) {
            remembered.lastActiveAtMs = now
        }
        remembered.title = title
        remembered.status = status

        val artist = metadata.text(MediaMetadata.METADATA_KEY_ARTIST)
            ?: metadata.text(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
            ?: metadata.text(MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE)
            ?: ""
        val (positionMs, positionAtMs) = positionOf(state, now)
        val volume = controller.playbackInfo?.let { info ->
            when (info.maxVolume > 0) {
                true -> info.currentVolume.toDouble() / info.maxVolume
                false -> -1.0
            }
        } ?: -1.0

        return PlayerInfo(
            id = key,
            appId = controller.packageName,
            appName = AppNames.label(context, controller.packageName),
            title = title,
            artist = artist,
            album = metadata.text(MediaMetadata.METADATA_KEY_ALBUM) ?: "",
            artwork = artworkOf(metadata, remembered),
            durationMs = max(0L, metadata.getLong(MediaMetadata.METADATA_KEY_DURATION)),
            positionMs = positionMs,
            positionAtMs = positionAtMs,
            status = status,
            playbackRate = (state?.playbackSpeed ?: 1f).toDouble(),
            contentUri = contentUriFrom(metadata.getString(MediaMetadata.METADATA_KEY_MEDIA_ID)),
            lastActiveAtMs = remembered.lastActiveAtMs,
            actions = actionsOf(state),
            volume = volume,
        )
    }

    fun forget(key: String) {
        memory.remove(key)
    }

    fun clear() = memory.clear()

    private fun artworkOf(metadata: MediaMetadata, remembered: Remembered): ByteArray? {
        val bitmap = metadata.getBitmap(MediaMetadata.METADATA_KEY_ART)
            ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
            ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON)
            ?: return null

        val identity = System.identityHashCode(bitmap) to bitmap.generationId
        if (remembered.artworkIdentity == identity) {
            return remembered.artwork
        }

        val encoded = encode(bitmap)
        remembered.artworkIdentity = identity
        remembered.artwork = encoded
        return encoded
    }

    private fun encode(bitmap: Bitmap): ByteArray? {
        for ((side, quality) in ARTWORK_STEPS) {
            val scaled = scale(bitmap, side)
            val out = ByteArrayOutputStream()
            if (!scaled.compress(Bitmap.CompressFormat.JPEG, quality, out)) {
                return null
            }
            if (scaled !== bitmap) {
                scaled.recycle()
            }
            if (out.size() <= MAX_ARTWORK_BYTES) {
                return out.toByteArray()
            }
        }
        return null
    }

    private fun scale(bitmap: Bitmap, side: Int): Bitmap {
        val longest = max(bitmap.width, bitmap.height)
        if (longest <= side) {
            return bitmap
        }

        val ratio = side.toDouble() / longest
        val width = max(1, (bitmap.width * ratio).roundToInt())
        val height = max(1, (bitmap.height * ratio).roundToInt())
        return Bitmap.createScaledBitmap(bitmap, width, height, true)
    }

    private class Remembered {
        var title: String? = null
        var status: PlayerStatus? = null
        var lastActiveAtMs: Long = 0
        var artworkIdentity: Pair<Int, Int>? = null
        var artwork: ByteArray? = null
    }

    companion object {
        private const val MAX_ARTWORK_BYTES = 64 * 1024
        private val ARTWORK_STEPS = listOf(256 to 80, 192 to 70, 128 to 60)

        /** Keeps media ids that are real links; most apps use opaque ids. */
        fun contentUriFrom(mediaId: String?): String? {
            val id = mediaId?.trim() ?: return null
            val isLink = id.startsWith("spotify:") ||
                id.startsWith("https://") ||
                id.startsWith("http://")
            return when (isLink) {
                true -> id
                false -> null
            }
        }

        fun statusOf(state: PlaybackState?): PlayerStatus = when (state?.state) {
            PlaybackState.STATE_PLAYING,
            PlaybackState.STATE_FAST_FORWARDING,
            PlaybackState.STATE_REWINDING -> PlayerStatus.PLAYING
            PlaybackState.STATE_BUFFERING,
            PlaybackState.STATE_CONNECTING -> PlayerStatus.BUFFERING
            PlaybackState.STATE_PAUSED -> PlayerStatus.PAUSED
            else -> PlayerStatus.STOPPED
        }

        /** The position and the wall clock time it was true at. */
        fun positionOf(state: PlaybackState?, now: Long): Pair<Long, Long> {
            if (state == null || state.position < 0) {
                return 0L to now
            }

            val updatedAt = state.lastPositionUpdateTime
            if (updatedAt <= 0) {
                return state.position to now
            }

            val age = SystemClock.elapsedRealtime() - updatedAt
            return state.position to (now - age)
        }

        fun actionsOf(state: PlaybackState?): List<PlayerAction> {
            val bits = state?.actions ?: return listOf(PlayerAction.SET_VOLUME)
            val actions = mutableListOf<PlayerAction>()
            if (bits and PlaybackState.ACTION_PLAY != 0L) {
                actions.add(PlayerAction.PLAY)
            }
            if (bits and PlaybackState.ACTION_PAUSE != 0L) {
                actions.add(PlayerAction.PAUSE)
            }
            if (bits and (PlaybackState.ACTION_PLAY_PAUSE or PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE) != 0L) {
                actions.add(PlayerAction.TOGGLE)
            }
            if (bits and PlaybackState.ACTION_SKIP_TO_NEXT != 0L) {
                actions.add(PlayerAction.NEXT)
            }
            if (bits and PlaybackState.ACTION_SKIP_TO_PREVIOUS != 0L) {
                actions.add(PlayerAction.PREVIOUS)
            }
            if (bits and PlaybackState.ACTION_SEEK_TO != 0L) {
                actions.add(PlayerAction.SEEK)
            }
            actions.add(PlayerAction.SET_VOLUME)
            return actions
        }
    }
}

private fun MediaMetadata.text(key: String): String? =
    getString(key)?.takeIf { it.isNotBlank() }
