package io.sofluffy.ferret_drop

import android.os.Handler
import android.os.Looper

/**
 * Holds shares from [ShareReceiverActivity] until Dart takes them, or hands
 * them straight to the running plugin.
 */
object ShareInbox {
    fun interface Listener {
        fun onShared(items: SharedItems)
    }

    private val lock = Any()
    private val pending = mutableListOf<SharedItems>()
    private var listener: Listener? = null
    private val main by lazy { Handler(Looper.getMainLooper()) }

    fun setListener(value: Listener?) {
        synchronized(lock) { listener = value }
    }

    /** Delivers [items] on the main thread, or keeps them for later. */
    fun deliver(items: SharedItems) {
        main.post {
            val current = synchronized(lock) { listener }
            if (current == null) {
                keep(items)
                return@post
            }

            current.onShared(items)
        }
    }

    fun keep(items: SharedItems) {
        synchronized(lock) { pending.add(items) }
    }

    fun takeAll(): List<SharedItems> =
        synchronized(lock) {
            val taken = pending.toList()
            pending.clear()
            taken
        }
}
