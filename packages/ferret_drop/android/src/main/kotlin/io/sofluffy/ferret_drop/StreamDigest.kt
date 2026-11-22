package io.sofluffy.ferret_drop

import java.io.InputStream
import java.security.MessageDigest

/** SHA-256 of everything left in a stream. */
internal object StreamDigest {
    private const val BUFFER_SIZE = 1024 * 1024

    fun sha256(input: InputStream): ByteArray {
        val digest = MessageDigest.getInstance("SHA-256")
        val buffer = ByteArray(BUFFER_SIZE)
        while (true) {
            val count = input.read(buffer)
            if (count < 0) {
                break
            }

            digest.update(buffer, 0, count)
        }

        return digest.digest()
    }
}
