package io.sofluffy.ferret_find

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Rings this phone: a looping alarm-stream tone, vibration, an optional torch
 * blink and a full-screen notification with "Found it". One ring at a time,
 * shared by the plugin and [FindActionReceiver]. Main thread only.
 */
internal object FindAlarm {
    const val CHANNEL_ID = "ferret.find"
    const val ACTION_FOUND = "io.sofluffy.ferret_find.FOUND"
    const val ACTION_DISMISSED = "io.sofluffy.ferret_find.DISMISSED"
    const val REASON_FOUND = "found"
    const val REASON_VOLUME_KEY = "volume_key"
    const val REASON_TIMEOUT = "timeout"

    /** Same name the app gives this channel elsewhere. */
    private const val CHANNEL_NAME = "Find my device"
    private const val NOTIFICATION_ID = 0x46494e44
    private const val VOLUME_CHANGED = "android.media.VOLUME_CHANGED_ACTION"
    private val VIBRATION = longArrayOf(0, 700, 500)

    /** Told when the ring stops on the phone itself, not when Dart stops it. */
    fun interface Listener {
        fun onStopped(reason: String)
    }

    var listener: Listener? = null

    val volumeKeys = VolumeKeyFilter()

    private val handler = Handler(Looper.getMainLooper())
    private val safetyStop = Runnable { stop(REASON_TIMEOUT) }
    private val alarmAttributes: AudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()

    private var context: Context? = null
    private var player: MediaPlayer? = null
    private var tone: ToneGenerator? = null
    private var vibrator: Vibrator? = null
    private var torch: TorchBlinker? = null
    private var volumeReceiver: BroadcastReceiver? = null
    private var focusRequest: AudioFocusRequest? = null

    val isRinging: Boolean
        get() = context != null

    /** Starts ringing, replacing a ring already going. Throws when no sound can play. */
    fun start(appContext: Context, alert: PlatformAlert) {
        release()
        val context = appContext.applicationContext
        this.context = context

        postNotification(context, alert)
        if (!alert.silent && !playSound(context)) {
            release()
            throw FlutterError("no_sound", "This phone could not play a ring tone.")
        }

        if (alert.vibrate) {
            vibrate(context)
        }

        if (alert.flashTorch) {
            torch = TorchBlinker.start(context, handler)
        }

        watchVolumeKeys(context)
        handler.postDelayed(safetyStop, alert.maxSeconds.coerceAtLeast(1) * 1000L)
    }

    /** Stops because of something on the phone, and tells the listener why. */
    fun stop(reason: String) {
        if (!isRinging) {
            return
        }

        release()
        listener?.onStopped(reason)
    }

    /** Stops everything without telling anyone. Safe to call when idle. */
    fun release() {
        val context = context ?: return
        this.context = null
        handler.removeCallbacks(safetyStop)

        volumeReceiver?.let { runCatching { context.unregisterReceiver(it) } }
        volumeReceiver = null

        player?.let { runCatching { it.stop() }; it.release() }
        player = null
        tone?.let { runCatching { it.stopTone() }; it.release() }
        tone = null
        abandonFocus(context)

        vibrator?.cancel()
        vibrator = null
        torch?.stop()
        torch = null

        context.getSystemService(NotificationManager::class.java)?.cancel(NOTIFICATION_ID)
    }

    private fun playSound(context: Context): Boolean {
        requestFocus(context)
        for (uri in soundCandidates()) {
            val started = startPlayer(context, uri)
            if (started != null) {
                player = started
                return true
            }
        }

        val generator = runCatching { ToneGenerator(AudioManager.STREAM_ALARM, ToneGenerator.MAX_VOLUME) }.getOrNull()
            ?: return false
        if (!generator.startTone(ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK)) {
            generator.release()
            return false
        }

        tone = generator
        return true
    }

    private fun soundCandidates(): List<Uri> = listOfNotNull(
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
    )

    private fun startPlayer(context: Context, uri: Uri): MediaPlayer? {
        val player = MediaPlayer()
        return try {
            player.setAudioAttributes(alarmAttributes)
            player.setDataSource(context, uri)
            player.isLooping = true
            player.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK)
            player.prepare()
            player.start()
            player
        } catch (error: Exception) {
            player.release()
            null
        }
    }

    @Suppress("DEPRECATION")
    private fun requestFocus(context: Context) {
        val audio = context.getSystemService(AudioManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(alarmAttributes)
                .build()
            audio.requestAudioFocus(request)
            focusRequest = request
            return
        }

        audio.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
    }

    @Suppress("DEPRECATION")
    private fun abandonFocus(context: Context) {
        val audio = context.getSystemService(AudioManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audio.abandonAudioFocusRequest(it) }
            focusRequest = null
            return
        }

        audio.abandonAudioFocus(null)
    }

    @Suppress("DEPRECATION")
    private fun vibrate(context: Context) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            context.getSystemService(Vibrator::class.java)
        }
        if (vibrator == null || !vibrator.hasVibrator()) {
            return
        }

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> vibrator.vibrate(
                VibrationEffect.createWaveform(VIBRATION, 0),
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM),
            )
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ->
                vibrator.vibrate(VibrationEffect.createWaveform(VIBRATION, 0), alarmAttributes)
            else -> vibrator.vibrate(VIBRATION, 0, alarmAttributes)
        }
        this.vibrator = vibrator
    }

    /**
     * Apps can't read volume keys in the background, but Android broadcasts
     * every volume change. One that Ferret didn't make is a key press.
     */
    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    private fun watchVolumeKeys(context: Context) {
        volumeKeys.ownChange(SystemClock.elapsedRealtime())
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (volumeKeys.isKeyPress(SystemClock.elapsedRealtime())) {
                    stop(REASON_VOLUME_KEY)
                }
            }
        }
        val filter = IntentFilter(VOLUME_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
        volumeReceiver = receiver
    }

    @Suppress("DEPRECATION")
    private fun postNotification(context: Context, alert: PlatformAlert) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ensureChannel(manager)
            Notification.Builder(context, CHANNEL_ID)
                .setTimeoutAfter((alert.maxSeconds + 5) * 1000L)
        } else {
            Notification.Builder(context)
                .setPriority(Notification.PRIORITY_MAX)
                .setSound(null)
                .setVibrate(null)
        }

        val found = broadcast(context, ACTION_FOUND, 1)
        builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(alert.title)
            .setContentText(alert.body)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setDeleteIntent(broadcast(context, ACTION_DISMISSED, 2))
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(context, android.R.drawable.ic_lock_idle_alarm),
                    alert.foundItLabel,
                    found,
                ).build(),
            )

        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            val open = PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            builder.setContentIntent(open).setFullScreenIntent(open, true)
        }

        runCatching { manager.notify(NOTIFICATION_ID, builder.build()) }
    }

    /** No channel sound: the plugin plays its own tone on the alarm stream. */
    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || manager.getNotificationChannel(CHANNEL_ID) != null) {
            return
        }

        val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH).apply {
            setSound(null, null)
            enableVibration(false)
            setBypassDnd(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun broadcast(context: Context, action: String, requestCode: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, FindActionReceiver::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}
