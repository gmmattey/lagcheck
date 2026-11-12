package com.lagcheck.android.update

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class PlayStoreUpdateManager(
    private val context: Context,
    private val appUpdateManager: AppUpdateManager = AppUpdateManagerFactory.create(context)
) {

    suspend fun checkPlayStoreUpdate(): AppUpdateInfo? = suspendCancellableCoroutine { continuation ->
        runCatching {
            appUpdateManager.appUpdateInfo
                .addOnSuccessListener { info ->
                    if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE) {
                        continuation.resume(info)
                    } else {
                        continuation.resume(null)
                    }
                }
                .addOnFailureListener {
                    continuation.resume(null)
                }
        }.onFailure {
            continuation.resume(null)
        }
    }

    fun startFlexibleUpdate(
        activity: Activity,
        updateInfo: AppUpdateInfo,
        onDownloadCompleted: () -> Unit,
        onFailed: () -> Unit = {}
    ) {
        val listener = object : InstallStateUpdatedListener {
            override fun onStateUpdate(state: com.google.android.play.core.install.InstallState) {
                if (state.installStatus() == InstallStatus.DOWNLOADED) {
                    appUpdateManager.unregisterListener(this)
                    onDownloadCompleted()
                }
            }
        }

        appUpdateManager.registerListener(listener)

        val options = AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build()
        runCatching {
            appUpdateManager.startUpdateFlow(updateInfo, activity, options)
        }.onFailure {
            appUpdateManager.unregisterListener(listener)
            onFailed()
            openPlayStorePage(activity)
        }
    }

    fun completeUpdate() {
        runCatching {
            appUpdateManager.completeUpdate()
        }
    }

    companion object {
        fun openPlayStorePage(context: Context) {
            val packageName = context.packageName
            try {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName")).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            } catch (_: Exception) {
                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$packageName")).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(webIntent)
            }
        }
    }
}
