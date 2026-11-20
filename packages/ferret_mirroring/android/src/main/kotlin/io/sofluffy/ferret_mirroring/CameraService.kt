package io.sofluffy.ferret_mirroring

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * Runs while a computer uses this phone's camera, with the ongoing
 * "Camera on for MacBook · Stop" notice that can't be swiped away.
 * Android 14 and newer only keep a camera and a microphone open from a
 * foreground service of those types.
 */
class CameraService : Service() {
    private var session: CameraSession? = null
    private var finished = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> arm(intent)
            ACTION_STOP -> stopByUser()
            else -> finish()
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        release()
        super.onDestroy()
    }

    /** Opens the camera. Null when it couldn't; the service is over then. */
    internal fun begin(options: NativeCameraOptions, listener: CameraSession.Listener): NativeCameraLens? {
        if (session != null || finished) {
            return null
        }

        try {
            val created = CameraSession(this, options, listener)
            val lens = created.start()
            session = created
            return lens
        } catch (error: Exception) {
            Log.w(TAG, "The camera did not start", error)
            finish()
            return null
        }
    }

    internal fun setLens(lens: NativeCameraLens): NativeCameraLens? = session?.setLens(lens)

    fun requestKeyframe() {
        session?.requestKeyframe()
    }

    fun setBitrate(bitrate: Int) {
        session?.setBitrate(bitrate)
    }

    /** Closes the camera and takes the notice away. */
    fun finish() {
        if (finished) {
            return
        }

        finished = true
        release()
        @Suppress("DEPRECATION")
        stopForeground(true)
        stopSelf()
    }

    private fun arm(intent: Intent) {
        val title = intent.getStringExtra(EXTRA_TITLE).orEmpty()
        val body = intent.getStringExtra(EXTRA_BODY).orEmpty()
        val stopLabel = intent.getStringExtra(EXTRA_STOP_LABEL).orEmpty()
        val channelName = intent.getStringExtra(EXTRA_CHANNEL_NAME).orEmpty()
        val withMicrophone = intent.getBooleanExtra(EXTRA_MICROPHONE, false)

        try {
            val notice = notice(title, body, stopLabel, channelName)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                startForeground(NOTICE_ID, notice, serviceTypes(withMicrophone))
            } else {
                startForeground(NOTICE_ID, notice)
            }
        } catch (error: Exception) {
            // Android 14 refuses a camera started while the app is in the background.
            Log.w(TAG, "Could not start the camera service", error)
            finish()
            CameraBridge.armed(null)
            return
        }

        CameraBridge.service = this
        CameraBridge.armed(this)
    }

    private fun serviceTypes(withMicrophone: Boolean): Int {
        val microphone = withMicrophone &&
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return 0
        }

        if (!microphone) {
            return ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA
        }

        return ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
    }

    private fun stopByUser() {
        val wasOn = session != null
        finish()
        if (wasOn) {
            CameraBridge.listener?.onEnded(NativeCaptureEnd.STOPPED_BY_USER)
        }
    }

    private fun release() {
        session?.release()
        session = null
        if (CameraBridge.service === this) {
            CameraBridge.service = null
        }
    }

    private fun notice(title: String, body: String, stopLabel: String, channelName: String): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(
                NotificationChannel(CHANNEL, channelName, NotificationManager.IMPORTANCE_LOW),
            )
        }

        val stop = PendingIntent.getService(
            this,
            NOTICE_ID,
            Intent(this, CameraService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = MirrorNotices.builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ferret_mirroring_status)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setContentIntent(packageManager.getLaunchIntentForPackage(packageName)?.let { launch ->
                PendingIntent.getActivity(this, 0, launch, PendingIntent.FLAG_IMMUTABLE)
            })
            .addAction(Notification.Action.Builder(null, stopLabel, stop).build())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }

        return builder.build()
    }

    companion object {
        private const val TAG = "FerretCamera"
        private const val CHANNEL = "ferret_mirroring_camera"
        private const val NOTICE_ID = 7404
        private const val ACTION_START = "io.sofluffy.ferret_mirroring.CAMERA_START"
        private const val ACTION_STOP = "io.sofluffy.ferret_mirroring.CAMERA_STOP"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"
        private const val EXTRA_STOP_LABEL = "stop_label"
        private const val EXTRA_CHANNEL_NAME = "channel_name"
        private const val EXTRA_MICROPHONE = "microphone"

        /** Starts the service in the foreground. False when Android refused right away. */
        fun start(context: Context, texts: NativeCameraTexts, withMicrophone: Boolean): Boolean {
            val intent = Intent(context, CameraService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_TITLE, texts.title)
                .putExtra(EXTRA_BODY, texts.body)
                .putExtra(EXTRA_STOP_LABEL, texts.stopLabel)
                .putExtra(EXTRA_CHANNEL_NAME, texts.channelName)
                .putExtra(EXTRA_MICROPHONE, withMicrophone)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }

                return true
            } catch (error: RuntimeException) {
                Log.w(TAG, "Could not start the camera service", error)
                return false
            }
        }
    }
}

/** Joins the camera service, which Android starts on its own, with the plugin that talks to Dart. */
internal object CameraBridge {
    @Volatile
    var listener: CameraSession.Listener? = null

    /** The running service, from the moment it is in the foreground to the end of the camera. */
    @Volatile
    var service: CameraService? = null

    private var onArmed: ((CameraService?) -> Unit)? = null

    /** Hears once whether the service that was just started reached the foreground. */
    fun whenArmed(callback: (CameraService?) -> Unit) {
        armed(null)
        onArmed = callback
    }

    fun armed(service: CameraService?) {
        val callback = onArmed
        onArmed = null
        callback?.invoke(service)
    }
}
