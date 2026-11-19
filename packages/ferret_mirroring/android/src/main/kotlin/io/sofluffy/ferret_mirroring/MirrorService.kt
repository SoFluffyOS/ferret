package io.sofluffy.ferret_mirroring

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log

/**
 * Runs while the screen is shared, with the ongoing "Sharing screen with
 * MacBook · Stop" notice that can't be swiped away. Android requires a
 * foreground service of type mediaProjection for the whole capture.
 */
class MirrorService : Service() {
    private val main = Handler(Looper.getMainLooper())
    private var grant: Intent? = null
    private var grantCode = 0
    private var session: ScreenCaptureSession? = null
    private var finished = false

    /** Gives up when Dart never starts the capture after the owner said yes. */
    private val unusedGrant = Runnable { finish() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_ARM -> arm(intent)
            ACTION_STOP -> stopByUser()
            else -> finish()
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        release()
        super.onDestroy()
    }

    /** Starts capturing with the grant this service was armed with, used once. */
    internal fun begin(options: NativeCaptureOptions, listener: MirrorBridge.Listener): Boolean {
        val data = grant
        grant = null
        main.removeCallbacks(unusedGrant)
        if (data == null || session != null || finished) {
            return false
        }

        try {
            val manager = getSystemService(MediaProjectionManager::class.java)
            val projection = manager?.getMediaProjection(grantCode, data)
            if (projection == null) {
                finish()
                return false
            }

            val created = ScreenCaptureSession(this, projection, options, listener)
            session = created
            created.start()
            return true
        } catch (error: Exception) {
            Log.w(TAG, "Screen capture did not start", error)
            finish()
            return false
        }
    }

    fun requestKeyframe() {
        session?.requestKeyframe()
    }

    fun setBitrate(bitrate: Int) {
        session?.setBitrate(bitrate)
    }

    /** Ends the capture and takes the notice away. */
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
        @Suppress("DEPRECATION")
        val data = intent.getParcelableExtra<Intent>(EXTRA_GRANT)
        val title = intent.getStringExtra(EXTRA_TITLE).orEmpty()
        val body = intent.getStringExtra(EXTRA_BODY).orEmpty()
        val stopLabel = intent.getStringExtra(EXTRA_STOP_LABEL).orEmpty()
        val channelName = intent.getStringExtra(EXTRA_CHANNEL_NAME).orEmpty()

        try {
            val notice = notice(title, body, stopLabel, channelName)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTICE_ID, notice, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
            } else {
                startForeground(NOTICE_ID, notice)
            }
        } catch (error: Exception) {
            Log.w(TAG, "Could not start the screen sharing service", error)
            ProjectionConsent.complete(this, NativeConsentResult.FAILED)
            finish()
            return
        }

        if (data == null) {
            ProjectionConsent.complete(this, NativeConsentResult.FAILED)
            finish()
            return
        }

        grant = data
        grantCode = intent.getIntExtra(EXTRA_GRANT_CODE, 0)
        MirrorBridge.service = this
        main.postDelayed(unusedGrant, UNUSED_GRANT_MS)
        ProjectionConsent.complete(this, NativeConsentResult.GRANTED)
    }

    private fun stopByUser() {
        val wasSharing = session != null
        finish()
        if (wasSharing) {
            MirrorBridge.listener?.onEnded(NativeCaptureEnd.STOPPED_BY_USER)
        }
    }

    private fun release() {
        main.removeCallbacks(unusedGrant)
        grant = null
        session?.release()
        session = null
        if (MirrorBridge.service === this) {
            MirrorBridge.service = null
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
            Intent(this, MirrorService::class.java).setAction(ACTION_STOP),
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
        private const val TAG = "FerretMirroring"
        private const val CHANNEL = "ferret_mirroring_sharing"
        private const val NOTICE_ID = 7401
        private const val UNUSED_GRANT_MS = 15_000L
        private const val ACTION_ARM = "io.sofluffy.ferret_mirroring.ARM"
        private const val ACTION_STOP = "io.sofluffy.ferret_mirroring.STOP"
        private const val EXTRA_GRANT = "grant"
        private const val EXTRA_GRANT_CODE = "grant_code"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"
        private const val EXTRA_STOP_LABEL = "stop_label"
        private const val EXTRA_CHANNEL_NAME = "channel_name"

        /** Starts the service in the foreground with the owner's grant. */
        fun arm(context: Context, grantCode: Int, grant: Intent, texts: NativeConsentTexts): Boolean {
            val intent = Intent(context, MirrorService::class.java)
                .setAction(ACTION_ARM)
                .putExtra(EXTRA_GRANT, grant)
                .putExtra(EXTRA_GRANT_CODE, grantCode)
                .putExtra(EXTRA_TITLE, texts.sharingTitle)
                .putExtra(EXTRA_BODY, texts.sharingBody)
                .putExtra(EXTRA_STOP_LABEL, texts.stopLabel)
                .putExtra(EXTRA_CHANNEL_NAME, texts.sharingChannelName)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }

                return true
            } catch (error: RuntimeException) {
                Log.w(TAG, "Could not start the screen sharing service", error)
                return false
            }
        }
    }
}
