package io.sofluffy.ferret_drop

import java.io.ByteArrayInputStream
import java.security.MessageDigest
import kotlin.test.Test
import kotlin.test.assertContentEquals

internal class StreamDigestTest {
    @Test
    fun sha256_ofAnEmptyStream() {
        val expected = MessageDigest.getInstance("SHA-256").digest(ByteArray(0))

        assertContentEquals(expected, StreamDigest.sha256(ByteArrayInputStream(ByteArray(0))))
    }

    @Test
    fun sha256_readsPastOneBuffer() {
        val bytes = ByteArray(3 * 1024 * 1024 + 17) { (it % 251).toByte() }
        val expected = MessageDigest.getInstance("SHA-256").digest(bytes)

        assertContentEquals(expected, StreamDigest.sha256(ByteArrayInputStream(bytes)))
    }
}
