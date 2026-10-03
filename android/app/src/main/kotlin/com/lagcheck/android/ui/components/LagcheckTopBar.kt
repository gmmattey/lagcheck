package com.lagcheck.android.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.R
import com.lagcheck.core.designsystem.components.ChevronLeftIcon
import com.lagcheck.core.designsystem.components.NetworkCockpitIcon
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography

/**
 * Top Bar Oficial da Home: Wordmark (esquerda) + Ícone de Rede / Cockpit + botão '…' (direita).
 * Paridade 1:1 com NolaggyAppHeader do iOS.
 */
@Composable
fun HomeTopBar(
    onOpenSettings: () -> Unit,
    onOpenNetworkCockpit: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Image(
            painter = painterResource(id = R.drawable.wordmark_primary),
            contentDescription = "lagcheck",
            modifier = Modifier
                .width(88.dp)
                .height(20.dp)
        )

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            if (onOpenNetworkCockpit != null) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .clickable { onOpenNetworkCockpit() },
                    contentAlignment = Alignment.Center
                ) {
                    NetworkCockpitIcon(
                        size = 19.dp,
                        color = LagCheckColors.TextSecondary
                    )
                }
            }

            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .clickable { onOpenSettings() },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "…",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = LagCheckColors.TextPrimary
                )
            }
        }
    }
}

/**
 * Barra Superior Canônica do Lagcheck para Telas Secundárias (Jogos, Detalhes, Histórico, Ajustes).
 * Regra inegociável do protótipo Open Design e Brand Spec:
 * O título NUNCA fica alinhado horizontalmente com o chevron de voltar.
 * Linha 1: Botão Voltar '‹' (44x44) à esquerda + Ação opcional à direita.
 * Linha 2: Título da tela (31sp display) abaixo, alinhado à esquerda.
 */
@Composable
fun SecondaryScreenHeader(
    title: String,
    subtitle: String? = null,
    onBack: () -> Unit,
    trailingAction: @Composable (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = 16.dp)
    ) {
        // Linha 1: Navegação (52dp)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .clickable { onBack() },
                contentAlignment = Alignment.CenterStart
            ) {
                ChevronLeftIcon(
                    size = 20.dp,
                    color = LagCheckColors.TextPrimary,
                    modifier = Modifier.padding(start = 4.dp)
                )
            }

            if (trailingAction != null) {
                trailingAction()
            } else {
                Spacer(modifier = Modifier.size(44.dp))
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // Linha 2: Título grande abaixo + subtítulo opcional
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = title,
                style = LagCheckTypography.PageTitle,
                color = LagCheckColors.TextPrimary
            )

            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = LagCheckTypography.MonoData,
                    color = LagCheckColors.TextMuted
                )
            }
        }
    }
}
