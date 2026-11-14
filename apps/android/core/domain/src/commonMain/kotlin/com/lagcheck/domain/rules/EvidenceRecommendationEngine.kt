package com.lagcheck.domain.rules

import com.lagcheck.domain.model.ActionableRecommendation
import com.lagcheck.domain.model.GameServerArchitecture
import com.lagcheck.domain.model.GatewayProbeOutcome
import com.lagcheck.domain.model.NatType
import com.lagcheck.domain.model.RecommendationKey
import com.lagcheck.domain.model.SpikePattern
import com.lagcheck.domain.model.WiFiBandConfidence
import com.lagcheck.domain.model.WiFiBandDiagnostic

data class DiagnosticEvidence(
    val gatewayOutcome: GatewayProbeOutcome = GatewayProbeOutcome.Unobservable,
    val wifiBand: WiFiBandDiagnostic? = null,
    val wifiBandConfidence: WiFiBandConfidence? = null,
    val loadTier: LoadDegradationTier? = null,
    val packetLossPercentage: Double = 0.0,
    val spikePattern: SpikePattern? = null,
    val tailRatio: Double? = null,
    val natType: NatType? = null,
    val serverArchitecture: GameServerArchitecture = GameServerArchitecture.DEDICATED_SERVER,
    val outOfOrderCount: Int = 0
)

/** De 0 a 3 recomendações, cada uma amarrada a uma evidência comprovada (Decisão 55). */
object EvidenceRecommendationEngine {
    fun generate(e: DiagnosticEvidence): List<ActionableRecommendation> {
        val r = mutableListOf<ActionableRecommendation>()
        if (e.gatewayOutcome.isDegraded) r += ActionableRecommendation(1, RecommendationKey.APPROACH_ROUTER)
        if (e.wifiBand?.isSuspectOrConfirmed24GHz == true &&
            (e.wifiBandConfidence == WiFiBandConfidence.HIGH || e.wifiBandConfidence == WiFiBandConfidence.MEDIUM)
        ) r += ActionableRecommendation(1, RecommendationKey.SWITCH_TO_5GHZ)
        if (e.packetLossPercentage > 1.0 && !e.gatewayOutcome.isDegraded) r += ActionableRecommendation(1, RecommendationKey.AVOID_RANKED)
        if (e.loadTier == LoadDegradationTier.MATERIAL || e.loadTier == LoadDegradationTier.SEVERE) {
            r += ActionableRecommendation(2, RecommendationKey.PAUSE_DOWNLOADS)
        }
        if (e.spikePattern?.isRecurring == true && e.gatewayOutcome.isStable) r += ActionableRecommendation(2, RecommendationKey.CHECK_LOCAL_INTERFERENCE)
        if (e.natType == NatType.TYPE_3_STRICT &&
            (e.serverArchitecture == GameServerArchitecture.PEER_TO_PEER || e.serverArchitecture == GameServerArchitecture.HYBRID)
        ) r += ActionableRecommendation(2, RecommendationKey.ENABLE_UPNP)
        // Atribuir a rota/operadora exige primeiro salto comprovadamente limpo (Decisão 50). Gateway não observável não basta.
        if (e.outOfOrderCount >= 2 && e.gatewayOutcome.isStable) r += ActionableRecommendation(2, RecommendationKey.ROUTE_INSTABILITY)
        return r.sortedBy { it.priority }.take(3)
    }
}

/** Arquitetura de servidor por jogo (rede P2P/híbrida torna o NAT relevante). */
object GameArchitectureRegistry {
    // O iOS registra "ea-sports-fc-mobile", mas o id publicado no catálogo é "eafc": ambos valem aqui, senão a regra nunca dispara.
    private val hybrid = setOf("minecraft", "roblox", "ea-sports-fc-mobile", "eafc")

    fun serverArchitecture(gameId: String): GameServerArchitecture =
        if (gameId.lowercase() in hybrid) GameServerArchitecture.HYBRID else GameServerArchitecture.DEDICATED_SERVER
}
