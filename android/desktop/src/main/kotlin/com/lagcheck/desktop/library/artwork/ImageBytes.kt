package com.lagcheck.desktop.library.artwork

/** Confere pelo cabeçalho se os bytes são mesmo uma imagem comum (JPEG, PNG ou WebP). */
internal object ImageBytes {
    const val MIN_SIZE = 32

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
}
