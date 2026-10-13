package com.lagcheck.core.designsystem.theme

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.R

/**
 * 3 Pilhas Tipográficas Canônicas do Lagcheck (Open Design / Brand Spec / Decisões 53 e 66).
 * 1. Display: Manchete de veredito, títulos de tela (Google Sans Flex bold).
 * 2. Corpo: contexto, listas e ações.
 * 3. Dados: cockpit de telemetria, kickers, pings, jitter e fases, em algarismos tabulares.
 * Tudo em Google Sans Flex (Decisão 80).
 */
@OptIn(ExperimentalTextApi::class)
object LagCheckTypography {
    /** Google Sans Flex (OFL, a mesma do SignallQ) é a única família do app: títulos, corpo e números (algarismos tabulares via `tnum`). */
    val GoogleSans = FontFamily(
        listOf(
            FontWeight.Normal, FontWeight.Medium, FontWeight.SemiBold,
            FontWeight.Bold, FontWeight.ExtraBold, FontWeight.Black
        ).map { w ->
            Font(R.font.google_sans_flex_variable, w, variationSettings = FontVariation.Settings(FontVariation.weight(w.weight)))
        }
    )
    private val RoundedDisplay = GoogleSans
    private const val TABULAR = "tnum"

    // 04 · Veredito Hero
    val VerdictHero = TextStyle(
        fontFamily = RoundedDisplay,
        fontWeight = FontWeight.Black,
        fontSize = 42.sp,
        lineHeight = 40.sp,
        letterSpacing = (-1.5).sp
    )

    // 01 · Home Game Title
    val HomeGameTitle = TextStyle(
        fontFamily = RoundedDisplay,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 38.sp,
        lineHeight = 38.sp,
        letterSpacing = (-1.2).sp
    )

    // Page Titles (Jogos, Detalhes, Histórico, Ajustes)
    val PageTitle = TextStyle(
        fontFamily = RoundedDisplay,
        fontWeight = FontWeight.Bold,
        fontSize = 31.sp,
        lineHeight = 36.sp,
        letterSpacing = (-1.0).sp
    )

    // Detalhes Score (Lagcheck Score 86)
    val ScoreNumber = TextStyle(
        fontFamily = GoogleSans,
        fontFeatureSettings = TABULAR,
        fontWeight = FontWeight.Bold,
        fontSize = 45.sp,
        lineHeight = 45.sp,
        letterSpacing = (-2.0).sp
    )

    // Status Copy durante medição ("Medindo rota em repouso…")
    val StatusCopy = TextStyle(
        fontFamily = RoundedDisplay,
        fontWeight = FontWeight.Bold,
        fontSize = 25.sp,
        lineHeight = 30.sp,
        letterSpacing = (-0.8).sp
    )

    // Modal / Alert Title ("A conexão mudou.", "Não encontrou o jogo?")
    val SectionHeader = TextStyle(
        fontFamily = RoundedDisplay,
        fontWeight = FontWeight.Bold,
        fontSize = 22.sp,
        lineHeight = 26.sp,
        letterSpacing = (-0.5).sp
    )

    // Primary CTA Button ("Checar agora", "Testar novamente")
    val CtaPrimary = TextStyle(
        fontFamily = GoogleSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 17.sp,
        lineHeight = 22.sp,
        letterSpacing = (-0.3).sp
    )

    // Secondary Button / Text
    val BodyMedium = TextStyle(
        fontFamily = GoogleSans,
        fontWeight = FontWeight.Normal,
        fontSize = 15.sp,
        lineHeight = 20.sp
    )

    val BodySemibold = TextStyle(
        fontFamily = GoogleSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        lineHeight = 22.sp,
        letterSpacing = (-0.2).sp
    )

    val Subtext = TextStyle(
        fontFamily = GoogleSans,
        fontWeight = FontWeight.Normal,
        fontSize = 13.sp,
        lineHeight = 18.sp
    )

    // Monospace Kickers e Indicadores ("RESULTADO DO CHECK", "FAVORITOS")
    val MonoKicker = TextStyle(
        fontFamily = GoogleSans,
        fontFeatureSettings = TABULAR,
        fontWeight = FontWeight.SemiBold,
        fontSize = 11.sp,
        lineHeight = 14.sp,
        letterSpacing = 0.8.sp
    )

    // Monospace Data (Métricas: "31 ms · 3 ms jitter · 0,4% perda", "Fase 1 de 2 · Repouso")
    val MonoData = TextStyle(
        fontFamily = GoogleSans,
        fontFeatureSettings = TABULAR,
        fontWeight = FontWeight.Medium,
        fontSize = 11.sp,
        lineHeight = 16.sp
    )

    val MonoSmall = TextStyle(
        fontFamily = GoogleSans,
        fontFeatureSettings = TABULAR,
        fontWeight = FontWeight.Normal,
        fontSize = 10.sp,
        lineHeight = 14.sp
    )

    // Compatibilidade reversa com componentes existentes
    val VerdictHeadline = PageTitle
    val CockpitNumber = ScoreNumber
    val CockpitNumberSmall = MonoData
    val CtaButton = CtaPrimary
    val CaptionMono = MonoData
}
