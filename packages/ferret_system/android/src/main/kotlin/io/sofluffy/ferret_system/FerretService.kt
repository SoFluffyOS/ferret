package io.sofluffy.ferret_system

import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * Keeps the process, and with it the Flutter engine, alive while the app is
 * closed. Android shows its notification for as long as it runs.
 */
class FerretService : Service() {
    private var inForeground = false

    override fun onCreate() {
        super.onCreate()
        ServiceNotification.hidden = false
        running = this
        ServiceStops.onServiceCreated(this)
        FerretRuntime.ensureEngine(this)
        ReconnectAlarm.update(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Android lets a service that is already in the foreground skip
        // startForeground, which would post a swiped-away notice again.
        if (ServiceNotification.shouldPost(inForeground) && !enterForeground()) {
            stopSelf()
            return START_NOT_STICKY
        }

        when (intent?.action) {
            ACTION_PAUSE -> FerretRuntime.setPauseFromSystem(
                this,
                PauseMessage(paused = true, untilMs = System.currentTimeMillis() + PAUSE_MS),
            )
            ACTION_RESUME -> FerretRuntime.setPauseFromSystem(this, PauseMessage(paused = false))
        }

        return START_STICKY
    }

    override fun onDestroy() {
        ServiceStops.onServiceStopped(this)
        if (running === this) {
            running = null
        }
        ReconnectAlarm.update(this)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /** The notice follows a language picked for Ferret in Android's settings. */
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        refreshNotification(this)
    }

    private fun enterForeground(): Boolean {
        val notification = ServiceNotification.build(this)
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    ServiceNotification.ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                )
            } else {
                startForeground(ServiceNotification.ID, notification)
            }
            inForeground = true
            true
        } catch (error: RuntimeException) {
            Log.w(TAG, "Android did not let the service run in the foreground", error)
            false
        }
    }

    companion object {
        const val ACTION_PAUSE = "io.sofluffy.ferret_system.PAUSE"
        const val ACTION_RESUME = "io.sofluffy.ferret_system.RESUME"

        private const val TAG = "FerretService"
        private const val PAUSE_MS = 60L * 60 * 1000

        private var running: FerretService? = null

        val isRunning: Boolean
            get() = running != null

        /** Returns false when Android refused, such as from the background on 12+. */
        fun start(context: Context): Boolean {
            val intent = Intent(context, FerretService::class.java)
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                true
            } catch (error: RuntimeException) {
                Log.w(TAG, "Could not start the service", error)
                false
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, FerretService::class.java))
        }

        fun refreshNotification(context: Context) {
            val service = running ?: return
            if (!ServiceNotification.shouldPost(service.inForeground)) {
                return
            }
            val manager = service.getSystemService(NotificationManager::class.java) ?: return
            manager.notify(ServiceNotification.ID, ServiceNotification.build(context))
        }
    }
}
