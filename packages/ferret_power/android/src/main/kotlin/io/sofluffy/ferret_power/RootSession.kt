package io.sofluffy.ferret_power

import io.sofluffy.ferret_power.shell.ShellClip
import io.sofluffy.ferret_power.shell.ShellLines
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

/**
 * One running root helper. Answers come back in order on stdout; `CHANGE`
 * lines can arrive at any time and go to [onChange].
 */
internal class RootSession(
    private val process: Process,
    private val onChange: (ShellClip) -> Unit,
    private val onClosed: (RootSession) -> Unit,
) {
    private val replies = LinkedBlockingQueue<String>()
    private val writer = process.outputStream.bufferedWriter(Charsets.UTF_8)

    @Volatile
    var isOpen = true
        private set

    init {
        thread(name = "ferret-root-helper", isDaemon = true) {
            runCatching {
                process.inputStream.bufferedReader(Charsets.UTF_8).forEachLine(::onLine)
            }
            isOpen = false
            replies.offer(CLOSED)
            onClosed(this)
        }
    }

    fun awaitReady(): Boolean = replies.poll(READY_TIMEOUT_SECONDS, TimeUnit.SECONDS) == ShellLines.READY

    /** Sends [command] and waits for its answer. Null when the helper is gone. */
    @Synchronized
    fun request(command: String): String? {
        if (!isOpen) {
            return null
        }

        val sent = runCatching {
            writer.write(command)
            writer.newLine()
            writer.flush()
        }.isSuccess
        if (!sent) {
            return null
        }

        val reply = replies.poll(REPLY_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        if (reply == null || reply == CLOSED) {
            return null
        }
        return reply
    }

    fun close() {
        runCatching {
            writer.write(ShellLines.QUIT)
            writer.newLine()
            writer.flush()
        }
        runCatching { writer.close() }
        process.destroy()
    }

    private fun onLine(line: String) {
        val change = ShellLines.parseClip(ShellLines.CHANGE, line)
        if (change != null) {
            onChange(change)
            return
        }
        replies.offer(line)
    }

    private companion object {
        const val CLOSED = "\u0000closed"
        const val READY_TIMEOUT_SECONDS = 20L
        const val REPLY_TIMEOUT_SECONDS = 15L
    }
}
