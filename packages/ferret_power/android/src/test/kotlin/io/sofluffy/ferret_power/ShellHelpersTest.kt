package io.sofluffy.ferret_power

import io.sofluffy.ferret_power.shell.ShellArguments
import io.sofluffy.ferret_power.shell.ShellClip
import io.sofluffy.ferret_power.shell.ShellGrants
import io.sofluffy.ferret_power.shell.ShellLines
import io.sofluffy.ferret_power.shell.ShellOptions
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class ShellLinesTest {
    @Test
    fun clipSurvivesNewlinesAndBackslashes() {
        val clip = ShellClip("first\nsecond\r\n\\n C:\\temp", sensitive = true)

        val line = ShellLines.clipLine(ShellLines.CHANGE, clip)

        assertEquals(false, line.contains('\n'))
        assertEquals(clip, ShellLines.parseClip(ShellLines.CHANGE, line))
    }

    @Test
    fun otherLinesAreNotClips() {
        assertNull(ShellLines.parseClip(ShellLines.CLIP, ShellLines.EMPTY))
        assertNull(ShellLines.parseClip(ShellLines.CLIP, "CHANGE 0 hello"))
        assertNull(ShellLines.parseClip(ShellLines.CLIP, "CLIP x hello"))
    }
}

internal class RootCommandTest {
    @Test
    fun quotesStopShellSyntax() {
        assertEquals("'it'\\''s; rm -rf /'", RootCommand.quote("it's; rm -rf /"))
    }

    @Test
    fun helperRunsFromTheApkWithQuotedArguments() {
        val options = ShellOptions(10, "io.sofluffy.ferret", "io.sofluffy.ferret/a.Listener")

        val command = RootCommand.helper("/data/app/~~x==/base.apk", options)

        assertEquals(
            "CLASSPATH='/data/app/~~x==/base.apk' exec app_process /system/bin " +
                "io.sofluffy.ferret_power.shell.ShellMain '--user=10' " +
                "'--package=io.sofluffy.ferret' '--listener=io.sofluffy.ferret/a.Listener' 2>/dev/null",
            command,
        )
        assertEquals(options, ShellOptions.parse(options.toArguments().toTypedArray()))
    }

    @Test
    fun shellUserIsTriedBeforeRoot() {
        val launchers = RootCommand.launchers("helper")

        assertEquals(listOf("su", "2000", "-c", "helper"), launchers.first())
        assertEquals(listOf("su", "-c", "helper"), launchers.last())
    }
}

internal class ShellGrantsTest {
    private val listener = "io.sofluffy.ferret/io.sofluffy.ferret_notifications.FerretNotificationListener"

    @Test
    fun knownGrantsBecomeFixedCommands() {
        assertEquals(
            listOf("cmd", "notification", "allow_listener", listener),
            ShellGrants.commandFor(ShellGrants.NOTIFICATION_ACCESS, "io.sofluffy.ferret", listener),
        )
        assertEquals(
            listOf("cmd", "deviceidle", "whitelist", "+io.sofluffy.ferret"),
            ShellGrants.commandFor(ShellGrants.BATTERY_UNRESTRICTED, "io.sofluffy.ferret", listener),
        )
    }

    @Test
    fun anythingElseIsRefused() {
        assertNull(ShellGrants.commandFor("pm uninstall", "io.sofluffy.ferret", listener))
        assertNull(ShellGrants.commandFor(ShellGrants.BATTERY_UNRESTRICTED, "io.sofluffy.ferret; reboot", listener))
        assertNull(ShellGrants.commandFor(ShellGrants.NOTIFICATION_ACCESS, "io.sofluffy.ferret", "other.app/a.B"))
        assertNull(ShellGrants.commandFor(ShellGrants.NOTIFICATION_ACCESS, "io.sofluffy.ferret", "io.sofluffy.ferret/a b"))
    }
}

internal class ShellArgumentsTest {
    private val int = Int::class.javaPrimitiveType!!
    private val boolean = Boolean::class.javaPrimitiveType!!
    private val string = String::class.java

    @Test
    fun fillsEveryKnownGetPrimaryClipSignature() {
        assertContentEquals(arrayOf<Any?>("com.android.shell"), fill(string))
        assertContentEquals(arrayOf<Any?>("com.android.shell", 10), fill(string, int))
        assertContentEquals(arrayOf<Any?>("com.android.shell", null, 10), fill(string, string, int))
        assertContentEquals(arrayOf<Any?>("com.android.shell", null, 10, 0), fill(string, string, int, int))
        assertContentEquals(
            arrayOf<Any?>("com.android.shell", null, 10, 0, true),
            fill(string, string, int, int, boolean),
        )
    }

    @Test
    fun putsTheListenerWhereItsTypeIs() {
        val listener = Runnable {}

        val arguments = ShellArguments.fill(arrayOf(Runnable::class.java, string, int), 0, listener)

        assertContentEquals(arrayOf<Any?>(listener, "com.android.shell", 0), arguments)
    }

    private fun fill(vararg types: Class<*>) = ShellArguments.fill(arrayOf(*types), 10, null)
}
