package com.lagcheck.android.update

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.coroutines.coroutineContext

data class DownloadProgress(
    val bytesDownloaded: Long,
    val totalBytes: Long,
    val percentage: Int
)

class ApkDownloader(
    private val destinationDirectory: File
) {

    suspend fun download(
        downloadUrl: String,
        targetFileName: String = "lagcheck-update.apk",
        onProgress: (DownloadProgress) -> Unit = {}
    ): Result<File> = withContext(Dispatchers.IO) {
        runCatching {
            destinationDirectory.mkdirs()
            val tempFile = File(destinationDirectory, "$targetFileName.tmp")
            val targetFile = File(destinationDirectory, targetFileName)

            if (tempFile.exists()) tempFile.delete()
            if (targetFile.exists()) targetFile.delete()

            var currentUrl = downloadUrl
            var connection: HttpURLConnection? = null
            var inputStream: InputStream? = null
            var redirects = 0

            while (redirects < 5) {
                val url = URL(currentUrl)
                connection = (url.openConnection() as HttpURLConnection).apply {
                    connectTimeout = 15000
                    readTimeout = 20000
                    instanceFollowRedirects = false
                    setRequestProperty("User-Agent", "LagCheck-Android-Updater")
                }

                val status = connection.responseCode
                if (status in 300..399) {
                    val redirectLocation = connection.getHeaderField("Location") ?: break
                    connection.disconnect()
                    currentUrl = if (redirectLocation.startsWith("http")) {
                        redirectLocation
                    } else {
                        URL(url, redirectLocation).toString()
                    }
                    redirects++
                } else if (status in 200..299) {
                    break
                } else {
                    connection.disconnect()
                    error("Falha ao baixar atualização: HTTP $status")
                }
            }

            val finalConn = connection ?: error("Conexão não estabelecida")
            val totalBytes = finalConn.contentLengthLong

            inputStream = finalConn.inputStream
            val outputStream = FileOutputStream(tempFile)

            var bytesDownloaded = 0L
            val buffer = ByteArray(8192)

            inputStream.use { input ->
                outputStream.use { output ->
                    var bytesRead: Int
                    while (input.read(buffer).also { bytesRead = it } != -1) {
                        coroutineContext.ensureActive()
                        output.write(buffer, 0, bytesRead)
                        bytesDownloaded += bytesRead

                        val percent = if (totalBytes > 0) {
                            ((bytesDownloaded * 100) / totalBytes).toInt().coerceIn(0, 100)
                        } else {
                            -1
                        }

                        onProgress(DownloadProgress(bytesDownloaded, totalBytes, percent))
                    }
                    output.flush()
                }
            }
            finalConn.disconnect()

            if (!tempFile.exists() || tempFile.length() == 0L) {
                error("Arquivo baixado está vazio")
            }

            if (!tempFile.renameTo(targetFile)) {
                tempFile.copyTo(targetFile, overwrite = true)
                tempFile.delete()
            }

            targetFile
        }
    }
}
