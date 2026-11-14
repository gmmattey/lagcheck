package com.lagcheck.core.designsystem.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.R

/**
 * Tipografia oficial do LagCheck Design System (Decisão 125 / DESIGN.md).
 * 3 famílias oficiais:
 * 1. Display (`BarlowSemiCondensed`): títulos, vereditos e nomes de destaque.
 * 2. Corpo (`Barlow`): leitura, navegação, rótulos de jogo e controles/CTAs.
 * 3. Telemetria (`ChakraPetch`): score, métricas, rotas e kickers técnicos com algarismos tabulares (`tnum`).
 */
object LagCheckTypography {
    val BarlowSemiCondensed = FontFamily(
        Font(R.font.barlow_semicondensed_bold, FontWeight.Bold),
        Font(R.font.barlow_semicondensed_extrabold, FontWeight.ExtraBold)
    )

    val Barlow = FontFamily(
        Font(R.font.barlow_regular, FontWeight.Normal),
        Font(R.font.barlow_medium, FontWeight.Medium),
        Font(R.font.barlow_semibold, FontWeight.SemiBold)
    )

    val ChakraPetch = FontFamily(
        Font(R.font.chakra_petch_semibold, FontWeight.SemiBold)
    )

    private const val TABULAR = "tnum"

    // 04 · Veredito Hero
    val VerdictHero = TextStyle(
        fontFamily = BarlowSemiCondensed,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 42.sp,
        lineHeight = 40.sp,
        letterSpacing = (-1.2).sp
    )

    // 01 · Home Game Title
    val HomeGameTitle = TextStyle(
        fontFamily = BarlowSemiCondensed,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 38.sp,
        lineHeight = 38.sp,
        letterSpacing = (-1.0).sp
    )

    // Page Titles (Jogos, Detalhes, Histórico, Ajustes)
    val PageTitle = TextStyle(
        fontFamily = BarlowSemiCondensed,
        fontWeight = FontWeight.Bold,
        fontSize = 31.sp,
        lineHeight = 36.sp,
        letterSpacing = (-0.8).sp
    )

    // Detalhes Score (Lagcheck Score 86)
    val ScoreNumber = TextStyle(
        fontFamily = ChakraPetch,
        fontFeatureSettings = TABULAR,
        fontWeight = FontWeight.SemiBold,
        fontSize = 45.sp,
        lineHeight = 45.sp,
        letterSpacing = (-1.5).sp
    )

    // Status Copy durante medição ("Medindo rota em repouso…")
    val StatusCopy = TextStyle(
        fontFamily = BarlowSemiCondensed,
        fontWeight = FontWeight.Bold,
        fontSize = 25.sp,
        lineHeight = 30.sp,
        letterSpacing = (-0.6).sp
    )

    // Modal / Alert Title ("A conexão mudou.", "Não encontrou o jogo?")
    val SectionHeader = TextStyle(
        fontFamily = BarlowSemiCondensed,
        fontWeight = FontWeight.Bold,
        fontSize = 22.sp,
        lineHeight = 26.sp,
        letterSpacing = (-0.4).sp
    )

    // Primary CTA Button ("Checar agora", "Testar novamente")
    val CtaPrimary = TextStyle(
        fontFamily = Barlow,
        fontWeight = FontWeight.SemiBold,
        fontSize = 17.sp,
        lineHeight = 22.sp,
        letterSpacing = (-0.2).sp
    )

    // Secondary Button / Text
    val BodyMedium = TextStyle(
        fontFamily = Barlow,
        fontWeight = FontWeight.Normal,
        fontSize = 15.sp,
        lineHeight = 20.sp
    )

    val BodySemibold = TextStyle(
        fontFamily = Barlow,
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        lineHeight = 22.sp,
        letterSpacing = (-0.1).sp
    )

    val Subtext = TextStyle(
        fontFamily = Barlow,
        fontWeight = FontWeight.Normal,
        fontSize = 13.sp,
        lineHeight = 18.sp
    )

    // Kickers e Indicadores técnicos ("RESULTADO DO CHECK", "FAVORITOS")
    val MonoKicker = TextStyle(
        fontFamily = ChakraPetch,
        fontFeatureSettings = TABULAR,
        fontWeight = FontWeight.SemiBold,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.8.sp
    )

    // Dados numéricos e telemetria ("31 ms · 3 ms jitter · 0,4% perda", "Fase 1 de 2 · Repouso")
    val MonoData = TextStyle(
        fontFamily = ChakraPetch,
        fontFeatureSettings = TABULAR,
        fontWeight = FontWeight.SemiBold,
        fontSize = 12.sp,
        lineHeight = 16.sp
    )

    val MonoSmall = TextStyle(
        fontFamily = ChakraPetch,
        fontFeatureSettings = TABULAR,
        fontWeight = FontWeight.SemiBold,
        fontSize = 12.sp,
        lineHeight = 16.sp
    )

    val MaterialTypography = Typography(
        displayLarge = VerdictHero,
        displayMedium = HomeGameTitle,
        displaySmall = PageTitle,
        headlineLarge = PageTitle,
        headlineMedium = StatusCopy,
        headlineSmall = SectionHeader,
        titleLarge = SectionHeader,
        titleMedium = BodySemibold,
        titleSmall = TextStyle(fontFamily = Barlow, fontWeight = FontWeight.Medium, fontSize = 14.sp, lineHeight = 20.sp),
        bodyLarge = TextStyle(fontFamily = Barlow, fontWeight = FontWeight.Normal, fontSize = 16.sp, lineHeight = 24.sp),
        bodyMedium = BodyMedium,
        bodySmall = Subtext,
        labelLarge = CtaPrimary,
        labelMedium = TextStyle(fontFamily = Barlow, fontWeight = FontWeight.Medium, fontSize = 12.sp, lineHeight = 16.sp),
        labelSmall = MonoSmall
    )

    // Compatibilidade reversa com componentes existentes
    val VerdictHeadline = PageTitle
    val CockpitNumber = ScoreNumber
    val CockpitNumberSmall = MonoData
    val CtaButton = CtaPrimary
    val CaptionMono = MonoData
}
