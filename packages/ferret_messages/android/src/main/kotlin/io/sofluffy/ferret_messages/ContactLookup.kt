package io.sofluffy.ferret_messages

import android.content.Context
import android.net.Uri
import android.os.SystemClock
import android.provider.ContactsContract

/**
 * Names and photos for phone numbers and email addresses, cached for a few
 * minutes so a page of conversations costs one lookup per person.
 */
class ContactLookup(private val context: Context, private val canRead: () -> Boolean) {
    private data class Entry(val participant: PlatformParticipant, val at: Long)

    private val cache = LinkedHashMap<String, Entry>(64, 0.75f, true)

    @Synchronized
    fun participant(address: String): PlatformParticipant {
        val now = SystemClock.elapsedRealtime()
        cache[address]?.takeIf { now - it.at < TTL_MS }?.let { return it.participant }

        val participant = when (canRead()) {
            true -> runCatching { lookup(address) }.getOrNull()
            false -> null
        } ?: PlatformParticipant(address = address, name = "")

        cache[address] = Entry(participant, now)
        while (cache.size > MAX_ENTRIES) {
            cache.remove(cache.keys.first())
        }

        return participant
    }

    private fun lookup(address: String): PlatformParticipant? {
        val uri = when (address.contains('@')) {
            true -> Uri.withAppendedPath(ContactsContract.CommonDataKinds.Email.CONTENT_LOOKUP_URI, Uri.encode(address))
            false -> Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(address))
        }
        val projection = arrayOf(
            ContactsContract.Contacts.DISPLAY_NAME,
            ContactsContract.Contacts.PHOTO_THUMBNAIL_URI,
        )

        return context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return@use null
            }

            val name = cursor.getString(0).orEmpty()
            val photo = cursor.getString(1)?.let { photoOf(Uri.parse(it)) }
            PlatformParticipant(address = address, name = name, avatarJpeg = photo)
        }
    }

    private fun photoOf(uri: Uri): ByteArray? = runCatching {
        context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?.let { Thumbnails.jpeg(it, Thumbnails.AVATAR_SIDE) }
    }.getOrNull()

    @Synchronized
    fun clear() = cache.clear()

    private companion object {
        const val TTL_MS = 10 * 60 * 1000L
        const val MAX_ENTRIES = 500
    }
}
