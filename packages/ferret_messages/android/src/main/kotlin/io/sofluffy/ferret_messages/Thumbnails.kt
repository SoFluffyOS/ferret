package io.sofluffy.ferret_messages

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import java.io.ByteArrayOutputStream

/** Small JPEG previews for contact photos and MMS images. */
object Thumbnails {
    const val AVATAR_SIDE = 96
    const val PREVIEW_SIDE = 320
    private const val QUALITY = 72

    /** [bytes] scaled to fit [maxSide] and re-encoded as JPEG, or null when it isn't an image. */
    fun jpeg(bytes: ByteArray, maxSide: Int): ByteArray? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            return null
        }

        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight, maxSide)
        }
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options) ?: return null
        val scale = minOf(1f, maxSide.toFloat() / maxOf(decoded.width, decoded.height))
        val width = maxOf(1, (decoded.width * scale).toInt())
        val height = maxOf(1, (decoded.height * scale).toInt())

        // JPEG has no alpha: draw on white so transparent PNGs and stickers stay readable.
        val flat = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        Canvas(flat).apply {
            drawColor(Color.WHITE)
            drawBitmap(Bitmap.createScaledBitmap(decoded, width, height, true), 0f, 0f, null)
        }

        return ByteArrayOutputStream().use { out ->
            flat.compress(Bitmap.CompressFormat.JPEG, QUALITY, out)
            out.toByteArray()
        }
    }

    /** The largest power of two that keeps both sides at least [maxSide]. */
    fun sampleSize(width: Int, height: Int, maxSide: Int): Int {
        var sample = 1
        while (maxOf(width, height) / (sample * 2) >= maxSide) {
            sample *= 2
        }

        return sample
    }
}
