package com.lagcheck.desktop.update

import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration

class JdkTransport(private val allowedHosts: Set<String>, private val version: String) : HttpTransport {
    private val client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(8)).followRedirects(HttpClient.Redirect.NEVER).build()

    override fun execute(request: TransportRequest): TransportResponse {
        var url = request.url
        repeat(5) {
            val uri = URI(url)
            require(uri.scheme.equals("https", true) && uri.host in allowedHosts) { "Host de atualização não permitido" }
            val headers = request.headers + mapOf("User-Agent" to "lagcheck-desktop/$version", "Accept" to "application/json")
            val builder = HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(8)).GET()
            headers.forEach { (name, value) -> builder.header(name, value) }
            val response = client.send(builder.build(), HttpResponse.BodyHandlers.ofInputStream())
            val responseHeaders = response.headers().map().mapValues { it.value.firstOrNull().orEmpty() }
            if (response.statusCode() !in 300..399) return TransportResponse(response.statusCode(), responseHeaders, response.body())
            val location = response.headers().firstValue("location").orElse(null)
            if (location == null) return TransportResponse(response.statusCode(), responseHeaders, response.body())
            response.body().close()
            url = uri.resolve(location).toString()
        }
        throw IllegalStateException("Muitos redirecionamentos")
    }
}

class ManifestReleaseFeed(private val url: String, private val transport: HttpTransport) : ReleaseFeed {
    override fun latest(): Release? = runCatching {
        val response = transport.execute(TransportRequest(url))
        response.body.use { body ->
            if (response.status !in 200..299) null
            else ManifestParser.release(String(body.readBytes(), Charsets.UTF_8))
        }
    }.getOrNull()
}

class GitHubReleaseFeed(private val ownerRepo: String, private val transport: HttpTransport) : ReleaseFeed {
    override fun latest(): Release? = runCatching {
        val response = transport.execute(TransportRequest("https://api.github.com/repos/$ownerRepo/releases?per_page=30"))
        response.body.use { body ->
            if (response.status !in 200..299) null
            else GitHubReleaseParser.releases(String(body.readBytes(), Charsets.UTF_8)).maxWithOrNull { a, b -> VersionComparer.compare(a.version, b.version) ?: 0 }
        }
    }.getOrNull()
}

object ManifestParser {
    private fun field(source: String, name: String): String? = Regex("\\\"$name\\\"\\s*:\\s*\\\"((?:\\\\.|[^\\\"\\\\])*)\\\"").find(source)?.groupValues?.get(1)
        ?.replace("\\n", "\n")?.replace("\\\"", "\"")?.replace("\\\\", "\\")

    fun release(source: String): Release? {
        if (!source.trim().startsWith("{") || !source.trim().endsWith("}")) return null
        val version = field(source, "version") ?: return null
        val notes = field(source, "notes") ?: return null
        val url = field(source, "url") ?: return null
        val sha = field(source, "sha256") ?: return null
        return Release(version, notes, url, sha).takeIf { VersionComparer.parse(it.version) != null && it.sha256.matches(Regex("[A-Fa-f0-9]{64}")) }
    }
}

object GitHubReleaseParser {
    fun releases(source: String): List<Release> {
        val tags = Regex("\\\"tag_name\\\"\\s*:").findAll(source).toList()
        return tags.mapIndexedNotNull { index, tagMatch ->
        val start = source.lastIndexOf('{', tagMatch.range.first).takeIf { it >= 0 } ?: return@mapIndexedNotNull null
        val end = tags.getOrNull(index + 1)?.range?.first ?: source.length
        val block = source.substring(start, end)
        val tag = Regex("\\\"tag_name\\\"\\s*:\\s*\\\"([^\\\"]+)\\\"").find(block)?.groupValues?.get(1) ?: return@mapIndexedNotNull null
        if (VersionComparer.parse(tag) == null || Regex("\\\"(?:draft|prerelease)\\\"\\s*:\\s*true").containsMatchIn(block)) return@mapIndexedNotNull null
        val url = Regex("\\\"browser_download_url\\\"\\s*:\\s*\\\"([^\\\"]+\\.(?:msi|exe))\\\"").find(block)?.groupValues?.get(1) ?: return@mapIndexedNotNull null
        val digest = Regex("\\\"digest\\\"\\s*:\\s*\\\"sha256:([A-Fa-f0-9]{64})\\\"").find(block)?.groupValues?.get(1)
            ?: Regex("\\\"sha256\\\"\\s*:\\s*\\\"([A-Fa-f0-9]{64})\\\"").find(block)?.groupValues?.get(1) ?: return@mapIndexedNotNull null
        Release(tag.removePrefix("windows-v"), "", url, digest)
        }
    }
}
