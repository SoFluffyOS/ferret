package io.sofluffy.ferret_notifications

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.util.LruCache
import java.io.ByteArrayOutputStream

/** Small PNGs of app icons, cached per package. */
internal object AppIcons {
    private const val NOTIFICATION_ICON_PX = 96
    private const val PICKER_ICON_PX = 72

    private val cache = LruCache<String, ByteArray>(128)

    fun notificationIcon(context: Context, packageName: String): ByteArray? =
        cached("$packageName@$NOTIFICATION_ICON_PX") { render(context, packageName, NOTIFICATION_ICON_PX) }

    fun pickerIcon(context: Context, packageName: String): ByteArray? =
        cached("$packageName@$PICKER_ICON_PX") { render(context, packageName, PICKER_ICON_PX) }

    private fun cached(key: String, load: () -> ByteArray?): ByteArray? {
        cache.get(key)?.let { return it }

        val bytes = load() ?: return null
        cache.put(key, bytes)
        return bytes
    }

    private fun render(context: Context, packageName: String, size: Int): ByteArray? {
        val drawable = runCatching { context.packageManager.getApplicationIcon(packageName) }
            .getOrNull() ?: return null

        return runCatching { toPng(drawable, size) }.getOrNull()
    }

    private fun toPng(drawable: Drawable, size: Int): ByteArray {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)

        val output = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
        bitmap.recycle()
        return output.toByteArray()
    }
}
