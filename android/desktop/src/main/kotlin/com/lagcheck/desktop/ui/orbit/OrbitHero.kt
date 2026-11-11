package com.lagcheck.desktop.ui.orbit

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.desktop.AppState
import com.lagcheck.desktop.ds.*
import com.lagcheck.desktop.library.launcher.GameLaunchResult
import com.lagcheck.desktop.library.launcher.GameRunner
import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.PcGame

@Composable
fun OrbitHero(
    game: PcGame,
    state: AppState,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(LcRadius.r17))
            .background(
                Brush.radialGradient(
                    colors = listOf(
                        LcColor.Panel.copy(alpha = 0.9f),
                        LcColor.Surface,
                        LcColor.Background
                    ),
                    radius = 1200f
                )
            )
            .border(1.dp, LcColor.BorderHairline, RoundedCornerShape(LcRadius.r17))
            .padding(28.dp)
    ) {
        Column(Modifier.fillMaxWidth()) {
            // Badges superiores
            Row(
                Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OrbitPlatformBadge(game.platform)
                OrbitNetworkBadge(game.networkSupport)

                Spacer(Modifier.weight(1f))

                // Botão de Favorito
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(LcRadius.r8))
                        .background(if (game.isFavorite) LcColor.AccentSubtle else Color.Transparent)
                        .border(1.dp, if (game.isFavorite) LcColor.AccentLight else LcColor.BorderHairline, RoundedCornerShape(LcRadius.r8))
                        .clickable { state.library.toggleFavorite(game) }
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = if (game.isFavorite) "★ FAVORITO" else "☆ FAVORITAR",
                        style = LcType.Section.copy(fontSize = 11.sp),
                        color = if (game.isFavorite) LcColor.AccentLight else LcColor.TextSecondary
                    )
                }
            }

            Spacer(Modifier.height(18.dp))

            // Conteúdo principal: Título, Descrição e Ações
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(
                        text = game.title,
                        style = LcType.VerdictHero.copy(fontSize = 36.sp, lineHeight = 40.sp),
                        color = LcColor.TextPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    Spacer(Modifier.height(8.dp))

                    if (!game.description.isNullOrBlank()) {
                        Text(
                            text = game.description,
                            style = LcType.Body,
                            color = LcColor.TextSecondary,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.widthIn(max = 680.dp)
                        )
                        Spacer(Modifier.height(12.dp))
                    }

                    // Metadados do jogo
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (game.playTimeMinutes > 0) {
                            Text(
                                text = "TEMPO DE JOGO: ${game.playTimeMinutes / 60}H ${game.playTimeMinutes % 60}M",
                                style = LcType.Section,
                                color = LcColor.TextTertiary
                            )
                        }
                        if (game.tags.isNotEmpty()) {
                            Text(
                                text = "•  ${game.tags.joinToString(" / ")}",
                                style = LcType.Section,
                                color = LcColor.TextTertiary
                            )
                        }
                    }

                    Spacer(Modifier.height(24.dp))

                    // Linha de Ações Principais
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Botão principal JOGAR (destaque esportivo verde-lima da interface ORBIT)
                        OrbitButton(
                            text = "Jogar",
                            onClick = {
                                val res = GameRunner.launch(game)
                                state.library.launchMessage = when (res) {
                                    is GameLaunchResult.Success -> res.message
                                    is GameLaunchResult.Failure -> res.reason
                                }
                            },
                            isPrimary = true,
                            isLime = true
                        )

                        // Botão secundário TESTAR CONEXÃO
                        when (val net = game.networkSupport) {
                            is GameNetworkSupport.LagcheckSupported -> {
                                OrbitButton(
                                    text = "Testar Conexão",
                                    onClick = { state.startForPcGame(game) },
                                    isPrimary = false
                                )
                            }
                            is GameNetworkSupport.GeneralConnectionOnly -> {
                                OrbitButton(
                                    text = "Testar Rota Geral",
                                    onClick = { state.startForPcGame(game) },
                                    isPrimary = false
                                )
                            }
                            is GameNetworkSupport.OfflineSingleplayer -> {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(LcRadius.r13))
                                        .background(LcColor.Surface)
                                        .border(1.dp, LcColor.BorderHairline, RoundedCornerShape(LcRadius.r13))
                                        .padding(horizontal = 16.dp, vertical = 12.dp)
                                ) {
                                    Text(
                                        text = "MODO OFFLINE · SEM TESTE DE SERVIDOR",
                                        style = LcType.Section,
                                        color = LcColor.TextTertiary
                                    )
                                }
                            }
                        }
                    }
                }

                // Miniatura / Arte Editorial do jogo
                if (!game.localArtworkRes.isNullOrBlank()) {
                    Spacer(Modifier.width(28.dp))
                    Box(
                        modifier = Modifier
                            .size(width = 170.dp, height = 230.dp)
                            .clip(RoundedCornerShape(LcRadius.r13))
                            .border(1.dp, LcColor.BorderStrong, RoundedCornerShape(LcRadius.r13))
                    ) {
                        ApprovedArtwork(game.localArtworkRes, game.title, Modifier.fillMaxSize())
                    }
                }
            }

            // Mensagem de feedback de lançamento
            state.library.launchMessage?.let { msg ->
                Spacer(Modifier.height(14.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(LcRadius.r8))
                        .background(LcColor.Surface)
                        .border(1.dp, LcColor.BorderHairline, RoundedCornerShape(LcRadius.r8))
                        .padding(horizontal = 14.dp, vertical = 8.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("INFO:", style = LcType.Section, color = LcColor.AccentLight)
                        Spacer(Modifier.width(8.dp))
                        Text(msg, style = LcType.Body, color = LcColor.TextSecondary)
                    }
                }
            }
        }
    }
}
