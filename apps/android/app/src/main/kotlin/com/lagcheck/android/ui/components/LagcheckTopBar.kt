package com.lagcheck.android.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
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
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.R
import com.lagcheck.core.designsystem.components.ChevronLeftIcon
import com.lagcheck.core.designsystem.components.NetworkCockpitIcon
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckSpacing

/**
 * Top Bar Oficial da Home: Wordmark (esquerda) + Ícone de Rede / Cockpit + botão '…' (direita).
 * Paridade 1:1 com NolaggyAppHeader do iOS.
 */
@Composable
fun HomeTopBar(
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp),
        horizontalArrangement = Arrangement.Start,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Image(
            painter = painterResource(id = R.drawable.wordmark_primary),
            contentDescription = "lagcheck",
            modifier = Modifier
                .width(110.dp)
                .height(30.dp)
        )
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
    onBack: (() -> Unit)?,
    trailingAction: @Composable (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = LagCheckSpacing.space4)
    ) {
        if (onBack != null || trailingAction != null) {
            // Linha 1: Navegação (52dp) apenas quando houver controle de volta ou ação à direita.
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (onBack != null) {
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape)
                            .clickable { onBack() },
                        contentAlignment = Alignment.CenterStart
                    ) {
                        ChevronLeftIcon(
                            size = 20.dp,
                            color = LagCheckColors.TextPrimary,
                            modifier = Modifier.padding(start = LagCheckSpacing.space1)
                        )
                    }
                } else {
                    Spacer(modifier = Modifier.size(48.dp))
                }

                if (trailingAction != null) {
                    trailingAction()
                } else {
                    Spacer(modifier = Modifier.size(48.dp))
                }
            }
            Spacer(modifier = Modifier.height(LagCheckSpacing.space1_5))
        } else {
            Spacer(modifier = Modifier.height(LagCheckSpacing.space3))
        }

        // Linha 2: Título grande abaixo + subtítulo opcional
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
        ) {
            Text(
                text = title.uppercase(),
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

/**
 * Cabeçalho colapsável Material 3 (Android): título grande em CAIXA ALTA à esquerda em repouso
 * (sem faixa vazia de 52 dp quando não há botões) que recolhe suavemente ao rolar para uma
 * barra fixa compacta (56 dp) com título alinhado à esquerda e separação tonal.
 */
@Composable
fun CollapsibleScreenTopBar(
    title: String,
    isCollapsed: Boolean,
    onBack: (() -> Unit)? = null,
    trailingAction: @Composable (() -> Unit)? = null,
    subtitle: String? = null,
    horizontalPadding: Dp = LagCheckSpacing.space6,
    modifier: Modifier = Modifier
) {
    val containerColor by animateColorAsState(
        targetValue = if (isCollapsed) LagCheckColors.Surface else LagCheckColors.Background
    )
    val elevation by animateDpAsState(
        targetValue = if (isCollapsed) 4.dp else 0.dp
    )
    val dividerAlpha by animateFloatAsState(
        targetValue = if (isCollapsed) 1f else 0f
    )
    val hasActionRow = onBack != null || trailingAction != null

    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(elevation = elevation)
            .background(containerColor)
            .animateContentSize()
    ) {
        if (isCollapsed) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .padding(horizontal = horizontalPadding),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (onBack != null) {
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape)
                            .clickable { onBack() },
                        contentAlignment = Alignment.CenterStart
                    ) {
                        ChevronLeftIcon(
                            size = 20.dp,
                            color = LagCheckColors.TextPrimary,
                            modifier = Modifier.padding(start = LagCheckSpacing.space1)
                        )
                    }
                    Spacer(modifier = Modifier.width(LagCheckSpacing.space1))
                }

                Text(
                    text = title.uppercase(),
                    style = LagCheckTypography.PageTitle.copy(
                        fontSize = 20.sp,
                        lineHeight = 24.sp,
                        letterSpacing = (-0.4).sp
                    ),
                    color = LagCheckColors.TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )

                if (trailingAction != null) {
                    Spacer(modifier = Modifier.width(LagCheckSpacing.space2))
                    trailingAction()
                }
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = horizontalPadding)
                    .padding(bottom = LagCheckSpacing.space3)
            ) {
                if (hasActionRow) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (onBack != null) {
                            Box(
                                modifier = Modifier
                                    .size(48.dp)
                                    .clip(CircleShape)
                                    .clickable { onBack() },
                                contentAlignment = Alignment.CenterStart
                            ) {
                                ChevronLeftIcon(
                                    size = 20.dp,
                                    color = LagCheckColors.TextPrimary,
                                    modifier = Modifier.padding(start = LagCheckSpacing.space1)
                                )
                            }
                        } else {
                            Spacer(modifier = Modifier.size(48.dp))
                        }

                        if (trailingAction != null) {
                            trailingAction()
                        } else {
                            Spacer(modifier = Modifier.size(48.dp))
                        }
                    }
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space1_5))
                } else {
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space3_5))
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
                ) {
                    Text(
                        text = title.uppercase(),
                        style = LagCheckTypography.PageTitle,
                        color = LagCheckColors.TextPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
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

        if (dividerAlpha > 0.01f) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(LagCheckColors.BorderHairline.copy(alpha = dividerAlpha))
            )
        }
    }
}
