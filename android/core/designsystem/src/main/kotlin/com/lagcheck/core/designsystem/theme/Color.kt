package com.lagcheck.core.designsystem.theme

import androidx.compose.ui.graphics.Color

/**
 * Tokens Canônicos de Cor do Lagcheck (Open Design / Brand Spec / Decisões 51 e 66).
 * Fundo quase-preto (#0B0D10), Roxo Gamer (#7C3AED) para ação/foco,
 * Coral Solar (#FF5A36) para atenção e exclusão, Verde (#34D399) para veredito bom.
 */
object LagCheckColors {
    // Fundos e Superfícies
    val Background = Color(0xFF0B0D10)
    val Surface = Color(0xFF15181E)
    val Panel = Color(0xFF1E232B)
    val Border = Color(0xFF262D38)
    val BorderHairline = Color(0x14FFFFFF)
    val BorderStrong = Color(0x29FFFFFF)
    val BorderHover = Color(0xFF384352)

    // Acentos e Semântica
    val AccentPrimary = Color(0xFF7C3AED) // Roxo Gamer (#7C3AED - CTAs, foco, progresso)
    val AccentPrimarySubtle = Color(0x267C3AED)
    val CoralWarning = Color(0xFFFF5A36)  // Coral Solar (#FF5A36 - Alerta, veredito negativo, exclusão)
    val SemanticCaution = Color(0xFFF59E0B) // Âmbar (#F59E0B - Veredito CAUTION / Atenção)
    val Good = Color(0xFF22C55E)          // Verde (#22C55E - Veredito bom, pulso saudável)
    val Success = Good
    val Inconclusive = Color(0xFF8A93A0)  // Cinza neutro (#8A93A0 - Veredito INCONCLUSIVE)

    // Tipografia
    val TextPrimary = Color(0xFFF4F5F7)
    val TextSecondary = Color(0xFF8A93A0)
    val TextTertiary = Color(0xFF606873)
    val TextMuted = Color(0xFF8A93A0)

    // Overlay
    val Scrim = Color(0x7A000000)
}
