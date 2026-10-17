package com.lagcheck.network.preflight

import com.lagcheck.catalog.RouteIdentity
import com.lagcheck.network.codec.SteamQueryA2sCodec

/**
 * Máquina pura da pré-validação de identidade (`steam-a2s-preflight-1`), espelho de `SteamA2SPreflightMachine` do iOS.
 * Não abre socket: recebe datagramas (ou `null` para timeout) e diz o próximo passo. Uma única troca de challenge é
 * aceita; resposta ambígua, truncada ou de identidade divergente rejeita a rota e devolve a medição à AWS assinada.
 */
class SteamA2sPreflightMachine(private val identity: RouteIdentity) {
    sealed interface Step {
        class Send(val payload: ByteArray) : Step
        data object Accept : Step
        data object Reject : Step
    }

    private enum class Phase { AWAITING_FIRST_RESPONSE, AWAITING_INFO_AFTER_CHALLENGE, FINISHED }

    private var phase = Phase.AWAITING_FIRST_RESPONSE

    /** Primeiro datagrama a enviar: A2S_INFO sem challenge. */
    val initialRequest: ByteArray get() = SteamQueryA2sCodec.encodeInitialRequest()

    fun receive(datagram: ByteArray?): Step {
        if (datagram == null || phase == Phase.FINISHED) return finish(false)
        if (phase == Phase.AWAITING_FIRST_RESPONSE && SteamQueryA2sCodec.isChallengeResponse(datagram)) {
            val token = SteamQueryA2sCodec.decodeChallenge(datagram) ?: return finish(false)
            phase = Phase.AWAITING_INFO_AFTER_CHALLENGE
            return Step.Send(SteamQueryA2sCodec.encodeAuthenticatedRequest(token))
        }
        val info = SteamQueryA2sCodec.decodeInfo(datagram) ?: return finish(false)
        val nameMatches = identity.serverNamePrefix?.let { info.name.startsWith(it) } ?: true
        return finish(info.appId == identity.appId && info.gameDirectory == identity.gameDirectory && nameMatches)
    }

    private fun finish(accepted: Boolean): Step {
        phase = Phase.FINISHED
        return if (accepted) Step.Accept else Step.Reject
    }
}
