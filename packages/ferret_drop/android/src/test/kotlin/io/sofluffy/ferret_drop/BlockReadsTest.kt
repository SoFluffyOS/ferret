package io.sofluffy.ferret_drop

import java.io.ByteArrayInputStream
import java.io.InputStream
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals

internal class BlockReadsTest {
    /** A pipe-like stream that hands out at most [step] bytes per read. */
    private class Trickle(private val bytes: ByteArray, private val step: Int) : InputStream() {
        private var at = 0

        override fun read(): Int = if (at < bytes.size) bytes[at++].toInt() and 0xff else -1

        override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
            if (at >= bytes.size) {
                return -1
            }

            val count = minOf(step, length, bytes.size - at)
            System.arraycopy(bytes, at, buffer, offset, count)
            at += count
            return count
        }
    }

    private val source = ByteArray(10_000) { (it % 251).toByte() }

    @Test
    fun fillsWholeBlocksFromAStreamThatReadsInSmallPieces() {
        val input = Trickle(source, step = 7)

        val first = BlockReads.read(input, 4096)
        val second = BlockReads.read(input, 4096)

        assertEquals(4096, first.size)
        assertContentEquals(source.copyOfRange(0, 4096), first)
        assertContentEquals(source.copyOfRange(4096, 8192), second)
    }

    @Test
    fun returnsTheShortTailThenNothing() {
        val input = ByteArrayInputStream(source)
        BlockReads.read(input, 8192)

        val tail = BlockReads.read(input, 8192)
        val after = BlockReads.read(input, 8192)

        assertContentEquals(source.copyOfRange(8192, source.size), tail)
        assertEquals(0, after.size)
    }

    @Test
    fun skippingToAnOffsetByReadingKeepsTheRestInOrder() {
        val input = Trickle(source, step = 1000)
        var skipped = 0
        while (skipped < 6000) {
            skipped += BlockReads.read(input, minOf(4096, 6000 - skipped)).size
        }

        assertContentEquals(source.copyOfRange(6000, source.size), BlockReads.read(input, 8192))
    }
}
