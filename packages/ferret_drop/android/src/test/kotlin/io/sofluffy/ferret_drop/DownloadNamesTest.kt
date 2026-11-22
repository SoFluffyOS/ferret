package io.sofluffy.ferret_drop

import kotlin.test.Test
import kotlin.test.assertEquals

internal class DownloadNamesTest {
    @Test
    fun relativePath_trimsSlashesAroundTheFolder() {
        assertEquals("Download/Ferret/Photos/", DownloadNames.relativePath("Download", "/Ferret/Photos/"))
    }

    @Test
    fun free_keepsANameNobodyUses() {
        assertEquals("clip.mov", DownloadNames.free("clip.mov") { false })
    }

    @Test
    fun free_numbersBeforeTheExtension() {
        val taken = setOf("clip.mov", "clip (1).mov")

        assertEquals("clip (2).mov", DownloadNames.free("clip.mov") { it in taken })
    }

    @Test
    fun free_numbersANameWithoutExtensionOrWithALeadingDot() {
        assertEquals("notes (1)", DownloadNames.free("notes") { it == "notes" })
        assertEquals(".env (1)", DownloadNames.free(".env") { it == ".env" })
    }
}
