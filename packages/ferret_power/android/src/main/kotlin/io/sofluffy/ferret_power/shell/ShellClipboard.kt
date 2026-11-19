package io.sofluffy.ferret_power.shell

import android.content.ClipData
import android.content.ClipDescription
import android.content.IOnPrimaryClipChangedListener
import android.os.Bundle
import android.os.IBinder
import java.lang.reflect.Method

/**
 * The system clipboard as the shell user sees it. Runs only inside the
 * helper process (Shizuku's user service or the root helper), never in the
 * app: the shell user may read the clipboard in the background, an app may
 * not. Talks to the clipboard service directly because the helper has no
 * `Context`.
 */
internal class ShellClipboard {
    private val service: Any? = runCatching { connect() }.getOrNull()
    private var listener: IOnPrimaryClipChangedListener? = null
    private var listenerUserId = 0

    /** The clipboard text of [userId], or null when there is none. */
    fun read(userId: Int): ShellClip? {
        val service = service ?: return null
        val method = method(service, "getPrimaryClip") ?: return null
        val arguments = ShellArguments.fill(method.parameterTypes, userId, null)
        val clip = runCatching { method.invoke(service, *arguments) as? ClipData }.getOrNull() ?: return null
        if (clip.itemCount == 0) {
            return null
        }

        val text = clip.getItemAt(0).text?.toString()
        if (text.isNullOrEmpty() || text.length > MAX_TEXT_LENGTH) {
            return null
        }

        val sensitive = clip.description?.extras?.getBoolean(EXTRA_IS_SENSITIVE, false) == true
        return ShellClip(text, sensitive)
    }

    /**
     * The clip of [userId] after a change, or null when the watcher has no
     * reason to read it: Ferret wrote it, or it holds no text. Decided from
     * the description, which Android hands out without the "pasted" toast.
     */
    fun readChange(userId: Int): ShellClip? {
        val description = description(userId)
        if (description != null && !shouldRead(description)) {
            return null
        }
        return read(userId)
    }

    private fun description(userId: Int): ClipDescription? {
        val service = service ?: return null
        val method = method(service, "getPrimaryClipDescription") ?: return null
        val arguments = ShellArguments.fill(method.parameterTypes, userId, null)
        return runCatching { method.invoke(service, *arguments) as? ClipDescription }.getOrNull()
    }

    private fun shouldRead(description: ClipDescription): Boolean {
        val writtenAt = runCatching { description.extras?.getLong(ShellClipFilter.EXTRA_WRITTEN_AT, 0L) }
            .getOrNull() ?: 0L
        val mimeTypes = List(description.mimeTypeCount) { index -> description.getMimeType(index) }
        return ShellClipFilter.shouldRead(description.label, writtenAt, mimeTypes, System.currentTimeMillis())
    }

    /** Calls [onChanged] after every copy. False when the service refused. */
    @Synchronized
    fun watch(userId: Int, onChanged: () -> Unit): Boolean {
        unwatch()
        val service = service ?: return false
        val method = method(service, "addPrimaryClipChangedListener") ?: return false
        val added = object : IOnPrimaryClipChangedListener.Stub() {
            override fun dispatchPrimaryClipChanged() {
                runCatching { onChanged() }
            }
        }

        val arguments = ShellArguments.fill(method.parameterTypes, userId, added)
        val registered = runCatching { method.invoke(service, *arguments) }.isSuccess
        if (registered) {
            listener = added
            listenerUserId = userId
        }
        return registered
    }

    @Synchronized
    fun unwatch() {
        val service = service ?: return
        val removed = listener ?: return
        listener = null
        val method = method(service, "removePrimaryClipChangedListener") ?: return
        val arguments = ShellArguments.fill(method.parameterTypes, listenerUserId, removed)
        runCatching { method.invoke(service, *arguments) }
    }

    private fun connect(): Any? {
        val binder = Class.forName("android.os.ServiceManager")
            .getMethod("getService", String::class.java)
            .invoke(null, "clipboard") as? IBinder ?: return null
        return Class.forName("android.content.IClipboard\$Stub")
            .getMethod("asInterface", IBinder::class.java)
            .invoke(null, binder)
    }

    private fun method(service: Any, name: String): Method? =
        service.javaClass.methods.firstOrNull { it.name == name }

    companion object {
        /** ClipDescription.EXTRA_IS_SENSITIVE, public from Android 13. */
        private const val EXTRA_IS_SENSITIVE = "android.content.extra.IS_SENSITIVE"

        /** Keeps a clip well under the 1 MB a binder call can carry. */
        const val MAX_TEXT_LENGTH = 200_000

        const val KEY_TEXT = "text"
        const val KEY_SENSITIVE = "sensitive"

        fun bundleOf(clip: ShellClip): Bundle = Bundle().apply {
            putString(KEY_TEXT, clip.text)
            putBoolean(KEY_SENSITIVE, clip.sensitive)
        }

        fun clipOf(bundle: Bundle?): ShellClip? {
            val text = bundle?.getString(KEY_TEXT)
            if (text.isNullOrEmpty()) {
                return null
            }
            return ShellClip(text, bundle.getBoolean(KEY_SENSITIVE, false))
        }
    }
}
