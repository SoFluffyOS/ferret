package io.sofluffy.ferret_calls

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager

/** Answers, ends, silences and places calls through Telecom. */
internal class CallControl(private val context: Context) {
    private var ringerMuted = false

    @SuppressLint("MissingPermission")
    fun answer(): PlatformCallResult {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return PlatformCallResult.UNSUPPORTED
        }

        if (!CallPermissions.canAnswer(context)) {
            return PlatformCallResult.PERMISSION_MISSING
        }

        val telecom = telecom() ?: return PlatformCallResult.FAILED
        return guarded {
            @Suppress("DEPRECATION")
            telecom.acceptRingingCall()
            PlatformCallResult.OK
        }
    }

    @SuppressLint("MissingPermission")
    fun end(): PlatformCallResult {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return PlatformCallResult.UNSUPPORTED
        }

        if (!CallPermissions.canAnswer(context)) {
            return PlatformCallResult.PERMISSION_MISSING
        }

        val telecom = telecom() ?: return PlatformCallResult.FAILED
        return guarded {
            @Suppress("DEPRECATION")
            val ended = telecom.endCall()
            if (ended) PlatformCallResult.OK else PlatformCallResult.FAILED
        }
    }

    /**
     * `TelecomManager.silenceRinger` only works for the default dialer or a
     * privileged app, so the fallback mutes the ring stream until the call
     * stops ringing ([restoreRinger]). Android refuses the mute when it would
     * change Do Not Disturb without notification policy access.
     */
    @SuppressLint("MissingPermission")
    fun silenceRinger(): PlatformCallResult {
        val silencedByTelecom = runCatching { telecom()?.silenceRinger() != null }.getOrDefault(false)
        if (silencedByTelecom) {
            return PlatformCallResult.OK
        }

        val audio = context.getSystemService(AudioManager::class.java)
            ?: return PlatformCallResult.FAILED
        return try {
            audio.adjustStreamVolume(AudioManager.STREAM_RING, AudioManager.ADJUST_MUTE, 0)
            ringerMuted = true
            PlatformCallResult.OK
        } catch (_: SecurityException) {
            PlatformCallResult.FAILED
        }
    }

    /** Undoes the mute of [silenceRinger] once the call no longer rings. */
    fun restoreRinger() {
        if (!ringerMuted) {
            return
        }

        ringerMuted = false
        val audio = context.getSystemService(AudioManager::class.java) ?: return
        runCatching {
            audio.adjustStreamVolume(AudioManager.STREAM_RING, AudioManager.ADJUST_UNMUTE, 0)
        }
    }

    /**
     * Telecom starts the call and shows the phone's own call screen, so this
     * works while the app is in the background.
     */
    @SuppressLint("MissingPermission")
    fun dial(number: String): PlatformCallResult {
        if (number.isBlank()) {
            return PlatformCallResult.FAILED
        }

        if (!CallPermissions.isGranted(context, Manifest.permission.CALL_PHONE)) {
            return PlatformCallResult.PERMISSION_MISSING
        }

        val telecom = telecom() ?: return PlatformCallResult.FAILED
        val extras = Bundle()
        outgoingAccount(telecom)?.let { account ->
            extras.putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, account)
        }

        return guarded {
            telecom.placeCall(Uri.fromParts(PhoneAccount.SCHEME_TEL, number, null), extras)
            PlatformCallResult.OK
        }
    }

    /**
     * The SIM to call with: the person's default one. With "ask every time"
     * on a dual SIM phone nobody is at the phone to answer the question, so
     * the first SIM is used. Null lets Telecom decide.
     */
    @SuppressLint("MissingPermission")
    private fun outgoingAccount(telecom: TelecomManager): PhoneAccountHandle? {
        if (!CallPermissions.isGranted(context, Manifest.permission.READ_PHONE_STATE)) {
            return null
        }

        return runCatching {
            telecom.getDefaultOutgoingPhoneAccount(PhoneAccount.SCHEME_TEL)
                ?: telecom.callCapablePhoneAccounts.takeIf { it.size > 1 }?.firstOrNull()
        }.getOrNull()
    }

    private fun telecom(): TelecomManager? = context.getSystemService(TelecomManager::class.java)

    private fun guarded(action: () -> PlatformCallResult): PlatformCallResult =
        try {
            action()
        } catch (_: SecurityException) {
            PlatformCallResult.PERMISSION_MISSING
        } catch (_: RuntimeException) {
            PlatformCallResult.FAILED
        }
}
