package com.lagcheck.domain.rules

/** Leitura local mínima para chamada de voz: só classifica o primeiro salto quando houve RTT observável. */
object VoiceChatSuitabilityEvaluator {
    sealed class Assessment {
        data class Favorable(val localGatewayRttMs: Int) : Assessment()
        data class Attention(val localGatewayRttMs: Int) : Assessment()
        data object NotAssessed : Assessment()
    }

    fun assess(localGatewayRttMilliseconds: Double?): Assessment {
        val rtt = localGatewayRttMilliseconds
        if (rtt == null || !rtt.isFinite() || rtt < 0) return Assessment.NotAssessed
        val rounded = Math.round(rtt).toInt()
        return if (rtt <= 15.0) Assessment.Favorable(rounded) else Assessment.Attention(rounded)
    }
}
