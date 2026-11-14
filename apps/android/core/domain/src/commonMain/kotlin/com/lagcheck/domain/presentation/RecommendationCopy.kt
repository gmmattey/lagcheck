package com.lagcheck.domain.presentation

import com.lagcheck.domain.model.LocalizedRecommendation
import com.lagcheck.domain.model.RecommendationKey

/**
 * Textos das recomendações. PT-BR vem do iOS (`EvidenceRecommendationEngine`). EN e ES foram escritos para o Android e
 * seguem `docs/07-voz-do-produto.md`: precisam da revisão de voz do Marco antes de release.
 * O texto de perda de pacotes não nomeia a operadora: sem probe isolado do gateway, isso seria acusação sem evidência.
 */
internal object RecommendationCopy {
    private data class Row(val title: String, val instruction: String, val badge: String)

    private val pt = mapOf(
        RecommendationKey.APPROACH_ROUTER to Row("Aproxime-se do Roteador", "Reduza a distância física ou obstáculos para eliminar a oscilação do sinal local.", "Wi-Fi Local"),
        RecommendationKey.SWITCH_TO_5GHZ to Row("Troque para Wi-Fi 5 GHz", "Conecte-se na frequência 5 GHz para escapar da interferência de canais vizinhos.", "2.4 GHz Detectado"),
        RecommendationKey.AVOID_RANKED to Row("Evite Partidas Ranqueadas", "A rota até o destino apresenta perda de pacotes e causará travamentos.", "Rota Externa"),
        RecommendationKey.PAUSE_DOWNLOADS to Row("Pause Downloads e Streaming", "Limite o uso simultâneo da internet para impedir picos de latência na partida.", "Saturação sob Carga"),
        RecommendationKey.CHECK_LOCAL_INTERFERENCE to Row("Verifique Interferências Locais", "Afaste dispositivos sem fio e fontes de interferência eletromagnética do roteador.", "Picos Recorrentes"),
        RecommendationKey.ENABLE_UPNP to Row("Habilite UPnP no Roteador", "Libere as portas automáticas no roteador para normalizar a conexão em partidas multiplayer.", "NAT Restrito"),
        RecommendationKey.ROUTE_INSTABILITY to Row("Instabilidade de Rota na Operadora", "Contate seu provedor para verificar o roteamento caso os micro-travamentos persistam.", "Rota Desordenada")
    )

    private val en = mapOf(
        RecommendationKey.APPROACH_ROUTER to Row("Move closer to the router", "Cut the distance or obstacles to stop the local signal from wobbling.", "Local Wi-Fi"),
        RecommendationKey.SWITCH_TO_5GHZ to Row("Switch to 5 GHz Wi-Fi", "Connect on 5 GHz to get away from neighbor-channel interference.", "2.4 GHz detected"),
        RecommendationKey.AVOID_RANKED to Row("Skip ranked matches", "The route to the destination is losing packets and will cause freezes.", "External route"),
        RecommendationKey.PAUSE_DOWNLOADS to Row("Pause downloads and streaming", "Limit other internet use to stop latency spikes in your match.", "Saturation under load"),
        RecommendationKey.CHECK_LOCAL_INTERFERENCE to Row("Check local interference", "Move wireless devices and electromagnetic interference away from the router.", "Recurring spikes"),
        RecommendationKey.ENABLE_UPNP to Row("Enable UPnP on the router", "Open automatic ports on the router to normalize multiplayer connections.", "Strict NAT"),
        RecommendationKey.ROUTE_INSTABILITY to Row("Route instability at the ISP", "Contact your provider to check routing if the micro-stutters persist.", "Out-of-order route")
    )

    private val es = mapOf(
        RecommendationKey.APPROACH_ROUTER to Row("Acércate al router", "Reduce la distancia o los obstáculos para eliminar la oscilación de la señal local.", "Wi-Fi local"),
        RecommendationKey.SWITCH_TO_5GHZ to Row("Cambia a Wi-Fi de 5 GHz", "Conéctate en 5 GHz para escapar de la interferencia de canales vecinos.", "2.4 GHz detectado"),
        RecommendationKey.AVOID_RANKED to Row("Evita partidas clasificatorias", "La ruta hasta el destino pierde paquetes y causará congelamientos.", "Ruta externa"),
        RecommendationKey.PAUSE_DOWNLOADS to Row("Pausa descargas y streaming", "Limita el uso simultáneo de internet para evitar picos de latencia en la partida.", "Saturación bajo carga"),
        RecommendationKey.CHECK_LOCAL_INTERFERENCE to Row("Revisa interferencias locales", "Aleja dispositivos inalámbricos y fuentes de interferencia electromagnética del router.", "Picos recurrentes"),
        RecommendationKey.ENABLE_UPNP to Row("Activa UPnP en el router", "Libera los puertos automáticos del router para normalizar las partidas multijugador.", "NAT restrictivo"),
        RecommendationKey.ROUTE_INSTABILITY to Row("Inestabilidad de ruta en el proveedor", "Contacta a tu proveedor para revisar el enrutamiento si los micro-tirones persisten.", "Ruta desordenada")
    )

    fun localize(key: RecommendationKey, language: ReadinessLanguage): LocalizedRecommendation {
        val row = when (language) {
            ReadinessLanguage.PT_BR -> pt
            ReadinessLanguage.EN -> en
            ReadinessLanguage.ES -> es
        }.getValue(key)
        return LocalizedRecommendation(row.title, row.instruction, row.badge)
    }
}
