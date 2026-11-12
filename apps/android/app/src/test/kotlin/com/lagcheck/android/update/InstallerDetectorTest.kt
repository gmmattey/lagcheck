package com.lagcheck.android.update

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class InstallerDetectorTest {

    @Test
    fun isStoreInstallerRecognizesGooglePlay() {
        assertThat(InstallerDetector.isStoreInstaller("com.android.vending")).isTrue()
    }

    @Test
    fun isStoreInstallerRecognizesAmazonAndSamsung() {
        assertThat(InstallerDetector.isStoreInstaller("com.amazon.venezia")).isTrue()
        assertThat(InstallerDetector.isStoreInstaller("com.sec.android.app.samsungapps")).isTrue()
    }

    @Test
    fun isStoreInstallerRejectsNullBlankAndPackageInstaller() {
        assertThat(InstallerDetector.isStoreInstaller(null)).isFalse()
        assertThat(InstallerDetector.isStoreInstaller("")).isFalse()
        assertThat(InstallerDetector.isStoreInstaller("com.google.android.packageinstaller")).isFalse()
        assertThat(InstallerDetector.isStoreInstaller("com.android.packageinstaller")).isFalse()
        assertThat(InstallerDetector.isStoreInstaller("org.mozilla.firefox")).isFalse()
        assertThat(InstallerDetector.isStoreInstaller("com.whatsapp")).isFalse()
    }
}
