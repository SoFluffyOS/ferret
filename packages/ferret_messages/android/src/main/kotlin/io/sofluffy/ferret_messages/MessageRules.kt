package io.sofluffy.ferret_messages

/** Pure rules for reading the Telephony providers, kept apart so they can be unit tested. */
object MessageRules {
    /** `Telephony.Sms.MESSAGE_TYPE_*` to a kind, or null for drafts and unknown types. */
    fun smsKind(type: Int): PlatformMessageKind? = when (type) {
        1 -> PlatformMessageKind.INBOX
        2 -> PlatformMessageKind.SENT
        4 -> PlatformMessageKind.OUTBOX
        5 -> PlatformMessageKind.FAILED
        6 -> PlatformMessageKind.QUEUED
        else -> null
    }

    /** `Telephony.Mms.MESSAGE_BOX_*` to a kind, or null for drafts and unknown boxes. */
    fun mmsKind(box: Int): PlatformMessageKind? = when (box) {
        1 -> PlatformMessageKind.INBOX
        2 -> PlatformMessageKind.SENT
        4 -> PlatformMessageKind.OUTBOX
        5 -> PlatformMessageKind.FAILED
        else -> null
    }

    /** MMS dates are stored in seconds, SMS dates in milliseconds. */
    fun mmsDateMs(seconds: Long): Long = seconds * 1000

    /** The MMS `date` bound (seconds) that keeps messages at or before [beforeMs]. */
    fun mmsSecondsAtOrBefore(beforeMs: Long): Long = Math.floorDiv(beforeMs, 1000L)

    fun smsId(rowId: Long): String = "sms:$rowId"

    fun mmsId(rowId: Long): String = "mms:$rowId"

    /** The MMS row id in an id made by [mmsId], or null. */
    fun mmsRowId(messageId: String): Long? = messageId.removePrefix("mms:")
        .takeIf { messageId.startsWith("mms:") }
        ?.toLongOrNull()

    /** A row found while paging, before its details are read. */
    data class Row(val id: String, val dateMs: Long)

    /**
     * Picks one page out of SMS and MMS rows that are each sorted newest
     * first: drops [skipIds], merges, and keeps [limit]. Ties keep a stable
     * order by id so pages never shuffle.
     */
    fun page(sms: List<Row>, mms: List<Row>, skipIds: Set<String>, limit: Int): Pair<List<Row>, Boolean> {
        val merged = (sms + mms)
            .filter { it.id !in skipIds }
            .sortedWith(compareByDescending<Row> { it.dateMs }.thenByDescending { it.id })
        return merged.take(limit) to (merged.size > limit)
    }

    /** `recipient_ids` of a thread, such as "3 7". */
    fun recipientIds(raw: String?): List<Long> =
        raw.orEmpty().split(' ').mapNotNull { it.trim().toLongOrNull() }

    /** A snippet short enough for a conversation list. */
    fun snippet(raw: String?, max: Int = 200): String {
        val text = raw.orEmpty().trim().replace(Regex("\\s+"), " ")
        if (text.length <= max) {
            return text
        }

        return text.take(max - 1) + "…"
    }

    /** The send outcome of one part, from a `sentIntent` result code. */
    fun sendFailureOf(resultCode: Int): PlatformSendFailure = when (resultCode) {
        android.app.Activity.RESULT_OK -> PlatformSendFailure.NONE
        // SmsManager.RESULT_ERROR_RADIO_OFF, RESULT_ERROR_NO_SERVICE
        2, 4 -> PlatformSendFailure.NO_SERVICE
        else -> PlatformSendFailure.OTHER
    }

    /** The first failure among the parts of one message, or NONE. */
    fun combine(failures: List<PlatformSendFailure>): PlatformSendFailure =
        failures.firstOrNull { it != PlatformSendFailure.NONE } ?: PlatformSendFailure.NONE
}
