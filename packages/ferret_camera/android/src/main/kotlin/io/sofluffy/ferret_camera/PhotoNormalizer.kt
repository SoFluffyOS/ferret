package io.sofluffy.ferret_camera

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Turns the camera app's file into the JPEG Ferret sends: the right way
 * up (computers don't all read the EXIF turn), at most [MAX_SIDE] pixels
 * long, and without EXIF, so the photo's location stays on the phone. */
object PhotoNormalizer {
    const val MAX_SIDE = 4096
    private const val QUALITY = 90

    /** Writes the cleaned photo next to [source] and deletes [source].
     * Returns the new file's path, or null when it couldn't be read. */
    fun normalize(source: File, now: Date = Date()): String? {
        try {
            val degrees = degreesOf(
                ExifInterface(source.absolutePath).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL,
                ),
            )
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(source.absolutePath, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                return null
            }

            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleFor(maxOf(bounds.outWidth, bounds.outHeight))
            }
            val decoded = BitmapFactory.decodeFile(source.absolutePath, options) ?: return null
            val turned = turn(decoded, degrees)
            val target = File(source.parentFile, fileName(now))
            FileOutputStream(target).use { turned.compress(Bitmap.CompressFormat.JPEG, QUALITY, it) }
            if (turned !== decoded) {
                turned.recycle()
            }
            decoded.recycle()
            return target.absolutePath
        } catch (error: Exception) {
            return null
        } catch (error: OutOfMemoryError) {
            return null
        } finally {
            source.delete()
        }
    }

    /** How far to turn a picture with this EXIF orientation. Mirrored
     * orientations only come from front cameras of a few makers; they keep
     * their turn and stay mirrored. */
    fun degreesOf(orientation: Int): Float = when (orientation) {
        ExifInterface.ORIENTATION_ROTATE_90, ExifInterface.ORIENTATION_TRANSPOSE -> 90f
        ExifInterface.ORIENTATION_ROTATE_180, ExifInterface.ORIENTATION_FLIP_VERTICAL -> 180f
        ExifInterface.ORIENTATION_ROTATE_270, ExifInterface.ORIENTATION_TRANSVERSE -> 270f
        else -> 0f
    }

    /** The power of two that brings [longSide] down to [MAX_SIDE] or less. */
    fun sampleFor(longSide: Int): Int {
        var sample = 1
        while (longSide / sample > MAX_SIDE) {
            sample *= 2
        }
        return sample
    }

    fun fileName(now: Date): String =
        "Photo " + SimpleDateFormat("yyyy-MM-dd 'at' HH.mm.ss", Locale.US).format(now) + ".jpg"

    private fun turn(bitmap: Bitmap, degrees: Float): Bitmap {
        if (degrees == 0f) {
            return bitmap
        }

        val matrix = Matrix().apply { postRotate(degrees) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }
}
