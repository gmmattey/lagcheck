package com.lagcheck.desktop.update

import java.io.File
import java.io.InputStream
import java.net.URI
import java.security.MessageDigest

class UpdateDownloader(
    private val transport: HttpTransport,
    private val allowedHosts: Set<String>,
    private val tempDir: File = File(System.getProperty("java.io.tmpdir"), "lagcheck-update")
) {
    fun download(release: Release, onProgress: (Long, Long?) -> Unit = { _, _ -> }, cancelled: () -> Boolean = { false }): File? {
        var target: File? = null
        return try {
            val uri = URI(release.url)
            require(uri.scheme.equals("https", true) && uri.host in allowedHosts) { "Host de download não permitido" }
            if (cancelled()) return null
            val response = transport.execute(TransportRequest(release.url))
            if (response.status !in 200..299 || cancelled()) {
                response.body.close()
                return null
            }
            tempDir.mkdirs()
            val suffix = if (uri.path.endsWith(".msi", true)) ".msi" else ".exe"
            val created = File.createTempFile("lagcheck-", suffix, tempDir)
            target = created
            val total = response.headers.entries.firstOrNull { it.key.equals("content-length", ignoreCase = true) }?.value?.toLongOrNull()
            val digest = MessageDigest.getInstance("SHA-256")
            val completed = response.body.use { input -> copyToFile(input, created, digest, total, onProgress, cancelled) }
            if (!completed || !digest.digest().toHex().equals(release.sha256, ignoreCase = true)) {
                created.delete()
                return null
            }
            created
        } catch (_: Exception) {
            target?.delete()
            null
        }
    }

    internal fun matchesChecksum(file: File, expected: String): Boolean = runCatching {
        file.inputStream().use { input ->
            val digest = MessageDigest.getInstance("SHA-256")
            val buffer = ByteArray(BUFFER_SIZE)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
            digest.digest().toHex().equals(expected, ignoreCase = true)
        }
    }.getOrDefault(false)

    private fun copyToFile(input: InputStream, target: File, digest: MessageDigest, total: Long?, onProgress: (Long, Long?) -> Unit, cancelled: () -> Boolean): Boolean {
        var received = 0L
        target.outputStream().use { output ->
            val buffer = ByteArray(BUFFER_SIZE)
            while (true) {
                if (cancelled()) return false
                val count = input.read(buffer)
                if (count < 0) break
                output.write(buffer, 0, count)
                digest.update(buffer, 0, count)
                received += count
                onProgress(received, total)
            }
        }
        return !cancelled()
    }

    private fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }

    private companion object { const val BUFFER_SIZE = 32 * 1024 }
}
