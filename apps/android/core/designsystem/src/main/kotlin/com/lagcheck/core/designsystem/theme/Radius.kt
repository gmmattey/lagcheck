package com.lagcheck.core.designsystem.theme

import androidx.compose.ui.unit.dp

/**
 * Tokens de raio do LagCheck (design-system/tokens/radius.json, Decisão 117).
 * Use estes valores em vez de números soltos em RoundedCornerShape.
 */
object LagCheckRadius {
    /** Alças de sheet e selos pequenos do veredito. Específico do Android. */
    val xs = 4.dp
    /** Mídia, capas de jogos e métricas. */
    val sm = 8.dp
    /** Campos, cartões compactos e containers de evidência. */
    val md = 13.dp
    /** Botões de ação primária. */
    val lg = 17.dp
    /** Bottom sheet modal e hero cards. */
    val xl = 26.dp
    /** Chips de telemetria ao vivo e pílulas de status. */
    val pill = 999.dp
}
