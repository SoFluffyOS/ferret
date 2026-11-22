package io.sofluffy.ferret_messages

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.atomic.AtomicInteger

/**
 * Sends SMS through [SmsManager] and waits for the radio to confirm each
 * part. Android writes what a non-default app sends into the SMS provider
 * itself, so the message shows up in the conversation like any other.
 */
class SmsSender(private val context: Context, private val reader: SmsReader) {
    suspend fun send(threadId: Long, addresses: List<String>, text: String): PlatformSendResult {
        val recipients = when (threadId > 0) {
            true -> reader.recipientsOf(threadId)
            false -> addresses.map { it.trim() }.filter { it.isNotEmpty() }.distinct()
        }
        if (recipients.isEmpty() || text.isBlank()) {
            return PlatformSendResult(failure = PlatformSendFailure.NO_RECIPIENT, threadId = threadId)
        }

        if (recipients.size > 1) {
            return PlatformSendResult(failure = PlatformSendFailure.GROUP, threadId = threadId)
        }

        val address = recipients.first()
        val manager = smsManager(subscriptionFor(threadId))
        val parts = manager.divideMessage(text)
        val token = nextToken.incrementAndGet()
        val action = "$SENT_ACTION.$token"
        val results = ArrayList<PlatformSendFailure>()
        val done = CompletableDeferred<Unit>()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                synchronized(results) {
                    results.add(MessageRules.sendFailureOf(resultCode))
                    if (results.size >= parts.size) {
                        done.complete(Unit)
                    }
                }
            }
        }

        register(receiver, IntentFilter(action))
        try {
            val sentIntents = ArrayList(parts.indices.map { pendingBroadcast(action, token * 100 + it) })
            val deliveredIntents = ArrayList(
                parts.indices.map { pendingBroadcast(DELIVERED_ACTION, token * 100 + it) },
            )
            manager.sendMultipartTextMessage(address, null, parts, sentIntents, deliveredIntents)

            val confirmed = withTimeoutOrNull(SEND_TIMEOUT_MS) { done.await() }
            val failure = when (confirmed) {
                null -> PlatformSendFailure.TIMEOUT
                else -> synchronized(results) { MessageRules.combine(results) }
            }
            return PlatformSendResult(failure = failure, threadId = threadFor(threadId, address))
        } catch (_: SecurityException) {
            return PlatformSendResult(failure = PlatformSendFailure.NO_ACCESS, threadId = threadId)
        } catch (_: IllegalArgumentException) {
            return PlatformSendResult(failure = PlatformSendFailure.NO_RECIPIENT, threadId = threadId)
        } finally {
            runCatching { context.unregisterReceiver(receiver) }
        }
    }

    private fun threadFor(threadId: Long, address: String): Long {
        if (threadId > 0) {
            return threadId
        }

        return runCatching { Telephony.Threads.getOrCreateThreadId(context, address) }.getOrDefault(0L)
    }

    private fun pendingBroadcast(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(action).setPackage(context.packageName)
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun register(receiver: BroadcastReceiver, filter: IntentFilter) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            return
        }

        context.registerReceiver(receiver, filter)
    }

    /**
     * A reply leaves from the SIM the conversation last used, like the
     * phone's own messaging app does, as long as that SIM is still in the
     * phone. Otherwise the phone's default SIM for texts.
     */
    private fun subscriptionFor(threadId: Long): Int? {
        if (threadId <= 0 || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return null
        }

        val subscription = reader.lastSubscriptionOf(threadId) ?: return null
        val inPhone = runCatching { SubscriptionManager.getSlotIndex(subscription) >= 0 }.getOrDefault(false)
        return subscription.takeIf { inPhone }
    }

    @Suppress("DEPRECATION")
    private fun smsManager(subscription: Int?): SmsManager {
        if (subscription != null) {
            return when (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                true -> context.getSystemService(SmsManager::class.java)
                    ?.createForSubscriptionId(subscription)
                    ?: SmsManager.getSmsManagerForSubscriptionId(subscription)
                false -> SmsManager.getSmsManagerForSubscriptionId(subscription)
            }
        }

        return when (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            true -> context.getSystemService(SmsManager::class.java) ?: SmsManager.getDefault()
            false -> SmsManager.getDefault()
        }
    }

    companion object {
        const val SENT_ACTION = "io.sofluffy.ferret_messages.SENT"

        /** Delivery reports change the message's status; the watcher picks them up. */
        const val DELIVERED_ACTION = "io.sofluffy.ferret_messages.DELIVERED"

        private const val SEND_TIMEOUT_MS = 60_000L
        private val nextToken = AtomicInteger(0)
    }
}
