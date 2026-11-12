package com.lagcheck.android.update

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class GitHubReleaseParserTest {

    private val sampleJson = """
    [
      {
        "tag_name": "windows-v0.1.0",
        "name": "LagCheck Windows v0.1.0",
        "draft": false,
        "prerelease": false,
        "body": "Versão windows",
        "assets": [
          {
            "name": "lagcheck-windows.msi",
            "browser_download_url": "https://example.com/lagcheck.msi",
            "size": 50000000
          }
        ]
      },
      {
        "tag_name": "android-v1.1-b6",
        "name": "LagCheck Android 1.1",
        "draft": false,
        "prerelease": false,
        "published_at": "2026-11-08T22:50:58Z",
        "body": "Melhorias no diagnóstico e estabilidade.",
        "assets": [
          {
            "name": "mapping.txt",
            "browser_download_url": "https://example.com/mapping.txt",
            "size": 120000
          },
          {
            "name": "lagcheck-android-production-v1.1-b6.apk",
            "browser_download_url": "https://github.com/gmmattey/lagcheck/releases/download/android-v1.1-b6/lagcheck-android-production-v1.1-b6.apk",
            "size": 18500000
          }
        ]
      },
      {
        "tag_name": "android-v1.2-b8",
        "name": "LagCheck Android 1.2",
        "draft": false,
        "prerelease": false,
        "published_at": "2026-11-12T10:00:00Z",
        "body": "Novo teste de rota e correções de layout.",
        "assets": [
          {
            "name": "lagcheck-android-production-v1.2-b8.apk",
            "browser_download_url": "https://github.com/gmmattey/lagcheck/releases/download/android-v1.2-b8/lagcheck-android-production-v1.2-b8.apk",
            "size": 19000000
          }
        ]
      }
    ]
    """.trimIndent()

    @Test
    fun parseReleasesIgnoresWindowsReleases() {
        val releases = GitHubReleaseParser.parseReleases(sampleJson)
        assertThat(releases.none { it.tagName.startsWith("windows") }).isTrue()
        assertThat(releases).hasSize(2)
    }

    @Test
    fun parseReleasesExtractsApkAssetInfo() {
        val releases = GitHubReleaseParser.parseReleases(sampleJson)
        val v11 = releases.first { it.tagName == "android-v1.1-b6" }
        assertThat(v11.versionName).isEqualTo("1.1")
        assertThat(v11.buildNumber).isEqualTo(6)
        assertThat(v11.isApkAsset).isTrue()
        assertThat(v11.apkFileName).isEqualTo("lagcheck-android-production-v1.1-b6.apk")
        assertThat(v11.apkSize).isEqualTo(18500000L)
        assertThat(v11.releaseNotes).isEqualTo("Melhorias no diagnóstico e estabilidade.")
    }

    @Test
    fun findLatestReturnsNewestAvailableRelease() {
        val releases = GitHubReleaseParser.parseReleases(sampleJson)
        val latestFor10 = GitHubReleaseParser.findLatest(releases, installedVersion = "1.0", installedBuild = 1)
        assertThat(latestFor10).isNotNull()
        assertThat(latestFor10?.tagName).isEqualTo("android-v1.2-b8")

        val latestFor11 = GitHubReleaseParser.findLatest(releases, installedVersion = "1.1", installedBuild = 6)
        assertThat(latestFor11).isNotNull()
        assertThat(latestFor11?.tagName).isEqualTo("android-v1.2-b8")

        val latestFor12 = GitHubReleaseParser.findLatest(releases, installedVersion = "1.2", installedBuild = 8)
        assertThat(latestFor12).isNull()
    }
}
