package com.lagcheck.android.update

import android.content.Context
import android.os.Build

object InstallerDetector {
    val GOOGLE_PLAY_INSTALLER = "com.android.vending"

    private val KNOWN_STORE_INSTALLERS = setOf(
        GOOGLE_PLAY_INSTALLER,
        "com.google.android.feedback",
        "com.amazon.venezia",
        "com.sec.android.app.samsungapps",
        "com.huawei.appmarket",
        "com.xiaomi.mipicks"
    )

    fun getInstallerPackage(context: Context): String? = runCatching {
        val pm = context.packageManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            pm.getInstallSourceInfo(context.packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            pm.getInstallerPackageName(context.packageName)
        }
    }.getOrNull()

    fun isInstalledFromStore(context: Context): Boolean {
        val installer = getInstallerPackage(context) ?: return false
        return isStoreInstaller(installer)
    }

    fun isStoreInstaller(installerPackage: String?): Boolean {
        if (installerPackage.isNullOrBlank()) return false
        return installerPackage in KNOWN_STORE_INSTALLERS
    }

    fun isInstalledFromGooglePlay(context: Context): Boolean {
        return getInstallerPackage(context) == GOOGLE_PLAY_INSTALLER
    }
}
