package com.lagcheck.core.designsystem.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography

/**
 * Trilha Viva de Medição (MeasurementLiveTrail) com 3 nós e pacotes viajando na rota.
 * Paridade 1:1 estrita com MeasurementLiveTrail.swift do iOS.
 * Apresenta ciclo ida-e-volta (RTT), rastro cometa, iluminação reativa nos nós e barra de progresso em gradiente Roxo Gamer.
 */
@Composable
fun MeasurementLiveTrail(
    destinationName: String,
    currentRTT: Double?,
    progress: Float,
    isPhaseRest: Boolean,
    gameName: String,
    isWiFi: Boolean = true,
    connectionLabel: String = "Wi-Fi",
    modifier: Modifier = Modifier
) {
    // Duração do ciclo de ida e volta (RTT) em milissegundos
    val rtt = currentRTT ?: 35.0
    val cycleMillis = ((0.7 + (rtt.coerceIn(10.0, 250.0) - 10.0) / 240.0 * 1.3) * 1000).toInt()

    val infiniteTransition = rememberInfiniteTransition(label = "PingCycle")
    val cycleProgress by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = cycleMillis, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "CycleProgress"
    )

    val isOutbound = cycleProgress <= 0.5f
    val nodeFraction = if (isOutbound) cycleProgress * 2.0f else (1.0f - cycleProgress) * 2.0f

    // Deteção de passagem nos nós para iluminação sutil e reativa (glow)
    val isHitNode1 = cycleProgress < 0.08f || cycleProgress > 0.92f
    val isHitNode2 = (cycleProgress in 0.21f..0.29f) || (cycleProgress in 0.71f..0.79f)
    val isHitNode3 = cycleProgress in 0.46f..0.54f

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // 1. Rota com 3 Nós e Linha com Pacotes Animados
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxWidth()
                .height(115.dp)
        ) {
            val totalWidth = maxWidth

            // Linha horizontal que conecta os nós (top = 25.5dp)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 25.5.dp, start = totalWidth * (1f / 6f), end = totalWidth * (1f / 6f))
                    .height(1.5.dp)
                    .background(LagCheckColors.BorderStrong)
            )

            // Pingo com cometa viajando pela linha
            val startX = totalWidth * (1f / 6f)
            val endX = totalWidth * (5f / 6f)
            val currentX = startX + (endX - startX) * nodeFraction

            // Cometa / rastro dinâmico
            val cometLength = 36.dp
            val cometX = if (isOutbound) currentX - cometLength else currentX
            Box(
                modifier = Modifier
                    .offset(x = cometX, y = 24.dp)
                    .size(width = cometLength, height = 3.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(
                        Brush.horizontalGradient(
                            if (isOutbound) listOf(Color.Transparent, LagCheckColors.AccentPrimary.copy(alpha = 0.85f))
                            else listOf(LagCheckColors.AccentPrimary.copy(alpha = 0.85f), Color.Transparent)
                        )
                    )
            )

            // Pingo brilhante (Core + Halo)
            Box(
                modifier = Modifier
                    .offset(x = currentX - 6.dp, y = 19.5.dp)
                    .size(12.dp)
                    .clip(CircleShape)
                    .background(LagCheckColors.AccentPrimary.copy(alpha = 0.35f))
            )
            Box(
                modifier = Modifier
                    .offset(x = currentX - 3.5.dp, y = 22.dp)
                    .size(7.dp)
                    .clip(CircleShape)
                    .background(Color.White)
            )

            // 3 Nós: Seu Celular, Rede local, Região Gamer São Paulo
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Nó 1: Smartphone (Origem)
                RouteNode(
                    icon = { SmartphoneIcon(size = 22.dp, color = if (isHitNode1) LagCheckColors.AccentPrimary else LagCheckColors.TextPrimary) },
                    title = "Seu Celular",
                    subtitle = null,
                    isFinished = true,
                    isCurrent = false,
                    isHit = isHitNode1
                )

                // Nó 2: Rede local (Wi-Fi / 4G)
                RouteNode(
                    icon = { WifiIcon(size = 22.dp, color = if (isHitNode2) LagCheckColors.AccentPrimary else LagCheckColors.TextPrimary) },
                    title = connectionLabel,
                    subtitle = "Rede local",
                    isFinished = !isPhaseRest,
                    isCurrent = isPhaseRest,
                    isHit = isHitNode2
                )

                // Nó 3: Região Gamer (Destino)
                RouteNode(
                    icon = { ServerRackIcon(size = 22.dp, color = if (isHitNode3) LagCheckColors.AccentPrimary else LagCheckColors.TextPrimary) },
                    title = "Região Gamer",
                    subtitle = destinationName,
                    isFinished = false,
                    isCurrent = !isPhaseRest,
                    isHit = isHitNode3
                )
            }
        }

        Spacer(modifier = Modifier.height(44.dp))

        // 2. Status Copy ("Medindo rota em repouso…" / "Avaliando sob carga…")
        Text(
            text = if (isPhaseRest) "Medindo rota em repouso…" else "Avaliando sob carga…",
            style = LagCheckTypography.StatusCopy,
            color = LagCheckColors.TextPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(11.dp))

        // 3. Status Subtitle
        Text(
            text = if (isPhaseRest) "O check preserva uma leitura estável." else "Simulando tráfego simultâneo para detectar oscilações.",
            style = LagCheckTypography.Subtext,
            color = LagCheckColors.TextMuted,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(38.dp))

        // 4. Barra de Progresso Fina (4dp) em Gradiente Roxo Gamer
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(4.dp)
                .clip(RoundedCornerShape(999.dp))
                .background(LagCheckColors.Surface)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(fraction = progress.coerceIn(0.04f, 1f))
                    .height(4.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(
                        Brush.horizontalGradient(
                            listOf(
                                LagCheckColors.AccentPrimary,
                                LagCheckColors.AccentPrimary.copy(alpha = 0.85f)
                            )
                        )
                    )
            )
        }

        Spacer(modifier = Modifier.height(14.dp))

        // 5. Phase Kicker (11px mono)
        Text(
            text = if (isPhaseRest) "Fase 1 de 2 · Repouso" else "Fase 2 de 2 · Carga",
            style = LagCheckTypography.MonoData,
            color = LagCheckColors.TextMuted,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun RouteNode(
    icon: @Composable () -> Unit,
    title: String,
    subtitle: String?,
    isFinished: Boolean,
    isCurrent: Boolean,
    isHit: Boolean
) {
    val borderColor = when {
        isHit -> LagCheckColors.AccentPrimary
        isFinished || isCurrent -> LagCheckColors.AccentPrimary
        else -> LagCheckColors.BorderStrong
    }

    val glowAlpha = if (isHit) 0.25f else 0.0f

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.size(width = 95.dp, height = 110.dp)
    ) {
        Box(
            modifier = Modifier
                .size(51.dp)
                .clip(CircleShape)
                .background(LagCheckColors.Surface)
                .border(
                    width = if (isHit) 1.5.dp else 1.dp,
                    color = borderColor,
                    shape = CircleShape
                )
                .background(LagCheckColors.AccentPrimary.copy(alpha = glowAlpha), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            icon()
        }

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = title,
            style = LagCheckTypography.MonoSmall,
            color = LagCheckColors.TextPrimary,
            textAlign = TextAlign.Center,
            maxLines = 1
        )

        if (subtitle != null) {
            Text(
                text = subtitle,
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted,
                textAlign = TextAlign.Center,
                maxLines = 1
            )
        }
    }
}
