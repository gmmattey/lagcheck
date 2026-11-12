package com.lagcheck.android.update

import java.net.HttpURLConnection
import java.net.URL

data class AppRelease(
    val tagName: String,
    val versionName: String,
    val buildNumber: Int?,
    val releaseNotes: String,
    val apkDownloadUrl: String,
    val apkFileName: String,
    val apkSize: Long,
    val publishedAt: String?,
    val isApkAsset: Boolean
)

interface ReleaseFeed {
    suspend fun fetchLatestRelease(): AppRelease?
}

object GitHubReleaseParser {

    private fun extractJsonString(block: String, key: String): String? {
        val regex = Regex("\"$key\"\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"")
        return regex.find(block)?.groupValues?.get(1)
            ?.replace("\\n", "\n")
            ?.replace("\\\"", "\"")
            ?.replace("\\\\", "\\")
    }

    private fun extractJsonLong(block: String, key: String): Long? {
        val regex = Regex("\"$key\"\\s*:\\s*(\\d+)")
        return regex.find(block)?.groupValues?.get(1)?.toLongOrNull()
    }

    private fun extractJsonBoolean(block: String, key: String): Boolean {
        val regex = Regex("\"$key\"\\s*:\\s*(true|false)")
        return regex.find(block)?.groupValues?.get(1)?.toBooleanStrictOrNull() ?: false
    }

    fun parseReleases(jsonSource: String): List<AppRelease> {
        val releases = mutableListOf<AppRelease>()
        val tagMatches = Regex("\"tag_name\"\\s*:").findAll(jsonSource).toList()

        tagMatches.forEachIndexed { index, tagMatch ->
            val start = jsonSource.lastIndexOf('{', tagMatch.range.first).takeIf { it >= 0 } ?: return@forEachIndexed
            val nextStart = tagMatches.getOrNull(index + 1)?.range?.first ?: jsonSource.length
            val end = jsonSource.lastIndexOf('}', nextStart).takeIf { it > start }?.plus(1) ?: nextStart
            val block = jsonSource.substring(start, end)

            val isDraft = extractJsonBoolean(block, "draft")
            if (isDraft) return@forEachIndexed

            val tagName = extractJsonString(block, "tag_name")?.trim() ?: return@forEachIndexed
            if (tagName.isEmpty()) return@forEachIndexed

            // Ignora releases explicitamente desktop (ex: windows-v*)
            if (tagName.startsWith("windows-", ignoreCase = true)) return@forEachIndexed

            val parsedVersion = VersionComparer.parse(tagName)
            val body = extractJsonString(block, "body") ?: ""
            val publishedAt = extractJsonString(block, "published_at")
            val releaseHtmlUrl = extractJsonString(block, "html_url") ?: ""

            // Encontra assets do bloco
            var chosenApkUrl = ""
            var chosenApkName = ""
            var chosenApkSize = 0L
            var foundApk = false

            val assetBlocks = block.split(Regex("\"name\"\\s*:"))
            for (i in 1 until assetBlocks.size) {
                val assetPart = assetBlocks[i]
                val assetNameMatch = Regex("^\\s*\"([^\"]+)\"").find(assetPart) ?: continue
                val assetName = assetNameMatch.groupValues[1]

                if (assetName.endsWith(".apk", ignoreCase = true)) {
                    val downloadUrl = extractJsonString(assetPart, "browser_download_url") ?: ""
                    val size = extractJsonLong(assetPart, "size") ?: 0L
                    val isProduction = assetName.contains("production", ignoreCase = true)

                    if (downloadUrl.isNotEmpty()) {
                        if (!foundApk || isProduction) {
                            chosenApkUrl = downloadUrl
                            chosenApkName = assetName
                            chosenApkSize = size
                            foundApk = true
                            if (isProduction) break
                        }
                    }
                }
            }

            val isAndroidRelease = tagName.startsWith("android-", ignoreCase = true) || foundApk
            if (!isAndroidRelease) return@forEachIndexed

            val downloadUrl = if (foundApk) chosenApkUrl else releaseHtmlUrl
            val fileName = if (foundApk) chosenApkName else "$tagName.apk"
            val versionName = parsedVersion?.let { "${it.major}.${it.minor}${if (it.patch > 0) ".${it.patch}" else ""}" } ?: tagName
            val buildNumber = parsedVersion?.buildNumber

            releases.add(
                AppRelease(
                    tagName = tagName,
                    versionName = versionName,
                    buildNumber = buildNumber,
                    releaseNotes = body,
                    apkDownloadUrl = downloadUrl,
                    apkFileName = fileName,
                    apkSize = chosenApkSize,
                    publishedAt = publishedAt,
                    isApkAsset = foundApk
                )
            )
        }

        return releases
    }

    fun findLatest(releases: List<AppRelease>, installedVersion: String, installedBuild: Int? = null): AppRelease? {
        return releases
            .filter { release ->
                VersionComparer.isNewer(
                    candidateVersion = release.versionName,
                    installedVersion = installedVersion,
                    candidateBuild = release.buildNumber,
                    installedBuild = installedBuild
                )
            }
            .maxWithOrNull { a, b ->
                val vA = VersionComparer.parse(a.tagName) ?: VersionComparer.parse(a.versionName)
                val vB = VersionComparer.parse(b.tagName) ?: VersionComparer.parse(b.versionName)
                when {
                    vA != null && vB != null -> vA.compareTo(vB)
                    else -> 0
                }
            }
    }
}

class GitHubReleaseFeed(
    private val ownerRepo: String = "gmmattey/lagcheck",
    private val installedVersion: String,
    private val installedBuild: Int? = null,
    private val httpFetcher: (String) -> String? = { urlString ->
        runCatching {
            val url = URL(urlString)
            val conn = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 8000
                readTimeout = 8000
                requestMethod = "GET"
                setRequestProperty("Accept", "application/vnd.github.v3+json")
                setRequestProperty("User-Agent", "LagCheck-Android/$installedVersion")
            }
            conn.inputStream.use { it.bufferedReader().readText() }
        }.getOrNull()
    }
) : ReleaseFeed {

    override suspend fun fetchLatestRelease(): AppRelease? {
        val url = "https://api.github.com/repos/$ownerRepo/releases?per_page=15"
        val response = httpFetcher(url) ?: return null
        val releases = GitHubReleaseParser.parseReleases(response)
        return GitHubReleaseParser.findLatest(releases, installedVersion, installedBuild)
    }
}
