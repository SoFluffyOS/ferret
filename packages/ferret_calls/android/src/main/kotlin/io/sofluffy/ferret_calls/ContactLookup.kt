package io.sofluffy.ferret_calls

import android.Manifest
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.ContactsContract
import java.io.ByteArrayOutputStream

/** Finds the contact behind a phone number. */
internal class ContactLookup(private val context: Context) {
    /** Null when the number is unknown or `READ_CONTACTS` is missing. */
    fun find(number: String, withPhoto: Boolean): PlatformContact? {
        if (number.isBlank() ||
            !CallPermissions.isGranted(context, Manifest.permission.READ_CONTACTS)
        ) {
            return null
        }

        val lookup = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
            Uri.encode(number),
        )
        val columns = arrayOf(
            ContactsContract.PhoneLookup.CONTACT_ID,
            ContactsContract.PhoneLookup.DISPLAY_NAME,
        )

        return runCatching {
            context.contentResolver.query(lookup, columns, null, null, null)?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return@use null
                }

                val contactId = cursor.getLong(0)
                val name = cursor.getString(1).orEmpty()
                PlatformContact(
                    name = name,
                    photoJpeg = if (withPhoto) photoOf(contactId) else null,
                )
            }
        }.getOrNull()
    }

    private fun photoOf(contactId: Long): ByteArray? {
        val contact = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId)
        val thumbnail = runCatching {
            ContactsContract.Contacts.openContactPhotoInputStream(
                context.contentResolver,
                contact,
                false,
            )?.use { BitmapFactory.decodeStream(it) }
        }.getOrNull() ?: return null

        val (width, height) = PhotoSize.fit(thumbnail.width, thumbnail.height, PhotoSize.MAX_SIDE)
        val scaled = Bitmap.createScaledBitmap(thumbnail, width, height, true)
        val output = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, output)
        return output.toByteArray()
    }

    private companion object {
        const val JPEG_QUALITY = 80
    }
}

/** Sizes for the contact photo sent to other devices. */
internal object PhotoSize {
    const val MAX_SIDE = 96

    /** [width] x [height] scaled down to fit [maxSide], keeping its shape. */
    fun fit(width: Int, height: Int, maxSide: Int): Pair<Int, Int> {
        val longest = maxOf(width, height)
        if (longest <= maxSide) {
            return width to height
        }

        val scaledWidth = maxOf(1, width * maxSide / longest)
        val scaledHeight = maxOf(1, height * maxSide / longest)
        return scaledWidth to scaledHeight
    }
}
