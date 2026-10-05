package com.lagcheck.android.data

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.URI
import java.net.HttpURLConnection
import java.net.URLEncoder
import java.security.MessageDigest
import java.util.concurrent.Executors
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/** Images only: catalog signature stays in core:catalog; no content digest verification. */
object RemoteArtworkRepository {
    private const val MAX_BYTES = 8 * 1024 * 1024
    private const val MAX_CACHE = 50L * 1024 * 1024
    private val workers = Executors.newFixedThreadPool(3)
    private val active = mutableSetOf<HttpURLConnection>()
    @Volatile private var enabled = true

    @Synchronized fun setDownloadsEnabled(value: Boolean) {
        enabled = value
        if (!value) { active.forEach { it.disconnect() }; active.clear() }
    }

    suspend fun load(context: Context, url: String?, revision: String): Bitmap? = suspendCancellableCoroutine { continuation ->
        var connection: HttpURLConnection? = null
        val future = workers.submit {
            var result: Bitmap? = null
            try {
                val uri = url?.let { URI(it) }
                if (uri == null || uri.scheme != "https" || uri.host == null || uri.userInfo != null ||
                    uri.query != null || uri.fragment != null || !Regex("^/artwork/games/[a-zA-Z0-9_-]+\\.(jpg|jpeg|png|webp)$").matches(uri.path)) {
                    return@submit
                }
                val directory = File(context.cacheDir, "remote-artwork").apply { mkdirs() }
                // Hash names a local cache file; it is not checked against image content.
                val key = MessageDigest.getInstance("SHA-256").digest("$url|$revision".toByteArray()).joinToString("") { "%02x".format(it) }
                val file = File(directory, key)
                val cached = if (file.exists() && file.length() <= MAX_BYTES) decode(file.readBytes()) else null
                result = cached
                if (cached != null && System.currentTimeMillis() - file.lastModified() < 86_400_000) return@submit
                if (!enabled || !continuation.isActive) return@submit
                val requestUrl = URI("$url?revision=${URLEncoder.encode(revision, "UTF-8")}").toURL()
                val conn = requestUrl.openConnection() as HttpURLConnection
                connection = conn
                synchronized(this) {
                    if (!enabled || !continuation.isActive) return@submit
                    active.add(conn)
                }
                conn.connectTimeout = 5000
                conn.readTimeout = 5000
                conn.instanceFollowRedirects = false
                conn.setRequestProperty("Accept", "image/png,image/jpeg,image/webp")
                if (conn.responseCode != 200 || conn.contentType?.substringBefore(';')?.lowercase() !in setOf("image/png", "image/jpeg", "image/webp") || conn.contentLengthLong > MAX_BYTES) return@submit
                val bytes = conn.inputStream.use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (true) {
                        if (!enabled || !continuation.isActive) return@submit
                        val count = input.read(buffer)
                        if (count < 0) break
                        if (output.size() + count > MAX_BYTES) return@submit
                        output.write(buffer, 0, count)
                    }
                    output.toByteArray()
                }
                val image = decode(bytes) ?: return@submit
                if (!enabled || !continuation.isActive) return@submit
                val temporary = File.createTempFile("art-", ".tmp", directory)
                try { temporary.writeBytes(bytes); temporary.renameTo(file) } finally { temporary.delete() }
                trim(directory)
                result = image
            } catch (_: Exception) {
                // Retain cached/local art; image failure never affects measurement.
            } finally {
                connection?.let { conn -> synchronized(this) { active.remove(conn) }; conn.disconnect() }
                if (continuation.isActive) continuation.resume(result)
            }
        }
        continuation.invokeOnCancellation { connection?.disconnect(); future.cancel(true) }
    }

    private fun decode(bytes: ByteArray): Bitmap? {
        if (bytes.isEmpty() || bytes.size > MAX_BYTES) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        if (bounds.outWidth !in 1..4096 || bounds.outHeight !in 1..4096) return null
        val options = BitmapFactory.Options().apply {
            inSampleSize = if (maxOf(bounds.outWidth, bounds.outHeight) > 2048) 2 else 1
        }
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
    }
    private fun trim(directory: File) {
        val files = directory.listFiles()?.filter { it.isFile }?.sortedBy { it.lastModified() } ?: return
        var size = files.sumOf { it.length() }
        for (file in files) { if (size <= MAX_CACHE) break; val length = file.length(); if (file.delete()) size -= length }
    }
}
