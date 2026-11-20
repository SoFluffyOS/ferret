package io.sofluffy.ferret_mirroring

/**
 * H.264 as the encoder sends it: NAL units separated by start codes
 * (00 00 01 or 00 00 00 01). MediaCodec takes it as it is, with the
 * parameter sets as its codec-specific data.
 */
internal object AnnexB {
    const val SEQUENCE_PARAMETER_SET = 7
    const val PICTURE_PARAMETER_SET = 8
    const val IDR_SLICE = 5

    private val START_CODE = byteArrayOf(0, 0, 0, 1)

    /** The NAL units in [data], without their start codes. */
    fun units(data: ByteArray): List<IntRange> {
        val units = mutableListOf<IntRange>()
        var unitStart = -1
        var index = 0
        while (index + 2 < data.size) {
            val startsHere = data[index].toInt() == 0 && data[index + 1].toInt() == 0 && data[index + 2].toInt() == 1
            if (!startsHere) {
                index += 1
                continue
            }

            if (unitStart >= 0) {
                var end = index
                while (end > unitStart && data[end - 1].toInt() == 0) {
                    end -= 1
                }

                if (end > unitStart) {
                    units.add(unitStart until end)
                }
            }

            unitStart = index + 3
            index += 3
        }

        if (unitStart in 0 until data.size) {
            units.add(unitStart until data.size)
        }

        return units
    }

    /** The kind of the NAL unit at [range] in [data]. */
    fun kindOf(data: ByteArray, range: IntRange): Int = data[range.first].toInt() and 0x1f

    /** Whether [data] holds a picture every later one can start from. */
    fun hasIdr(data: ByteArray): Boolean = units(data).any { kindOf(data, it) == IDR_SLICE }

    /** [unit] (without a start code) behind a 4-byte start code, as MediaCodec wants its sets. */
    fun withStartCode(unit: ByteArray): ByteArray = START_CODE + unit
}

/** A picture size from a sequence parameter set: whole macroblocks, and the part shown. */
internal data class SpsSize(
    val codedWidth: Int,
    val codedHeight: Int,
    val cropLeft: Int,
    val cropTop: Int,
    val width: Int,
    val height: Int,
) {
    companion object {
        /**
         * Reads the size from [sps], one NAL unit without its start code.
         * Null when it can't be read.
         */
        fun parse(sps: ByteArray): SpsSize? = try {
            read(BitReader(unescape(sps)))
        } catch (error: IndexOutOfBoundsException) {
            null
        } catch (error: IllegalArgumentException) {
            null
        }

        private fun read(bits: BitReader): SpsSize? {
            bits.skip(8)
            val profile = bits.bits(8)
            bits.skip(16)
            bits.ue()
            var chromaFormat = 1
            var separateColourPlanes = false
            if (profile in HIGH_PROFILES) {
                chromaFormat = bits.ue()
                if (chromaFormat == 3) {
                    separateColourPlanes = bits.bit()
                }

                bits.ue()
                bits.ue()
                bits.skip(1)
                if (bits.bit()) {
                    val lists = if (chromaFormat == 3) 12 else 8
                    for (list in 0 until lists) {
                        if (bits.bit()) {
                            skipScalingList(bits, if (list < 6) 16 else 64)
                        }
                    }
                }
            }

            bits.ue()
            when (bits.ue()) {
                0 -> bits.ue()
                1 -> {
                    bits.skip(1)
                    bits.se()
                    bits.se()
                    repeat(bits.ue()) { bits.se() }
                }
            }

            bits.ue()
            bits.skip(1)
            val widthInMbs = bits.ue() + 1
            val heightInMapUnits = bits.ue() + 1
            val frameMbsOnly = bits.bit()
            if (!frameMbsOnly) {
                bits.skip(1)
            }

            bits.skip(1)
            val codedWidth = widthInMbs * 16
            val codedHeight = heightInMapUnits * 16 * (if (frameMbsOnly) 1 else 2)
            if (!bits.bit()) {
                return SpsSize(codedWidth, codedHeight, 0, 0, codedWidth, codedHeight)
            }

            val chroma = if (separateColourPlanes) 0 else chromaFormat
            val cropUnitX = if (chroma == 1 || chroma == 2) 2 else 1
            val cropUnitY = (if (chroma == 1) 2 else 1) * (if (frameMbsOnly) 1 else 2)
            val left = bits.ue() * cropUnitX
            val right = bits.ue() * cropUnitX
            val top = bits.ue() * cropUnitY
            val bottom = bits.ue() * cropUnitY
            val width = codedWidth - left - right
            val height = codedHeight - top - bottom
            if (width <= 0 || height <= 0) {
                return null
            }

            return SpsSize(codedWidth, codedHeight, left, top, width, height)
        }

        private fun skipScalingList(bits: BitReader, size: Int) {
            var last = 8
            var next = 8
            for (index in 0 until size) {
                if (next != 0) {
                    next = (last + bits.se() + 256) % 256
                }

                last = if (next == 0) last else next
            }
        }

        /** Drops the emulation prevention bytes (00 00 03 → 00 00). */
        private fun unescape(data: ByteArray): ByteArray {
            val out = java.io.ByteArrayOutputStream(data.size)
            var zeros = 0
            for (byte in data) {
                val value = byte.toInt() and 0xff
                if (zeros >= 2 && value == 3) {
                    zeros = 0
                    continue
                }

                out.write(value)
                zeros = if (value == 0) zeros + 1 else 0
            }

            return out.toByteArray()
        }

        private val HIGH_PROFILES = setOf(100, 110, 122, 244, 44, 83, 86, 118, 128, 138, 139, 134, 135)
    }
}

private class BitReader(private val data: ByteArray) {
    private var position = 0

    fun bit(): Boolean {
        val byte = data[position / 8].toInt()
        val set = (byte shr (7 - position % 8)) and 1 == 1
        position += 1
        return set
    }

    fun bits(count: Int): Int {
        var value = 0
        repeat(count) { value = (value shl 1) or (if (bit()) 1 else 0) }
        return value
    }

    fun skip(count: Int) {
        position += count
        require(position <= data.size * 8)
    }

    fun ue(): Int {
        var zeros = 0
        while (!bit()) {
            zeros += 1
            require(zeros < 32)
        }

        return (1 shl zeros) - 1 + bits(zeros)
    }

    fun se(): Int {
        val value = ue()
        return if (value % 2 == 1) (value + 1) / 2 else -(value / 2)
    }
}
