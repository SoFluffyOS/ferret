package io.sofluffy.ferret_system

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager

/**
 * Reports network changes and wake-ups, so Ferret reconnects at once
 * instead of waiting for the next discovery round.
 */
class NetworkWatcher(
    private val context: Context,
    private val onChange: (NetworkChange) -> Unit,
) {
    private val main = Handler(Looper.getMainLooper())
    private val connectivity = context.getSystemService(ConnectivityManager::class.java)
    private val addresses = mutableMapOf<Network, List<String>>()
    private val blocked = mutableMapOf<Network, Boolean>()
    private var initialNetwork: Network? = null
    private var watching = false

    private val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            main.post {
                if (network == initialNetwork) {
                    initialNetwork = null
                    return@post
                }

                onChange(NetworkChange.AVAILABLE)
            }
        }

        override fun onLost(network: Network) {
            main.post {
                addresses.remove(network)
                blocked.remove(network)
                onChange(NetworkChange.LOST)
            }
        }

        /**
         * Android cut Ferret off the network (Doze, Data Saver, restricted
         * battery use) and now lets it back on: connections made before are dead.
         */
        override fun onBlockedStatusChanged(network: Network, isBlocked: Boolean) {
            main.post {
                val wasBlocked = blocked.put(network, isBlocked) ?: false
                if (wasBlocked && !isBlocked) {
                    onChange(NetworkChange.AVAILABLE)
                }
            }
        }

        override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) {
            val current = linkProperties.linkAddresses.map { it.toString() }.sorted()
            main.post {
                val previous = addresses.put(network, current)
                if (previous != null && previous != current) {
                    onChange(NetworkChange.CHANGED)
                }
            }
        }
    }

    private val wakeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_ON -> onChange(NetworkChange.WAKE)
                PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED -> {
                    val power = context.getSystemService(PowerManager::class.java)
                    if (power?.isDeviceIdleMode == false) {
                        onChange(NetworkChange.WAKE)
                    }
                }
                PowerManager.ACTION_DEVICE_LIGHT_IDLE_MODE_CHANGED -> {
                    val power = context.getSystemService(PowerManager::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && power?.isDeviceLightIdleMode == false) {
                        onChange(NetworkChange.WAKE)
                    }
                }
            }
        }
    }

    fun start() {
        if (watching) {
            return
        }

        watching = true
        initialNetwork = connectivity?.activeNetwork
        try {
            connectivity?.registerDefaultNetworkCallback(callback)
        } catch (error: RuntimeException) {
            initialNetwork = null
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                addAction(PowerManager.ACTION_DEVICE_LIGHT_IDLE_MODE_CHANGED)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(wakeReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(wakeReceiver, filter)
        }
    }

    fun stop() {
        if (!watching) {
            return
        }

        watching = false
        try {
            connectivity?.unregisterNetworkCallback(callback)
        } catch (error: RuntimeException) {
            // Already unregistered.
        }
        context.unregisterReceiver(wakeReceiver)
        addresses.clear()
        blocked.clear()
    }
}
