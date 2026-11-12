package com.lagcheck.desktop.ds

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.platform.Font
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.domain.model.GameReadinessVerdict

/** Tokens do LagCheck para Windows. Mesmos valores da Dark Competitive UI (Decisões 51 e 66); nada de cor solta. */
object LcColor {
    val Background = Color(0xFF0B0D10)
    val Surface = Color(0xFF15181E)
    val Panel = Color(0xFF1E232B)
    val BorderHairline = Color(0x14FFFFFF)
    val BorderSubtle = Color(0x1AFFFFFF) // rgba(255, 255, 255, 0.10)
    val BorderStrong = Color(0x29FFFFFF) // rgba(255, 255, 255, 0.16)
    val BorderHover = Color(0x737C3AED)  // rgba(124, 58, 237, 0.45)
    val Sky = Color(0xFF38BDF8)
    val Accent = Color(0xFF7C3AED)
    val AccentHover = Color(0xFF8B5CF6)
    val AccentPressed = Color(0xFF6D28D9)
    val AccentLight = Color(0xFFA78BFA)
    val AccentSubtle = Color(0x267C3AED)
    val Coral = Color(0xFFFF5A36)
    val Caution = Color(0xFFF59E0B)
    val Good = Color(0xFF22C55E)
    val Inconclusive = Color(0xFF8A93A0)
    val TextPrimary = Color(0xFFF4F5F7)
    val TextSecondary = Color(0xFF8A93A0)
    val TextTertiary = Color(0xFF606873)
    val HoverOverlay = Color(0x0FFFFFFF)
}

object LcSpace { val xs = 4.dp; val sm = 8.dp; val md = 12.dp; val lg = 16.dp; val xl = 24.dp; val xxl = 32.dp }
/** Raios do OpenDesign e design.md: r8 (mídia/métrica), r13 (controles/cards), r17 (CTAs), r26 (sheets), pill. */
object LcRadius {
    val control = 8.dp
    val panel = 13.dp
    val r8 = 8.dp
    val r13 = 13.dp
    val r17 = 17.dp
    val r26 = 26.dp
    val pill = 999.dp
}
object LcSize {
    val minTarget = 40.dp          // alvo mínimo com mouse; toque no Windows pede 44.dp (ver docs/09)
    val sidebar = 232.dp
    val contentMax = 920.dp
    val focusRing = 2.dp
}

/** Famílias oficiais do Windows, empacotadas para manter o desenho igual em qualquer instalação. */
object LcType {
    private val BodyFamily = FontFamily(
        Font(resource = "fonts/barlow_regular.ttf", weight = FontWeight.Normal),
        Font(resource = "fonts/barlow_medium.ttf", weight = FontWeight.Medium),
        Font(resource = "fonts/barlow_semibold.ttf", weight = FontWeight.SemiBold),
    )
    private val DisplayFamily = FontFamily(
        Font(resource = "fonts/barlow_semicondensed_bold.ttf", weight = FontWeight.Bold),
        Font(resource = "fonts/barlow_semicondensed_extrabold.ttf", weight = FontWeight.ExtraBold),
    )
    private val MetricFamily = FontFamily(
        Font(resource = "fonts/chakra_petch_semibold.ttf", weight = FontWeight.SemiBold),
    )
    private val TechnicalFamily = FontFamily.Monospace
    val VerdictHero = TextStyle(fontFamily = DisplayFamily, fontWeight = FontWeight.ExtraBold, fontSize = 40.sp, lineHeight = 44.sp, letterSpacing = (-1).sp)
    val PageTitle = TextStyle(fontFamily = DisplayFamily, fontWeight = FontWeight.Bold, fontSize = 28.sp, lineHeight = 34.sp, letterSpacing = (-0.6).sp)
    val Section = TextStyle(fontFamily = TechnicalFamily, fontWeight = FontWeight.SemiBold, fontSize = 11.sp, lineHeight = 14.sp, letterSpacing = 1.4.sp)
    val Body = TextStyle(fontFamily = BodyFamily, fontWeight = FontWeight.Normal, fontSize = 14.sp, lineHeight = 20.sp)
    val BodyStrong = TextStyle(fontFamily = BodyFamily, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, lineHeight = 20.sp)
    val Button = TextStyle(fontFamily = BodyFamily, fontWeight = FontWeight.SemiBold, fontSize = 13.sp, lineHeight = 16.sp, letterSpacing = 1.sp)
    val DataHero = TextStyle(fontFamily = MetricFamily, fontWeight = FontWeight.SemiBold, fontSize = 56.sp, lineHeight = 60.sp)
    val DataLarge = TextStyle(fontFamily = MetricFamily, fontWeight = FontWeight.SemiBold, fontSize = 24.sp, lineHeight = 28.sp)
    val DataSmall = TextStyle(fontFamily = MetricFamily, fontWeight = FontWeight.SemiBold, fontSize = 13.sp, lineHeight = 16.sp)
}

/** Veredito sempre com símbolo + texto + cor: cor sozinha nunca carrega o estado. */
data class VerdictStyle(val label: String, val color: Color, val phrase: String)

fun GameReadinessVerdict.style(): VerdictStyle = when (this) {
    GameReadinessVerdict.READY -> VerdictStyle("● PRONTO PARA RANKED", LcColor.Good, "Pode entrar na fila.")
    GameReadinessVerdict.CAUTION -> VerdictStyle("▲ CONDIÇÕES INSTÁVEIS", LcColor.Caution, "Dá pra jogar, mas pode oscilar.")
    GameReadinessVerdict.NOT_READY -> VerdictStyle("▲ EU EVITARIA RANKED AGORA", LcColor.Coral, "A rota não está segurando.")
    GameReadinessVerdict.INCONCLUSIVE -> VerdictStyle("— INCONCLUSIVO", LcColor.Inconclusive, "Faltou resposta para dar um veredito.")
}
