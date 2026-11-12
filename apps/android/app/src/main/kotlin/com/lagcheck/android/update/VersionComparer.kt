package com.lagcheck.android.update

data class ParsedVersion(
    val major: Int,
    val minor: Int,
    val patch: Int = 0,
    val buildNumber: Int? = null
) : Comparable<ParsedVersion> {
    override fun compareTo(other: ParsedVersion): Int {
        if (major != other.major) return major.compareTo(other.major)
        if (minor != other.minor) return minor.compareTo(other.minor)
        if (patch != other.patch) return patch.compareTo(other.patch)
        if (buildNumber != null && other.buildNumber != null) {
            return buildNumber.compareTo(other.buildNumber)
        }
        return 0
    }
}

object VersionComparer {
    // Reconhece formatos como: "1.0", "v1.1", "android-v1.1-b6", "1.2.0-b14", "2.0.1"
    private val TAG_REGEX = Regex("^(?:android-v|windows-v|v)?(\\d+)\\.(\\d+)(?:\\.(\\d+))?(?:-b(\\d+))?$", RegexOption.IGNORE_CASE)

    fun parse(raw: String): ParsedVersion? {
        val match = TAG_REGEX.matchEntire(raw.trim()) ?: return null
        val (majorStr, minorStr, patchStr, buildStr) = match.destructured
        val major = majorStr.toIntOrNull() ?: return null
        val minor = minorStr.toIntOrNull() ?: return null
        val patch = if (patchStr.isNotBlank()) patchStr.toIntOrNull() ?: 0 else 0
        val build = if (buildStr.isNotBlank()) buildStr.toIntOrNull() else null
        return ParsedVersion(major, minor, patch, build)
    }

    fun isNewer(
        candidateVersion: String,
        installedVersion: String,
        candidateBuild: Int? = null,
        installedBuild: Int? = null
    ): Boolean {
        val candParsed = parse(candidateVersion)?.let {
            if (candidateBuild != null && it.buildNumber == null) it.copy(buildNumber = candidateBuild) else it
        } ?: return false

        val instParsed = parse(installedVersion)?.let {
            if (installedBuild != null && it.buildNumber == null) it.copy(buildNumber = installedBuild) else it
        } ?: return false

        return candParsed > instParsed
    }
}
