package com.lagcheck.domain.rules

import com.lagcheck.domain.model.CulpritEntity
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.QualityMetrics
import com.lagcheck.domain.model.RootCauseIsolationReport
import java.util.Date

object RootCauseEvaluator {
    const val VERSION = "root-cause-v1"

    fun evaluate(
        gatewayOutcome: GatewayProbeOutcome,
        wanMetrics: QualityMetrics,
        platformDegraded: Boolean,
        platformServiceName: String? = null,
        now: Date = Date()
    ): RootCauseIsolationReport {
        val gwObservable = gatewayOutcome !is GatewayProbeOutcome.Unobservable
        val gwRTT = when (gatewayOutcome) {
            is GatewayProbeOutcome.Stable -> gatewayOutcome.rttMilliseconds
            is GatewayProbeOutcome.Degraded -> gatewayOutcome.rttMilliseconds
            is GatewayProbeOutcome.Unobservable -> null
        }
        val gwLoss = when (gatewayOutcome) {
            is GatewayProbeOutcome.Degraded -> gatewayOutcome.lossPercentage
            else -> 0.0
        }

        val wanRTT = wanMetrics.p50Milliseconds
        val wanJitter = wanMetrics.jitterMilliseconds
        val wanLoss = wanMetrics.packetLossPercentage

        // 1. Regra Gateway / Wi-Fi Local (Architecture Plan §3.2 regra 1):
        val isLocalCulprit = gwObservable && ((gwRTT ?: 0.0) > 15.0 || gwLoss > 2.0)

        // 2. Regra Operadora / Rota Externa (Architecture Plan §3.2 regra 2):
        val isWanUnstable = wanLoss > 1.0 || (wanJitter ?: 0.0) > 15.0
        val isGatewayPristine = gwObservable && ((gwRTT ?: 0.0) <= 5.0 && gwLoss == 0.0)

        val culprit: CulpritEntity = when {
            isLocalCulprit -> CulpritEntity.LOCAL_WIFI
            (isGatewayPristine || !gwObservable) && isWanUnstable -> CulpritEntity.INTERNET_PROVIDER
            platformDegraded && !isWanUnstable -> CulpritEntity.GAME_PLATFORM
            isGatewayPristine && !isWanUnstable && !platformDegraded -> CulpritEntity.ALL_CLEAR
            else -> CulpritEntity.UNOBSERVABLE
        }

        return RootCauseIsolationReport(
            primaryCulprit = culprit,
            localGatewayRTTMs = gwRTT,
            localGatewayPacketLoss = gwLoss,
            localGatewayObservable = gwObservable,
            wanMedianRTTMs = wanRTT,
            wanJitterMs = wanJitter,
            wanPacketLoss = wanLoss,
            platformDegraded = platformDegraded,
            platformServiceName = platformServiceName,
            evaluatedAt = now
        )
    }
}
