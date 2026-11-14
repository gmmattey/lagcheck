package com.lagcheck.desktop.library.artwork

/** Confere pelo cabeçalho se os bytes são mesmo uma imagem comum (JPEG, PNG ou WebP). */
object ImageBytes {
    const val MIN_SIZE = 32

    data class Dimensions(val width: Int, val height: Int) {
        val pixels: Long get() = width.toLong() * height
    }

    fun looksLikeImage(b: ByteArray): Boolean {
        if (b.size < MIN_SIZE) return false
        fun at(i: Int) = b[i].toInt() and 0xFF
        val jpeg = at(0) == 0xFF && at(1) == 0xD8 && at(2) == 0xFF
        val png = at(0) == 0x89 && at(1) == 0x50 && at(2) == 0x4E && at(3) == 0x47
        val webp = at(0) == 'R'.code && at(1) == 'I'.code && at(2) == 'F'.code && at(3) == 'F'.code &&
            at(8) == 'W'.code && at(9) == 'E'.code && at(10) == 'B'.code && at(11) == 'P'.code
        return jpeg || png || webp
    }

    fun looksLikeImageFile(path: java.nio.file.Path, maxBytes: Long): Boolean = runCatching {
        val size = java.nio.file.Files.size(path)
        if (size < MIN_SIZE || size > maxBytes) return@runCatching false
        java.nio.file.Files.newInputStream(path).use { looksLikeImage(it.readNBytes(16).copyOf(MIN_SIZE)) }
    }.getOrDefault(false)

    /** Lê apenas o cabeçalho (até 64 KiB); ausência de dimensão não invalida uma imagem conhecida. */
    fun dimensions(path: java.nio.file.Path): Dimensions? = runCatching {
        java.nio.file.Files.newInputStream(path).use { dimensions(it.readNBytes(64 * 1024)) }
    }.getOrNull()

    internal fun dimensions(b: ByteArray): Dimensions? {
        fun u8(index: Int) = b.getOrNull(index)?.toInt()?.and(0xFF)
        fun be32(index: Int): Int? {
            if (index + 3 >= b.size) return null
            return (u8(index)!! shl 24) or (u8(index + 1)!! shl 16) or (u8(index + 2)!! shl 8) or u8(index + 3)!!
        }
        fun le24(index: Int): Int? {
            if (index + 2 >= b.size) return null
            return u8(index)!! or (u8(index + 1)!! shl 8) or (u8(index + 2)!! shl 16)
        }
        fun valid(width: Int?, height: Int?) =
            if (width != null && height != null && width > 0 && height > 0) Dimensions(width, height) else null

        if (b.size >= 24 && u8(0) == 0x89 && u8(1) == 0x50 && u8(2) == 0x4E && u8(3) == 0x47) {
            return valid(be32(16), be32(20))
        }
        if (b.size >= 30 && u8(0) == 'R'.code && u8(1) == 'I'.code && u8(2) == 'F'.code && u8(3) == 'F'.code &&
            u8(8) == 'W'.code && u8(9) == 'E'.code && u8(10) == 'B'.code && u8(11) == 'P'.code &&
            u8(12) == 'V'.code && u8(13) == 'P'.code && u8(14) == '8'.code && u8(15) == 'X'.code
        ) {
            return valid(le24(24)?.plus(1), le24(27)?.plus(1))
        }
        if (b.size < 4 || u8(0) != 0xFF || u8(1) != 0xD8) return null
        var index = 2
        while (index + 8 < b.size) {
            while (index < b.size && u8(index) != 0xFF) index++
            while (index < b.size && u8(index) == 0xFF) index++
            val marker = u8(index++) ?: return null
            if (marker == 0xD9 || marker == 0xDA) return null
            if (marker in setOf(0x01, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7)) continue
            if (index + 1 >= b.size) return null
            val length = (u8(index)!! shl 8) or u8(index + 1)!!
            if (length < 2 || index + length > b.size) return null
            if (marker in setOf(0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF)) {
                return valid((u8(index + 5)!! shl 8) or u8(index + 6)!!, (u8(index + 3)!! shl 8) or u8(index + 4)!!)
            }
            index += length
        }
        return null
    }
}
