package io.sofluffy.ferret_calls

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import androidx.annotation.RequiresApi

/**
 * Watches the phone's call state. The state comes from `TelephonyCallback`
 * (Android 12+) or `PhoneStateListener`; the number comes from the
 * `PHONE_STATE` broadcast, since `TelephonyCallback` no longer carries it.
 *
 * The default `TelephonyManager` reports calls on every SIM, so dual SIM
 * phones need nothing extra.
 */
internal class CallMonitor(
    private val context: Context,
    private val onEvent: (PlatformPhoneState, String?) -> Unit,
) {
    private val merger = PhoneEventMerger(onEvent)
    private var callback: Any? = null
    private var legacyListener: PhoneStateListener? = null
    private var receiver: BroadcastReceiver? = null

    val isRunning: Boolean
        get() = receiver != null

    /** Returns false when `READ_PHONE_STATE` is missing or there is no telephony. */
    fun start(): Boolean {
        if (isRunning) {
            return true
        }

        if (!CallPermissions.isGranted(context, Manifest.permission.READ_PHONE_STATE)) {
            return false
        }

        val telephony = context.getSystemService(TelephonyManager::class.java) ?: return false
        merger.reset()

        try {
            registerStateListener(telephony)
        } catch (_: SecurityException) {
            return false
        }

        registerNumberReceiver()
        return true
    }

    fun stop() {
        val telephony = context.getSystemService(TelephonyManager::class.java)
        receiver?.let { runCatching { context.unregisterReceiver(it) } }
        receiver = null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (callback as? TelephonyCallback)?.let { registered ->
                runCatching { telephony?.unregisterTelephonyCallback(registered) }
            }
        }
        callback = null

        legacyListener?.let { listener ->
            @Suppress("DEPRECATION")
            runCatching { telephony?.listen(listener, PhoneStateListener.LISTEN_NONE) }
        }
        legacyListener = null
    }

    private fun registerStateListener(telephony: TelephonyManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val stateCallback = StateCallback { state -> merger.accept(stateOf(state), null) }
            telephony.registerTelephonyCallback(context.mainExecutor, stateCallback)
            callback = stateCallback
            return
        }

        @Suppress("DEPRECATION")
        val listener = object : PhoneStateListener() {
            @Deprecated("Replaced by TelephonyCallback on Android 12+")
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                merger.accept(stateOf(state), phoneNumber)
            }
        }
        @Suppress("DEPRECATION")
        telephony.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
        legacyListener = listener
    }

    /**
     * Android sends the broadcast twice to apps that hold `READ_CALL_LOG`:
     * once without the number and once with it. The merger keeps the number.
     */
    private fun registerNumberReceiver() {
        val numberReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val state = when (intent.getStringExtra(TelephonyManager.EXTRA_STATE)) {
                    TelephonyManager.EXTRA_STATE_RINGING -> PlatformPhoneState.RINGING
                    TelephonyManager.EXTRA_STATE_OFFHOOK -> PlatformPhoneState.OFF_HOOK
                    TelephonyManager.EXTRA_STATE_IDLE -> PlatformPhoneState.IDLE
                    else -> return
                }

                @Suppress("DEPRECATION")
                val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                merger.accept(state, number)
            }
        }
        val filter = IntentFilter(TelephonyManager.ACTION_PHONE_STATE_CHANGED)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(numberReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(numberReceiver, filter)
        }
        receiver = numberReceiver
    }

    private fun stateOf(state: Int): PlatformPhoneState = when (state) {
        TelephonyManager.CALL_STATE_RINGING -> PlatformPhoneState.RINGING
        TelephonyManager.CALL_STATE_OFFHOOK -> PlatformPhoneState.OFF_HOOK
        else -> PlatformPhoneState.IDLE
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private class StateCallback(private val onState: (Int) -> Unit) :
        TelephonyCallback(),
        TelephonyCallback.CallStateListener {
        override fun onCallStateChanged(state: Int) = onState(state)
    }
}
