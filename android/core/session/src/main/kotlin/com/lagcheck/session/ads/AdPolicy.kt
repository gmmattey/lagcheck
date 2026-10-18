package com.lagcheck.session.ads

/** Superfícies Android autorizadas para Native Advanced (Decisão 96). */
enum class AdPlacement { HOME, HISTORY, GAMES, RESULT }

/** Contexto avaliado pela política de anúncios. JVM puro: não conhece SDK nem UI. */
data class AdContext(
    /** Chave de build de publicidade. */
    val enabled: Boolean,
    /** `null` para Check, Detalhes, Configurações e demais telas excluídas. */
    val placement: AdPlacement?,
    /** Resultado do consentimento (UMP): sem isso não há requisição de anúncio. */
    val canRequestAds: Boolean,
    /** Há um check em andamento (pré-leitura, repouso, carga ou consentimento de dados móveis). */
    val measuring: Boolean
)

/** Native Advanced só nas quatro superfícies autorizadas, nunca durante Check ou sem UMP. */
object AdPolicy {
    fun shouldShowNative(context: AdContext): Boolean =
        context.enabled && context.placement != null && context.canRequestAds && !context.measuring
}
