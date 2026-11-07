package com.lagcheck.desktop.update

object VersionComparer {
    private val version = Regex("^(?:windows-v)?(\\d+)\\.(\\d+)(?:\\.(\\d+))?$")

    fun compare(left: String, right: String): Int? {
        val l = parse(left) ?: return null
        val r = parse(right) ?: return null
        return l.zip(r).firstOrNull { it.first != it.second }?.let { it.first.compareTo(it.second) } ?: 0
    }

    fun isNewer(candidate: String, installed: String): Boolean = (compare(candidate, installed) ?: 0) > 0
    fun parse(value: String): List<Int>? = version.matchEntire(value.trim())?.destructured?.let { (major, minor, patch) ->
        listOf(major.toIntOrNull() ?: return null, minor.toIntOrNull() ?: return null, patch.ifBlank { "0" }.toIntOrNull() ?: return null)
    }
}
