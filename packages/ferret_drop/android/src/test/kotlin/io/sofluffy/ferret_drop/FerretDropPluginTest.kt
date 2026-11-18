package io.sofluffy.ferret_drop

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class FerretDropPluginTest {
    @Test
    fun takePendingShares_returnsEachShareOnce() {
        ShareInbox.keep(SharedItems(paths = listOf("/tmp/a.txt"), text = null))

        val first = ShareInbox.takeAll()
        val second = ShareInbox.takeAll()

        assertEquals(listOf("/tmp/a.txt"), first.single().paths)
        assertTrue(second.isEmpty())
    }
}
