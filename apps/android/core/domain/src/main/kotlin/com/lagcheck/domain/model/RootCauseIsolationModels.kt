package com.lagcheck.domain.model

import java.util.Date

enum class CulpritEntity(val rawValue: String) {
    LOCAL_WIFI("localWiFi"),
    INTERNET_PROVIDER("internetProvider"),
    GAME_PLATFORM("gamePlatform"),
    ALL_CLEAR("allClear"),
    UNOBSERVABLE("unobservable");

    companion object {
        fun fromRaw(raw: String): CulpritEntity? = entries.firstOrNull { it.rawValue == raw }
    }
}

data class RootCauseIsolationReport(
    val primaryCulprit: CulpritEntity,
    val localGatewayRTTMs: Double?,
    val localGatewayPacketLoss: Double,
    val localGatewayObservable: Boolean,
    val wanMedianRTTMs: Double?,
    val wanJitterMs: Double?,
    val wanPacketLoss: Double,
    val platformDegraded: Boolean,
    val platformServiceName: String?,
    val evaluatedAt: Date = Date()
)
