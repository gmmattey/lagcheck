package com.lagcheck.android.update

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class VersionComparerTest {

    @Test
    fun parseSimpleVersion() {
        val parsed = VersionComparer.parse("1.0")
        assertThat(parsed).isNotNull()
        assertThat(parsed?.major).isEqualTo(1)
        assertThat(parsed?.minor).isEqualTo(0)
        assertThat(parsed?.patch).isEqualTo(0)
        assertThat(parsed?.buildNumber).isNull()
    }

    @Test
    fun parseAndroidTagWithBuild() {
        val parsed = VersionComparer.parse("android-v1.1-b6")
        assertThat(parsed).isNotNull()
        assertThat(parsed?.major).isEqualTo(1)
        assertThat(parsed?.minor).isEqualTo(1)
        assertThat(parsed?.patch).isEqualTo(0)
        assertThat(parsed?.buildNumber).isEqualTo(6)
    }

    @Test
    fun parseThreePartVersion() {
        val parsed = VersionComparer.parse("v2.4.1-b42")
        assertThat(parsed).isNotNull()
        assertThat(parsed?.major).isEqualTo(2)
        assertThat(parsed?.minor).isEqualTo(4)
        assertThat(parsed?.patch).isEqualTo(1)
        assertThat(parsed?.buildNumber).isEqualTo(42)
    }

    @Test
    fun isNewerRecognizesHigherMinor() {
        assertThat(VersionComparer.isNewer("1.1", "1.0")).isTrue()
        assertThat(VersionComparer.isNewer("1.0", "1.1")).isFalse()
        assertThat(VersionComparer.isNewer("1.0", "1.0")).isFalse()
    }

    @Test
    fun isNewerRecognizesHigherMajor() {
        assertThat(VersionComparer.isNewer("2.0", "1.9")).isTrue()
        assertThat(VersionComparer.isNewer("1.9", "2.0")).isFalse()
    }

    @Test
    fun isNewerRecognizesHigherPatch() {
        assertThat(VersionComparer.isNewer("1.0.1", "1.0.0")).isTrue()
        assertThat(VersionComparer.isNewer("1.0.0", "1.0.1")).isFalse()
    }

    @Test
    fun isNewerRecognizesHigherBuildWhenVersionsEqual() {
        assertThat(VersionComparer.isNewer("android-v1.1-b7", "android-v1.1-b6")).isTrue()
        assertThat(VersionComparer.isNewer("android-v1.1-b6", "android-v1.1-b7")).isFalse()
        assertThat(VersionComparer.isNewer("android-v1.1-b6", "android-v1.1-b6")).isFalse()
    }

    @Test
    fun isNewerWithSeparateBuildNumbers() {
        assertThat(VersionComparer.isNewer("1.0", "1.0", candidateBuild = 10, installedBuild = 9)).isTrue()
        assertThat(VersionComparer.isNewer("1.0", "1.0", candidateBuild = 9, installedBuild = 10)).isFalse()
        assertThat(VersionComparer.isNewer("1.1", "1.0", candidateBuild = 1, installedBuild = 50)).isTrue()
    }

    @Test
    fun invalidVersionReturnsFalse() {
        assertThat(VersionComparer.isNewer("invalid", "1.0")).isFalse()
        assertThat(VersionComparer.isNewer("1.0", "invalid")).isFalse()
    }
}
