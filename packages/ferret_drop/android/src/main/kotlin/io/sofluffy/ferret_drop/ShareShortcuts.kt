package io.sofluffy.ferret_drop

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

/**
 * One Direct Share target per connected device, so the share sheet's top row
 * can offer "Simon's MacBook Pro" and a tap sends straight there.
 */
internal object ShareShortcuts {
    const val CATEGORY = "io.sofluffy.ferret_drop.category.SEND_TO_DEVICE"
    private const val PREFIX = "device:"
    private const val TAG = "ShareShortcuts"
    private const val BACKGROUND = 0xFFE8833A.toInt()

    private val names = mutableMapOf<String, String>()

    fun shortcutId(deviceId: String) = PREFIX + deviceId

    /** The device a share-sheet target stands for, or null for any other. */
    fun deviceId(shortcutId: String?): String? =
        shortcutId?.takeIf { it.startsWith(PREFIX) }?.removePrefix(PREFIX)?.takeIf { it.isNotEmpty() }

    fun name(deviceId: String): String? = synchronized(names) { names[deviceId] }

    /** The shortcuts to drop: ours that no longer stand for a target. */
    fun stale(published: List<String>, targets: List<String>): List<String> {
        val wanted = targets.map(::shortcutId).toSet()
        return published.filter { it.startsWith(PREFIX) && it !in wanted }
    }

    fun publish(context: Context, targets: List<ShareTarget>) {
        synchronized(names) {
            names.clear()
            targets.forEach { names[it.deviceId] = it.name }
        }

        try {
            val published = ShortcutManagerCompat.getDynamicShortcuts(context).map { it.id }
            val stale = stale(published, targets.map { it.deviceId })
            if (stale.isNotEmpty()) {
                ShortcutManagerCompat.removeDynamicShortcuts(context, stale)
            }

            val max = ShortcutManagerCompat.getMaxShortcutCountPerActivity(context).coerceAtLeast(1)
            targets.take(max).forEachIndexed { rank, target ->
                ShortcutManagerCompat.pushDynamicShortcut(context, shortcut(context, target, rank))
            }
        } catch (error: RuntimeException) {
            Log.d(TAG, "Share targets not published", error)
        }
    }

    fun reportUsed(context: Context, deviceId: String) {
        try {
            ShortcutManagerCompat.reportShortcutUsed(context, shortcutId(deviceId))
        } catch (error: RuntimeException) {
            Log.d(TAG, "Share target use not reported", error)
        }
    }

    private fun shortcut(context: Context, target: ShareTarget, rank: Int): ShortcutInfoCompat {
        val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(Intent.ACTION_MAIN).setPackage(context.packageName)
        return ShortcutInfoCompat.Builder(context, shortcutId(target.deviceId))
            .setShortLabel(target.name)
            .setLongLabel(target.name)
            .setIcon(icon(context, target.kind))
            .setIntent(open)
            .setLongLived(true)
            .setRank(rank)
            .setCategories(setOf(CATEGORY))
            .build()
    }

    /** The device's outline in white on Ferret's orange, as an adaptive icon. */
    private fun icon(context: Context, kind: String): IconCompat {
        val glyph = ContextCompat.getDrawable(context, glyphFor(kind))
            ?: return IconCompat.createWithResource(context, glyphFor(kind))
        val density = context.resources.displayMetrics.density
        val size = (108 * density).toInt()
        val inset = (36 * density).toInt()
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(BACKGROUND)
        glyph.setTint(Color.WHITE)
        glyph.setBounds(inset, inset, size - inset, size - inset)
        glyph.draw(canvas)
        return IconCompat.createWithAdaptiveBitmap(bitmap)
    }

    private fun glyphFor(kind: String): Int = when (kind) {
        "phone" -> R.drawable.ferret_drop_phone
        "tablet" -> R.drawable.ferret_drop_tablet
        "desktop" -> R.drawable.ferret_drop_desktop
        else -> R.drawable.ferret_drop_laptop
    }
}
