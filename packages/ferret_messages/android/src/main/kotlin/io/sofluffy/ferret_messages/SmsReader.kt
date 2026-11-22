package io.sofluffy.ferret_messages

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony

/**
 * Reads conversations and messages from Android's SMS and MMS providers.
 * Every call runs queries on the caller's thread; call it off the main thread.
 */
class SmsReader(private val context: Context, private val contacts: ContactLookup) {
    private val resolver: ContentResolver
        get() = context.contentResolver

    fun conversations(beforeDateMs: Long, limit: Int): PlatformConversationPage {
        val selection = StringBuilder("${Telephony.Threads.MESSAGE_COUNT} > 0")
        val args = mutableListOf<String>()
        if (beforeDateMs > 0) {
            selection.append(" AND ${Telephony.Threads.DATE} < ?")
            args.add(beforeDateMs.toString())
        }

        val rows = threadRows(selection.toString(), args.toTypedArray(), limit + 1)
        val page = rows.take(limit)
        return PlatformConversationPage(
            conversations = conversationsOf(page),
            hasMore = rows.size > limit,
        )
    }

    fun conversationsById(threadIds: List<Long>): List<PlatformConversation> {
        if (threadIds.isEmpty()) {
            return emptyList()
        }

        val placeholders = threadIds.joinToString(",") { "?" }
        val rows = threadRows(
            "${Telephony.Threads._ID} IN ($placeholders)",
            threadIds.map { it.toString() }.toTypedArray(),
            threadIds.size,
        )
        return conversationsOf(rows)
    }

    fun messages(threadId: Long, beforeDateMs: Long, skipIds: Set<String>, limit: Int): PlatformMessagePage {
        val want = limit + skipIds.size + 1
        val sms = smsRows("${Telephony.Sms.THREAD_ID} = ?", listOf(threadId.toString()), beforeDateMs, want)
        val mms = mmsRows("${Telephony.Mms.THREAD_ID} = ?", listOf(threadId.toString()), beforeDateMs, want)
        val (rows, hasMore) = MessageRules.page(sms.map { it.row }, mms.map { it.row }, skipIds, limit)

        return PlatformMessagePage(messages = detailsOf(rows, sms, mms), hasMore = hasMore)
    }

    fun recent(sinceDateMs: Long, limit: Int): List<PlatformMessage> {
        val sms = smsRows("${Telephony.Sms.DATE} > ?", listOf(sinceDateMs.toString()), 0, limit)
        val mms = mmsRows(
            "${Telephony.Mms.DATE} > ?",
            listOf(Math.floorDiv(sinceDateMs, 1000L).toString()),
            0,
            limit,
        )
        val (rows, _) = MessageRules.page(sms.map { it.row }, mms.map { it.row }, emptySet(), limit)
        return detailsOf(rows, sms, mms)
    }

    fun attachment(messageId: String, partId: String): PlatformAttachmentData? {
        val rowId = MessageRules.mmsRowId(messageId) ?: return null
        val partRow = partId.toLongOrNull() ?: return null
        val mime = resolver.query(
            PART_URI,
            arrayOf(Telephony.Mms.Part.CONTENT_TYPE),
            "${Telephony.Mms.Part._ID} = ? AND ${Telephony.Mms.Part.MSG_ID} = ?",
            arrayOf(partRow.toString(), rowId.toString()),
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return@use null
            }

            cursor.getString(0).orEmpty()
        } ?: return null

        val data = readPart(partRow, MAX_ATTACHMENT_BYTES) ?: return null
        return PlatformAttachmentData(mime = mime, data = data)
    }

    /** The addresses of everyone in [threadId] but the phone's owner. */
    fun recipientsOf(threadId: Long): List<String> {
        val raw = resolver.query(
            THREADS_URI,
            arrayOf(Telephony.Threads.RECIPIENT_IDS),
            "${Telephony.Threads._ID} = ?",
            arrayOf(threadId.toString()),
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return@use null
            }

            cursor.getString(0)
        } ?: return emptyList()

        val addresses = canonicalAddresses()
        return MessageRules.recipientIds(raw).mapNotNull { addresses[it] }
    }

    /**
     * The SIM the newest text in [threadId] used, so a reply goes out the
     * same way on a dual-SIM phone; null when the phone didn't record one.
     */
    fun lastSubscriptionOf(threadId: Long): Int? = runCatching {
        resolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf(Telephony.Sms.SUBSCRIPTION_ID),
            "${Telephony.Sms.THREAD_ID} = ?",
            arrayOf(threadId.toString()),
            "${Telephony.Sms.DATE} DESC",
        )?.use { cursor ->
            when (cursor.moveToFirst() && !cursor.isNull(0)) {
                true -> cursor.getInt(0)
                false -> null
            }
        }
    }.getOrNull()?.takeIf { it >= 0 }

    private data class ThreadRow(
        val id: Long,
        val dateMs: Long,
        val recipientIds: List<Long>,
        val snippet: String,
    )

    private fun threadRows(selection: String, args: Array<String>, max: Int): List<ThreadRow> {
        val projection = arrayOf(
            Telephony.Threads._ID,
            Telephony.Threads.DATE,
            Telephony.Threads.RECIPIENT_IDS,
            Telephony.Threads.SNIPPET,
        )
        val rows = mutableListOf<ThreadRow>()
        resolver.query(THREADS_URI, projection, selection, args, "${Telephony.Threads.DATE} DESC")?.use { cursor ->
            while (rows.size < max && cursor.moveToNext()) {
                rows.add(
                    ThreadRow(
                        id = cursor.getLong(0),
                        dateMs = cursor.getLong(1),
                        recipientIds = MessageRules.recipientIds(cursor.getString(2)),
                        snippet = MessageRules.snippet(cursor.getString(3)),
                    ),
                )
            }
        }

        return rows
    }

    private fun conversationsOf(rows: List<ThreadRow>): List<PlatformConversation> {
        if (rows.isEmpty()) {
            return emptyList()
        }

        val addresses = canonicalAddresses()
        val unread = unreadCounts()
        return rows.map { row ->
            val participants = row.recipientIds
                .mapNotNull { addresses[it] }
                .map { contacts.participant(it) }
            PlatformConversation(
                threadId = row.id,
                participants = participants,
                snippet = row.snippet,
                lastDateMs = row.dateMs,
                unreadCount = (unread[row.id] ?: 0).toLong(),
                isGroup = participants.size > 1,
            )
        }
    }

    private fun canonicalAddresses(): Map<Long, String> {
        val addresses = HashMap<Long, String>()
        resolver.query(CANONICAL_URI, arrayOf("_id", "address"), null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                cursor.getString(1)?.let { addresses[cursor.getLong(0)] = it }
            }
        }

        return addresses
    }

    private fun unreadCounts(): Map<Long, Int> {
        val counts = HashMap<Long, Int>()
        val count = { cursor: Cursor ->
            while (cursor.moveToNext()) {
                val thread = cursor.getLong(0)
                counts[thread] = (counts[thread] ?: 0) + 1
            }
        }
        resolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Sms.THREAD_ID),
            "${Telephony.Sms.READ} = 0",
            null,
            null,
        )?.use(count)
        resolver.query(
            Telephony.Mms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Mms.THREAD_ID),
            "${Telephony.Mms.READ} = 0",
            null,
            null,
        )?.use(count)
        return counts
    }

    private class SmsRow(
        val row: MessageRules.Row,
        val threadId: Long,
        val address: String,
        val body: String,
        val kind: PlatformMessageKind,
        val read: Boolean,
    )

    private class MmsRow(
        val row: MessageRules.Row,
        val rowId: Long,
        val threadId: Long,
        val kind: PlatformMessageKind,
        val read: Boolean,
    )

    private fun smsRows(where: String, whereArgs: List<String>, beforeDateMs: Long, max: Int): List<SmsRow> {
        val selection = StringBuilder(where)
        val args = whereArgs.toMutableList()
        if (beforeDateMs > 0) {
            selection.append(" AND ${Telephony.Sms.DATE} <= ?")
            args.add(beforeDateMs.toString())
        }

        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.THREAD_ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.TYPE,
            Telephony.Sms.READ,
        )
        val rows = mutableListOf<SmsRow>()
        resolver.query(
            Telephony.Sms.CONTENT_URI,
            projection,
            selection.toString(),
            args.toTypedArray(),
            "${Telephony.Sms.DATE} DESC",
        )?.use { cursor ->
            while (rows.size < max && cursor.moveToNext()) {
                val kind = MessageRules.smsKind(cursor.getInt(5)) ?: continue
                rows.add(
                    SmsRow(
                        row = MessageRules.Row(MessageRules.smsId(cursor.getLong(0)), cursor.getLong(4)),
                        threadId = cursor.getLong(1),
                        address = cursor.getString(2).orEmpty(),
                        body = cursor.getString(3).orEmpty(),
                        kind = kind,
                        read = cursor.getInt(6) != 0,
                    ),
                )
            }
        }

        return rows
    }

    private fun mmsRows(where: String, whereArgs: List<String>, beforeDateMs: Long, max: Int): List<MmsRow> {
        // Only sent and downloaded MMS: notifications of undownloaded ones have no content yet.
        val selection = StringBuilder("$where AND ${Telephony.Mms.MESSAGE_TYPE} IN ($M_SEND_REQ, $M_RETRIEVE_CONF)")
        val args = whereArgs.toMutableList()
        if (beforeDateMs > 0) {
            selection.append(" AND ${Telephony.Mms.DATE} <= ?")
            args.add(MessageRules.mmsSecondsAtOrBefore(beforeDateMs).toString())
        }

        val projection = arrayOf(
            Telephony.Mms._ID,
            Telephony.Mms.THREAD_ID,
            Telephony.Mms.DATE,
            Telephony.Mms.MESSAGE_BOX,
            Telephony.Mms.READ,
        )
        val rows = mutableListOf<MmsRow>()
        resolver.query(
            Telephony.Mms.CONTENT_URI,
            projection,
            selection.toString(),
            args.toTypedArray(),
            "${Telephony.Mms.DATE} DESC",
        )?.use { cursor ->
            while (rows.size < max && cursor.moveToNext()) {
                val kind = MessageRules.mmsKind(cursor.getInt(3)) ?: continue
                val rowId = cursor.getLong(0)
                rows.add(
                    MmsRow(
                        row = MessageRules.Row(MessageRules.mmsId(rowId), MessageRules.mmsDateMs(cursor.getLong(2))),
                        rowId = rowId,
                        threadId = cursor.getLong(1),
                        kind = kind,
                        read = cursor.getInt(4) != 0,
                    ),
                )
            }
        }

        return rows
    }

    private fun detailsOf(rows: List<MessageRules.Row>, sms: List<SmsRow>, mms: List<MmsRow>): List<PlatformMessage> {
        val smsById = sms.associateBy { it.row.id }
        val mmsById = mms.associateBy { it.row.id }

        return rows.mapNotNull { row ->
            smsById[row.id]?.let { return@mapNotNull smsMessage(it) }
            mmsById[row.id]?.let { mmsMessage(it) }
        }
    }

    private fun smsMessage(row: SmsRow) = PlatformMessage(
        id = row.row.id,
        threadId = row.threadId,
        senderAddress = when (row.kind) {
            PlatformMessageKind.INBOX -> row.address
            else -> ""
        },
        body = row.body,
        dateMs = row.row.dateMs,
        kind = row.kind,
        attachments = emptyList(),
        read = row.read,
    )

    private fun mmsMessage(row: MmsRow): PlatformMessage {
        val texts = mutableListOf<String>()
        val attachments = mutableListOf<PlatformAttachment>()
        val projection = arrayOf(
            Telephony.Mms.Part._ID,
            Telephony.Mms.Part.CONTENT_TYPE,
            Telephony.Mms.Part.TEXT,
            Telephony.Mms.Part._DATA,
            Telephony.Mms.Part.NAME,
            Telephony.Mms.Part.CONTENT_LOCATION,
        )
        resolver.query(
            PART_URI,
            projection,
            "${Telephony.Mms.Part.MSG_ID} = ?",
            arrayOf(row.rowId.toString()),
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val partId = cursor.getLong(0)
                val mime = cursor.getString(1).orEmpty().lowercase()
                when {
                    mime == "application/smil" -> continue
                    mime == "text/plain" -> {
                        val text = when (cursor.getString(3)) {
                            null -> cursor.getString(2)
                            else -> readPart(partId, MAX_TEXT_BYTES)?.toString(Charsets.UTF_8)
                        }
                        text?.takeIf { it.isNotBlank() }?.let { texts.add(it) }
                    }
                    else -> attachments.add(attachmentOf(partId, mime, cursor.getString(4) ?: cursor.getString(5)))
                }
            }
        }

        return PlatformMessage(
            id = row.row.id,
            threadId = row.threadId,
            senderAddress = when (row.kind) {
                PlatformMessageKind.INBOX -> mmsSender(row.rowId)
                else -> ""
            },
            body = texts.joinToString("\n"),
            dateMs = row.row.dateMs,
            kind = row.kind,
            attachments = attachments,
            read = row.read,
        )
    }

    private fun attachmentOf(partId: Long, mime: String, name: String?): PlatformAttachment {
        if (mime.startsWith("image/")) {
            val bytes = readPart(partId, MAX_ATTACHMENT_BYTES)
            return PlatformAttachment(
                partId = partId.toString(),
                mime = mime,
                size = (bytes?.size ?: 0).toLong(),
                name = name.orEmpty(),
                thumbnailJpeg = bytes?.let { runCatching { Thumbnails.jpeg(it, Thumbnails.PREVIEW_SIDE) }.getOrNull() },
            )
        }

        val size = runCatching {
            resolver.openAssetFileDescriptor(partUri(partId), "r")?.use { it.length }
        }.getOrNull() ?: 0L
        return PlatformAttachment(
            partId = partId.toString(),
            mime = mime,
            size = maxOf(0L, size),
            name = name.orEmpty(),
        )
    }

    private fun mmsSender(rowId: Long): String {
        val uri = Uri.parse("content://mms/$rowId/addr")
        return resolver.query(
            uri,
            arrayOf(Telephony.Mms.Addr.ADDRESS),
            "${Telephony.Mms.Addr.TYPE} = ?",
            arrayOf(PDU_FROM.toString()),
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return@use ""
            }

            cursor.getString(0).orEmpty()
        }.orEmpty()
    }

    private fun readPart(partId: Long, maxBytes: Int): ByteArray? = runCatching {
        resolver.openInputStream(partUri(partId))?.use { input ->
            val bytes = input.readNBytesCompat(maxBytes + 1)
            bytes.takeIf { it.size <= maxBytes }
        }
    }.getOrNull()

    private fun partUri(partId: Long): Uri = Uri.parse("content://mms/part/$partId")

    private fun java.io.InputStream.readNBytesCompat(max: Int): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(16 * 1024)
        while (out.size() < max) {
            val read = read(buffer, 0, minOf(buffer.size, max - out.size()))
            if (read < 0) {
                break
            }

            out.write(buffer, 0, read)
        }

        return out.toByteArray()
    }

    companion object {
        /** Attachments larger than this are not sent to computers. */
        const val MAX_ATTACHMENT_BYTES = 16 * 1024 * 1024
        private const val MAX_TEXT_BYTES = 256 * 1024

        private val THREADS_URI: Uri = Uri.parse("content://mms-sms/conversations?simple=true")
        private val CANONICAL_URI: Uri = Uri.parse("content://mms-sms/canonical-addresses")
        private val PART_URI: Uri = Uri.parse("content://mms/part")

        private const val M_SEND_REQ = 128
        private const val M_RETRIEVE_CONF = 132
        private const val PDU_FROM = 137
    }
}
