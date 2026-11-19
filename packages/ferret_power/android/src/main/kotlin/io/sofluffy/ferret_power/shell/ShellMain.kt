package io.sofluffy.ferret_power.shell

import java.io.FileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.PrintStream
import kotlin.system.exitProcess

/**
 * Ferret's helper on a rooted phone, started by the app through `su` with
 * `app_process`. It takes the commands in [ShellLines] on stdin, answers on
 * stdout, and exits when the app closes the pipe.
 */
object ShellMain {
    @JvmStatic
    fun main(arguments: Array<String>) {
        val options = ShellOptions.parse(arguments)
        val clipboard = ShellClipboard()
        val injector = ShellInjector()
        val output = PrintStream(FileOutputStream(FileDescriptor.out), true, "UTF-8")
        val send: (String) -> Unit = { line -> synchronized(output) { output.println(line) } }

        send(ShellLines.READY)
        FileInputStream(FileDescriptor.`in`).bufferedReader(Charsets.UTF_8).useLines { lines ->
            for (line in lines) {
                // What is typed may end in a space, so a text line stays whole.
                val command = if (line.startsWith("${ShellInput.TEXT} ")) line else line.trim()
                if (command == ShellLines.QUIT) {
                    break
                }
                send(answer(command, options, clipboard, injector, send))
            }
        }

        injector.release()
        clipboard.unwatch()
        exitProcess(0)
    }

    private fun answer(
        command: String,
        options: ShellOptions,
        clipboard: ShellClipboard,
        injector: ShellInjector,
        send: (String) -> Unit,
    ): String {
        if (command == ShellLines.READ) {
            val clip = clipboard.read(options.userId) ?: return ShellLines.EMPTY
            return ShellLines.clipLine(ShellLines.CLIP, clip)
        }

        if (command == ShellLines.WATCH) {
            val watching = clipboard.watch(options.userId) {
                val clip = clipboard.readChange(options.userId) ?: return@watch
                send(ShellLines.clipLine(ShellLines.CHANGE, clip))
            }
            return if (watching) ShellLines.OK else ShellLines.FAIL
        }

        if (command == ShellLines.UNWATCH) {
            clipboard.unwatch()
            return ShellLines.OK
        }

        if (command.startsWith("${ShellLines.GRANT} ")) {
            val grant = command.removePrefix("${ShellLines.GRANT} ")
            val granted = ShellGrants.run(grant, options.packageName, options.listenerComponent)
            return if (granted) ShellLines.OK else ShellLines.FAIL
        }

        if (command == ShellLines.RELEASE) {
            injector.release()
            return ShellLines.OK
        }

        val input = ShellInput.parse(line = command) ?: return ShellLines.FAIL
        return if (injector.run(input)) ShellLines.OK else ShellLines.FAIL
    }
}
