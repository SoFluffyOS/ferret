package io.sofluffy.ferret_calls

import android.Manifest
import android.content.Context
import android.provider.CallLog

/** Reads the phone's recent calls. */
internal class CallHistory(
    private val context: Context,
    private val contacts: ContactLookup,
) {
    /** Newest first. Empty without `READ_CALL_LOG`. */
    fun recent(limit: Int): List<PlatformCallLogEntry> {
        if (limit <= 0 || !CallPermissions.isGranted(context, Manifest.permission.READ_CALL_LOG)) {
            return emptyList()
        }

        // Voicemail and blocked rows are skipped, so read a few more than asked.
        val rowLimit = limit + limit / 2
        val uri = CallLog.Calls.CONTENT_URI.buildUpon()
            .appendQueryParameter(CallLog.Calls.LIMIT_PARAM_KEY, rowLimit.toString())
            .build()
        val columns = arrayOf(
            CallLog.Calls._ID,
            CallLog.Calls.NUMBER,
            CallLog.Calls.CACHED_NAME,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
        )
        val names = HashMap<String, String>()
        val entries = ArrayList<PlatformCallLogEntry>(limit)

        runCatching {
            context.contentResolver.query(uri, columns, null, null, "${CallLog.Calls.DATE} DESC")
                ?.use { cursor ->
                    while (entries.size < limit && cursor.moveToNext()) {
                        val type = CallLogTypes.fromAndroid(cursor.getInt(3)) ?: continue
                        val number = cursor.getString(1).orEmpty()
                        val cachedName = cursor.getString(2).orEmpty()
                        entries.add(
                            PlatformCallLogEntry(
                                id = cursor.getLong(0).toString(),
                                number = number,
                                name = cachedName.ifBlank { nameOf(number, names) },
                                type = type,
                                dateMs = cursor.getLong(4),
                                durationSeconds = cursor.getLong(5),
                            ),
                        )
                    }
                }
        }

        return entries
    }

    /** The call log's cached name is often stale or empty; ask the contacts once per number. */
    private fun nameOf(number: String, names: MutableMap<String, String>): String {
        if (number.isBlank()) {
            return ""
        }

        return names.getOrPut(number) { contacts.find(number, withPhoto = false)?.name.orEmpty() }
    }
}

/** Maps `CallLog.Calls.TYPE` values. */
internal object CallLogTypes {
    /** Null for rows that are not calls a person made or got, such as voicemail. */
    fun fromAndroid(type: Int): PlatformCallLogType? = when (type) {
        CallLog.Calls.INCOMING_TYPE, CallLog.Calls.ANSWERED_EXTERNALLY_TYPE ->
            PlatformCallLogType.INCOMING
        CallLog.Calls.OUTGOING_TYPE -> PlatformCallLogType.OUTGOING
        CallLog.Calls.MISSED_TYPE -> PlatformCallLogType.MISSED
        CallLog.Calls.REJECTED_TYPE -> PlatformCallLogType.REJECTED
        else -> null
    }
}
