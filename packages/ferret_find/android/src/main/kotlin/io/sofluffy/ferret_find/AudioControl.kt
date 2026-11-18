package io.sofluffy.ferret_find

import android.app.NotificationManager
import android.content.Context
import android.media.AudioManager

/** Reads and sets the alarm volume, its mute, and Do Not Disturb. */
internal class AudioControl(private val context: Context) {
    private val audio: AudioManager?
        get() = context.getSystemService(AudioManager::class.java)

    private val notifications: NotificationManager?
        get() = context.getSystemService(NotificationManager::class.java)

    val controlsVolume: Boolean
        get() = audio?.isVolumeFixed == false

    val dndAccessGranted: Boolean
        get() = notifications?.isNotificationPolicyAccessGranted == true

    fun read(): PlatformAudio? {
        val audio = audio ?: return null
        val filter = notifications?.currentInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_UNKNOWN
        val doNotDisturb = filter > NotificationManager.INTERRUPTION_FILTER_ALL

        return PlatformAudio(
            volume = audio.getStreamVolume(STREAM).toLong(),
            maxVolume = audio.getStreamMaxVolume(STREAM).toLong(),
            muted = audio.isStreamMute(STREAM),
            interruptionFilter = filter.toLong(),
            quiet = audio.ringerMode != AudioManager.RINGER_MODE_NORMAL || doNotDisturb,
        )
    }

    /**
     * Lifting Do Not Disturb comes first so the volume can change; putting
     * it back comes last for the same reason.
     */
    fun apply(target: PlatformAudio) {
        val filter = target.interruptionFilter.toInt()
        if (filter == NotificationManager.INTERRUPTION_FILTER_ALL) {
            applyFilter(filter)
            applyVolume(target)
            return
        }

        applyVolume(target)
        applyFilter(filter)
    }

    private fun applyFilter(filter: Int) {
        val notifications = notifications ?: return
        if (filter == NotificationManager.INTERRUPTION_FILTER_UNKNOWN || !notifications.isNotificationPolicyAccessGranted) {
            return
        }

        if (notifications.currentInterruptionFilter == filter) {
            return
        }

        runCatching { notifications.setInterruptionFilter(filter) }
    }

    private fun applyVolume(target: PlatformAudio) {
        val audio = audio ?: return
        if (audio.isVolumeFixed) {
            return
        }

        if (audio.isStreamMute(STREAM) != target.muted) {
            val direction = if (target.muted) AudioManager.ADJUST_MUTE else AudioManager.ADJUST_UNMUTE
            runCatching { audio.adjustStreamVolume(STREAM, direction, 0) }
        }

        val max = audio.getStreamMaxVolume(STREAM)
        runCatching { audio.setStreamVolume(STREAM, target.volume.toInt().coerceIn(0, max), 0) }
    }

    companion object {
        const val STREAM = AudioManager.STREAM_ALARM
    }
}
