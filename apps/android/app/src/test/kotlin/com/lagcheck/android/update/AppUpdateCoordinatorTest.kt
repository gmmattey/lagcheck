package com.lagcheck.android.update

import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.io.File

@OptIn(ExperimentalCoroutinesApi::class)
class AppUpdateCoordinatorTest {

    private val testDispatcher = StandardTestDispatcher()
    private val testScope = TestScope(testDispatcher)

    private val fakeRelease = AppRelease(
        tagName = "android-v1.2-b8",
        versionName = "1.2",
        buildNumber = 8,
        releaseNotes = "Notas de teste",
        apkDownloadUrl = "https://example.com/test.apk",
        apkFileName = "test.apk",
        apkSize = 20_000_000L,
        publishedAt = "2026-11-12T10:00:00Z",
        isApkAsset = true
    )

    private class FakeReleaseFeed(private val release: AppRelease?) : ReleaseFeed {
        override suspend fun fetchLatestRelease(): AppRelease? = release
    }

    @Test
    fun whenNewReleaseAvailableEmitsUpdateAvailableState() = testScope.runTest {
        val tempDir = File.createTempFile("lagcheck_test", "dir").apply {
            delete()
            mkdirs()
        }

        val feed = FakeReleaseFeed(fakeRelease)
        val coordinator = AppUpdateCoordinator(
            context = null,
            scope = this,
            installedVersionName = "1.0",
            installedVersionCode = 1,
            isStoreInstall = false,
            releaseFeed = feed,
            downloader = ApkDownloader(tempDir),
            ioDispatcher = testDispatcher
        )

        coordinator.checkForUpdates(manual = true)
        advanceUntilIdle()

        val state = coordinator.uiState.value
        assertThat(state).isInstanceOf(AppUpdateUiState.UpdateAvailable::class.java)
        val available = state as AppUpdateUiState.UpdateAvailable
        assertThat(available.newVersion).isEqualTo("1.2")
        assertThat(available.isFromStore).isFalse()
        assertThat(available.canAutoDownload).isTrue()

        coordinator.dismissUpdatePrompt()
        assertThat(coordinator.uiState.value).isEqualTo(AppUpdateUiState.Idle)

        tempDir.deleteRecursively()
    }

    @Test
    fun whenNoReleaseAvailableManualCheckEmitsUpToDate() = testScope.runTest {
        val tempDir = File.createTempFile("lagcheck_test", "dir2").apply {
            delete()
            mkdirs()
        }

        val feed = FakeReleaseFeed(null)
        val coordinator = AppUpdateCoordinator(
            context = null,
            scope = this,
            installedVersionName = "1.0",
            installedVersionCode = 1,
            isStoreInstall = false,
            releaseFeed = feed,
            downloader = ApkDownloader(tempDir),
            ioDispatcher = testDispatcher
        )

        coordinator.checkForUpdates(manual = true)
        advanceUntilIdle()

        assertThat(coordinator.uiState.value).isInstanceOf(AppUpdateUiState.UpToDate::class.java)

        tempDir.deleteRecursively()
    }
}
