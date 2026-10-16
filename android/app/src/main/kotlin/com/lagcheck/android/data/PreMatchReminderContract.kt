package com.lagcheck.android.data

/** Pure state contract for the local reminder; Android framework delivery is tested on device. */
data class PreMatchReminderState(val enabled: Boolean, val gameId: String?, val hour: Int = 20, val minute: Int = 0, val permissionDenied: Boolean = false) {
    fun scheduled(gameId: String, hour: Int, minute: Int) = copy(enabled = true, gameId = gameId, hour = hour, minute = minute, permissionDenied = false)
    fun disabled(permissionDenied: Boolean = false) = copy(enabled = false, gameId = null, permissionDenied = permissionDenied)
    fun invalidated(available: Set<String>) = if (enabled && gameId !in available) disabled() else this
    fun permissionRevoked() = disabled(permissionDenied = true)
}
