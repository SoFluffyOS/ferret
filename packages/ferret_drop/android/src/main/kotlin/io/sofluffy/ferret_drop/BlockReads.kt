package io.sofluffy.ferret_drop

import java.io.InputStream

/** Reads a stream in blocks of a fixed size, whatever its reads return. */
internal object BlockReads {
    /**
     * Up to [length] next bytes of [input]: fewer only at its end, none
     * once it has ended. Streams from other apps are often pipes that hand
     * out a few KB per read.
     */
    fun read(input: InputStream, length: Int): ByteArray {
        val buffer = ByteArray(length)
        var filled = 0
        while (filled < length) {
            val count = input.read(buffer, filled, length - filled)
            if (count < 0) {
                break
            }

            filled += count
        }

        return if (filled == length) buffer else buffer.copyOf(filled)
    }
}
