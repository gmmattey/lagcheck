package com.lagcheck.core.designsystem.theme

import androidx.compose.ui.unit.dp

/**
 * Tokens de espaçamento do LagCheck (design-system/tokens/spacing.json, Decisão 117).
 * Escala base de 4 dp igual ao iOS. Os meios passos (6, 10, 14, 18) e os degraus
 * 36 e 40 existem só no Android, porque as telas já os usavam.
 * Use estes valores em padding, spacedBy e Spacer em vez de números soltos.
 */
object LagCheckSpacing {
    val space1 = 4.dp
    /** Meio passo, só Android. */
    val space1_5 = 6.dp
    val space2 = 8.dp
    /** Meio passo, só Android. */
    val space2_5 = 10.dp
    val space3 = 12.dp
    /** Meio passo, só Android. */
    val space3_5 = 14.dp
    val space4 = 16.dp
    /** Meio passo, só Android. */
    val space4_5 = 18.dp
    val space5 = 20.dp
    val space6 = 24.dp
    val space7 = 28.dp
    val space8 = 32.dp
    /** Só Android. */
    val space9 = 36.dp
    /** Só Android. */
    val space10 = 40.dp

    // Semânticos (iguais ao iOS)
    val screenMarginHorizontal = 22.dp
    val cardPadding = 16.dp
    val stackGapTight = 4.dp
    val stackGapDefault = 8.dp
    val stackGapComfortable = 16.dp
}
