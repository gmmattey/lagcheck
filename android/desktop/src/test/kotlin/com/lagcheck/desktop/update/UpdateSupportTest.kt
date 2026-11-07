package com.lagcheck.desktop.update

import java.io.File
import java.io.ByteArrayInputStream
import java.io.InputStream
import java.nio.file.Files
import java.security.MessageDigest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class UpdateSupportTest {
    private fun response(status: Int, bytes: ByteArray = byteArrayOf(), headers: Map<String, String> = emptyMap()) =
        TransportResponse(status, headers, ByteArrayInputStream(bytes))

    @Test fun comparatorAcceptsWindowsTagAndBlocksDowngrade() {
        assertTrue(VersionComparer.isNewer("windows-v1.2", "1.1.9"))
        assertFalse(VersionComparer.isNewer("1.2.0", "1.2.0"))
        assertFalse(VersionComparer.isNewer("1.1.9", "1.2"))
        assertNull(VersionComparer.compare("one", "1.0"))
    }

    @Test fun manifestRejectsMalformedData() {
        assertNull(ManifestParser.release("not json"))
        assertNull(ManifestParser.release("{\"version\":\"1.2\"}"))
        assertEquals("1.2", ManifestParser.release("{\"version\":\"1.2\",\"notes\":\"ok\",\"url\":\"https://downloads.example.com/app.msi\",\"sha256\":\"${"a".repeat(64)}\"}")?.version)
    }

    @Test fun githubFiltersTagsDraftsAndPrereleases() {
        val sha = "b".repeat(64)
        val json = """[{"tag_name":"windows-v1.2","draft":false,"prerelease":false,"assets":[{"browser_download_url":"https://downloads.example.com/app.msi","digest":"sha256:$sha"}]},{"tag_name":"windows-v2.0","draft":true,"prerelease":false,"assets":[]}]"""
        assertEquals(listOf("1.2"), GitHubReleaseParser.releases(json).map { it.version })
    }

    @Test fun emptySourceDoesNotCallNetworkAndSixHoursAreRespected() {
        var calls = 0
        val file = Files.createTempFile("lagcheck-update", ".properties").toFile().apply { delete() }
        val store = UpdateStore(file)
        val coordinator = UpdateCoordinator(UpdateSourceConfig("", "", emptySet()), store, HttpTransport { calls++; error("network") })
        coordinator.check()
        assertEquals(0, calls)
        store.markChecked()
        assertFalse(store.canCheck())
    }

    @Test fun failedStatusesAndChecksumOrHostMismatchNeverProduceInstaller() {
        val release = Release("1.2", "", "https://downloads.example.com/app.msi", "0".repeat(64))
        val temp = Files.createTempDirectory("lagcheck-update").toFile()
        val denied = UpdateDownloader(HttpTransport { response(200, "bad".toByteArray()) }, emptySet(), temp)
        assertNull(denied.download(release))
        val allowed = UpdateDownloader(HttpTransport { response(403) }, setOf("downloads.example.com"), temp)
        assertNull(allowed.download(release))
        val limited = UpdateDownloader(HttpTransport { response(429) }, setOf("downloads.example.com"), temp)
        assertNull(limited.download(release))
    }

    @Test fun downloaderStreamsVerifiesAndReportsProgress() {
        val bytes = ByteArray(70_000) { (it % 251).toByte() }
        val sha = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
        val release = Release("1.2", "", "https://downloads.example.com/app.msi", sha)
        val temp = Files.createTempDirectory("lagcheck-stream").toFile()
        var progress = 0L
        val downloader = UpdateDownloader(HttpTransport {
            TransportResponse(200, mapOf("Content-Length" to bytes.size.toString()), object : InputStream() {
                private var offset = 0
                override fun read(): Int = if (offset == bytes.size) -1 else bytes[offset++].toInt() and 0xFF
                override fun read(buffer: ByteArray, off: Int, len: Int): Int {
                    if (offset == bytes.size) return -1
                    val count = minOf(len, 7_000, bytes.size - offset)
                    bytes.copyInto(buffer, off, offset, offset + count)
                    offset += count
                    return count
                }
            })
        }, setOf("downloads.example.com"), temp)
        val installer = downloader.download(release, onProgress = { received, total -> progress = received; assertEquals(bytes.size.toLong(), total) })
        assertTrue(installer?.readBytes()?.contentEquals(bytes) == true)
        assertEquals(bytes.size.toLong(), progress)
    }

    @Test fun cancellationAndChecksumMismatchDeletePartialInstaller() {
        val release = Release("1.2", "", "https://downloads.example.com/app.exe", "0".repeat(64))
        val mismatchTemp = Files.createTempDirectory("lagcheck-mismatch").toFile()
        val mismatch = UpdateDownloader(HttpTransport { response(200, ByteArray(80_000) { 1 }) }, setOf("downloads.example.com"), mismatchTemp)
        assertNull(mismatch.download(release))
        assertTrue(mismatchTemp.listFiles().isNullOrEmpty())

        val cancelledTemp = Files.createTempDirectory("lagcheck-cancel").toFile()
        val downloader = UpdateDownloader(HttpTransport { response(200, ByteArray(80_000) { 1 }) }, setOf("downloads.example.com"), cancelledTemp)
        var cancelled = false
        assertNull(downloader.download(release, onProgress = { _, _ -> cancelled = true }, cancelled = { cancelled }))
        assertTrue(cancelledTemp.listFiles().isNullOrEmpty())
    }

    @Test fun msiUsesWindowsInstallerAndExeRunsDirectly() {
        val coordinator = UpdateCoordinator(UpdateSourceConfig("", "", emptySet()), UpdateStore(Files.createTempFile("lagcheck-update", ".properties").toFile()))
        assertEquals(listOf("msiexec.exe", "/i", "C:\\temp\\lagcheck.msi"), coordinator.installerCommand(File("C:\\temp\\lagcheck.msi")))
        assertEquals(listOf("C:\\temp\\lagcheck.exe"), coordinator.installerCommand(File("C:\\temp\\lagcheck.exe")))
    }
}
