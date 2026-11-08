package com.lagcheck.android.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import com.lagcheck.network.health.PlatformHealth

/**
 * Aviso de que a rede do console está com problema, vindo do status público da fabricante (Decisão 30).
 * Só aparece com problema reportado; falha de leitura não mostra nada. O símbolo (▲/✕) e o selo garantem que o estado
 * não dependa só de cor. Texto vem da fabricante quando existe; senão, uma frase curta padrão.
 */
@Composable
fun PlatformHealthBanner(health: PlatformHealth, modifier: Modifier = Modifier) {
    if (!health.isIssueReported) return
    val major = health.isMajorOutage
    val accent = if (major) LagCheckColors.CoralWarning else LagCheckColors.SemanticCaution
    val title = if (major) trf("%s fora do ar", health.serviceName) else trf("%s com instabilidade", health.serviceName)
    val message = health.details?.takeIf { it.isNotBlank() }
        ?: if (major) tr("Os servidores de login e multiplayer estão passando por interrupções no momento.")
        else tr("Pode haver lentidão ou dificuldade temporária para entrar em partidas online.")
    val badge = if (major) tr("Fora do ar") else tr("Instável")

    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(LagCheckRadius.md))
            .background(LagCheckColors.Surface)
            .border(1.dp, accent.copy(alpha = 0.35f), RoundedCornerShape(LagCheckRadius.md))
            .padding(LagCheckSpacing.space3_5)
            .semantics(mergeDescendants = true) { contentDescription = "$title. $message" },
        verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space1_5)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
            Text(
                text = (if (major) "✕ " else "▲ ") + title,
                fontSize = 14.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary,
                modifier = Modifier.weight(1f)
            )
            Text(
                text = badge,
                style = LagCheckTypography.MonoSmall,
                color = accent,
                modifier = Modifier
                    .padding(start = LagCheckSpacing.space2)
                    .clip(RoundedCornerShape(LagCheckRadius.pill))
                    .background(accent.copy(alpha = 0.16f))
                    .padding(horizontal = LagCheckSpacing.space2, vertical = LagCheckSpacing.space1)
            )
        }
        Text(text = message, style = LagCheckTypography.Subtext, color = LagCheckColors.TextMuted)
        if (health.affectedServices.isNotEmpty()) {
            Text(
                text = trf("Afeta: %s", health.affectedServices.joinToString(", ")),
                style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted
            )
        }
    }
}
