package com.lagcheck.android.update

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.google.android.play.core.appupdate.AppUpdateInfo
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File

sealed interface AppUpdateUiState {
    object Idle : AppUpdateUiState
    object Checking : AppUpdateUiState
    data class UpdateAvailable(
        val release: AppRelease?,
        val isFromStore: Boolean,
        val currentVersion: String,
        val newVersion: String,
        val releaseNotes: String,
        val downloadSize: Long,
        val canAutoDownload: Boolean
    ) : AppUpdateUiState
    data class Downloading(
        val progressPercent: Int,
        val bytesDownloaded: Long,
        val totalBytes: Long
    ) : AppUpdateUiState
    data class ReadyToInstall(
        val apkFile: File,
        val isFromStore: Boolean
    ) : AppUpdateUiState
    data class NeedsInstallPermission(
        val apkFile: File
    ) : AppUpdateUiState
    data class UpToDate(val version: String) : AppUpdateUiState
    data class Error(val message: String) : AppUpdateUiState
}

class AppUpdateCoordinator(
    private val context: Context? = null,
    private val scope: CoroutineScope,
    private val installedVersionName: String,
    private val installedVersionCode: Int,
    private val isStoreInstall: Boolean = context?.let { InstallerDetector.isInstalledFromStore(it) } ?: false,
    private val releaseFeed: ReleaseFeed = GitHubReleaseFeed(
        ownerRepo = "gmmattey/lagcheck",
        installedVersion = installedVersionName,
        installedBuild = installedVersionCode
    ),
    private val downloader: ApkDownloader = ApkDownloader(File(context?.cacheDir ?: File(System.getProperty("java.io.tmpdir") ?: "/tmp"), "updates")),
    private val playStoreManager: PlayStoreUpdateManager? = context?.let { PlayStoreUpdateManager(it) },
    private val canInstallPackagesProvider: () -> Boolean = { context?.let { ApkInstaller.canInstallPackages(it) } ?: true },
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) {

    private val _uiState = MutableStateFlow<AppUpdateUiState>(AppUpdateUiState.Idle)
    val uiState: StateFlow<AppUpdateUiState> = _uiState.asStateFlow()

    private var cachedPlayUpdateInfo: AppUpdateInfo? = null
    private var cachedRelease: AppRelease? = null
    private var downloadJob: Job? = null
    private var lastCheckedTimestamp: Long = 0L

    companion object {
        private const val CHECK_INTERVAL_MS = 60 * 60 * 1000L // 1 hora entre checks automáticos
    }

    fun checkForUpdates(manual: Boolean = false) {
        val now = System.currentTimeMillis()
        if (!manual && (now - lastCheckedTimestamp < CHECK_INTERVAL_MS) && _uiState.value !is AppUpdateUiState.Idle) {
            return
        }

        scope.launch(ioDispatcher) {
            _uiState.value = AppUpdateUiState.Checking
            lastCheckedTimestamp = now

            if (isStoreInstall) {
                // Fluxo para usuários que instalaram da Play Store
                val playInfo = playStoreManager?.checkPlayStoreUpdate()
                cachedPlayUpdateInfo = playInfo

                if (playInfo != null) {
                    val availableVersion = playInfo.availableVersionCode().toString()
                    _uiState.value = AppUpdateUiState.UpdateAvailable(
                        release = null,
                        isFromStore = true,
                        currentVersion = installedVersionName,
                        newVersion = availableVersion,
                        releaseNotes = "",
                        downloadSize = playInfo.totalBytesToDownload(),
                        canAutoDownload = true
                    )
                } else {
                    // Também confere se há release mais recente no feed caso a Play Store não tenha reportado
                    val feedRelease = runCatching { releaseFeed.fetchLatestRelease() }.getOrNull()
                    if (feedRelease != null) {
                        cachedRelease = feedRelease
                        _uiState.value = AppUpdateUiState.UpdateAvailable(
                            release = feedRelease,
                            isFromStore = true,
                            currentVersion = installedVersionName,
                            newVersion = feedRelease.versionName,
                            releaseNotes = feedRelease.releaseNotes,
                            downloadSize = feedRelease.apkSize,
                            canAutoDownload = false // Redireciona para loja
                        )
                    } else {
                        _uiState.value = if (manual) AppUpdateUiState.UpToDate(installedVersionName) else AppUpdateUiState.Idle
                    }
                }
            } else {
                // Fluxo principal para APK direto / Sideload
                val feedRelease = runCatching { releaseFeed.fetchLatestRelease() }.getOrNull()
                if (feedRelease != null) {
                    cachedRelease = feedRelease
                    _uiState.value = AppUpdateUiState.UpdateAvailable(
                        release = feedRelease,
                        isFromStore = false,
                        currentVersion = installedVersionName,
                        newVersion = feedRelease.versionName,
                        releaseNotes = feedRelease.releaseNotes,
                        downloadSize = feedRelease.apkSize,
                        canAutoDownload = feedRelease.isApkAsset
                    )
                } else {
                    _uiState.value = if (manual) AppUpdateUiState.UpToDate(installedVersionName) else AppUpdateUiState.Idle
                }
            }
        }
    }

    fun startUpdate(activity: Activity) {
        val currentState = _uiState.value as? AppUpdateUiState.UpdateAvailable ?: return

        if (currentState.isFromStore) {
            val playInfo = cachedPlayUpdateInfo
            if (playInfo != null && playStoreManager != null) {
                playStoreManager.startFlexibleUpdate(
                    activity = activity,
                    updateInfo = playInfo,
                    onDownloadCompleted = {
                        _uiState.value = AppUpdateUiState.ReadyToInstall(File(""), isFromStore = true)
                    },
                    onFailed = {
                        PlayStoreUpdateManager.openPlayStorePage(activity)
                    }
                )
            } else {
                // Direciona direto para a Play Store
                PlayStoreUpdateManager.openPlayStorePage(activity)
            }
            return
        }

        // Fluxo APK: download transparente
        val release = cachedRelease ?: return
        if (!release.isApkAsset || release.apkDownloadUrl.isBlank()) {
            openInBrowser(activity, release.apkDownloadUrl)
            return
        }

        downloadJob?.cancel()
        downloadJob = scope.launch(ioDispatcher) {
            _uiState.value = AppUpdateUiState.Downloading(
                progressPercent = 0,
                bytesDownloaded = 0L,
                totalBytes = release.apkSize
            )

            val result = downloader.download(
                downloadUrl = release.apkDownloadUrl,
                targetFileName = release.apkFileName.ifBlank { "lagcheck-update.apk" },
                onProgress = { progress ->
                    _uiState.value = AppUpdateUiState.Downloading(
                        progressPercent = progress.percentage,
                        bytesDownloaded = progress.bytesDownloaded,
                        totalBytes = progress.totalBytes
                    )
                }
            )

            result.fold(
                onSuccess = { apkFile ->
                    if (canInstallPackagesProvider()) {
                        _uiState.value = AppUpdateUiState.ReadyToInstall(apkFile, isFromStore = false)
                        context?.let { ApkInstaller.installApk(it, apkFile) }
                    } else {
                        _uiState.value = AppUpdateUiState.NeedsInstallPermission(apkFile)
                    }
                },
                onFailure = { error ->
                    _uiState.value = AppUpdateUiState.Error(error.message ?: "Falha ao baixar o arquivo da atualização")
                }
            )
        }
    }

    fun proceedWithInstallation(apkFile: File) {
        val ctx = context ?: return
        if (canInstallPackagesProvider()) {
            _uiState.value = AppUpdateUiState.ReadyToInstall(apkFile, isFromStore = false)
            ApkInstaller.installApk(ctx, apkFile)
        } else {
            ctx.startActivity(ApkInstaller.requestInstallPermissionIntent(ctx))
        }
    }

    fun completeStoreUpdate() {
        playStoreManager?.completeUpdate()
    }

    fun cancelDownload() {
        downloadJob?.cancel()
        downloadJob = null
        val release = cachedRelease
        if (release != null) {
            _uiState.value = AppUpdateUiState.UpdateAvailable(
                release = release,
                isFromStore = isStoreInstall,
                currentVersion = installedVersionName,
                newVersion = release.versionName,
                releaseNotes = release.releaseNotes,
                downloadSize = release.apkSize,
                canAutoDownload = release.isApkAsset
            )
        } else {
            _uiState.value = AppUpdateUiState.Idle
        }
    }

    fun dismissUpdatePrompt() {
        _uiState.value = AppUpdateUiState.Idle
    }

    fun openInBrowser(context: Context, url: String? = null) {
        val target = url ?: cachedRelease?.apkDownloadUrl ?: "https://github.com/gmmattey/lagcheck/releases"
        runCatching {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(target)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        }
    }

    fun openStore(context: Context) {
        PlayStoreUpdateManager.openPlayStorePage(context)
    }
}
