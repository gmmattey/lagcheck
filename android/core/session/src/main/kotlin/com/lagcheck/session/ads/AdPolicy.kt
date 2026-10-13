package com.lagcheck.session.ads

/** Onde um banner pode aparecer. Nenhuma outra tela reserva espaço de anúncio. */
enum class AdPlacement { HOME, HISTORY }

/** Contexto avaliado pela política de anúncios. JVM puro: não conhece SDK nem UI. */
data class AdContext(
    /** Chave de build: desligada no beta; liga só quando o MVP1.1 for autorizado. */
    val enabled: Boolean,
    /** Tela atual como posição de banner; `null` para qualquer tela fora de Home e Histórico. */
    val placement: AdPlacement?,
    /** Resultado do consentimento (UMP): sem isso não há requisição de anúncio. */
    val canRequestAds: Boolean,
    /** Há um check em andamento (pré-leitura, repouso, carga ou consentimento de dados móveis). */
    val measuring: Boolean
)

/** Regras que não mudam: só Home e Histórico, nunca durante a medição, nunca sem consentimento. */
object AdPolicy {
    fun shouldShowBanner(context: AdContext): Boolean =
        context.enabled && context.placement != null && context.canRequestAds && !context.measuring
}
