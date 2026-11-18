package io.sofluffy.ferret_clipboard

import kotlin.test.Test
import kotlin.test.assertEquals

internal class FerretClipboardPluginTest {
    @Test
    fun sensitiveExtraMatchesTheAndroidConstant() {
        assertEquals("android.content.extra.IS_SENSITIVE", FerretClipboardPlugin.EXTRA_IS_SENSITIVE)
    }
}
