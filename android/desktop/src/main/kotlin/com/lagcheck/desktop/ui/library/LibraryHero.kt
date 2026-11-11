package com.lagcheck.desktop.ui.library

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.desktop.AppState
import com.lagcheck.desktop.ds.*
import com.lagcheck.desktop.library.artwork.ArtworkType
import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.PcGame

@Composable
fun LibraryHero(
    game: PcGame,
    state: AppState,
    modifier: Modifier = Modifier
) {
    val heroArt by rememberArtwork(game, ArtworkType.HERO, state.artwork, state.artworkGeneration)
    val coverArt by rememberArtwork(game, ArtworkType.COVER, state.artwork, state.artworkGeneration)
    val heroBitmap = (heroArt as? ArtworkState.Loaded)?.bitmap
    val coverBitmap = (coverArt as? ArtworkState.Loaded)?.bitmap

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
    ) {
        // Banner do jogo ao fundo, com degradê para o texto à esquerda continuar legível.
        if (heroBitmap != null) {
            Image(heroBitmap, null, Modifier.matchParentSize(), alignment = Alignment.CenterEnd, contentScale = ContentScale.Crop)
            Box(
                Modifier.matchParentSize().background(
                    Brush.horizontalGradient(
                        0f to Color(0xF20B0D10),
                        0.55f to Color(0xB30B0D10),
                        1f to Color(0x330B0D10)
                    )
                )
            )
        }
        Column(Modifier.fillMaxWidth().padding(28.dp)) {
            // Badges superiores
            Row(
                Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                PlatformBadge(game.platform)
                NetworkBadge(game.networkSupport)

                Spacer(Modifier.weight(1f))

                // Atualizar imagem do jogo: apaga a cópia guardada e busca de novo
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(LcRadius.r8))
                        .border(1.dp, LcColor.BorderHairline, RoundedCornerShape(LcRadius.r8))
                        .clickable { state.refreshArtwork(game) }
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Text("ATUALIZAR IMAGEM", style = LcType.Section.copy(fontSize = 11.sp), color = LcColor.TextSecondary)
                }

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
                        // Botão principal Jogar (Roxo Gamer, ação primária do design system)
                        LibraryButton(
                            text = "Jogar",
                            onClick = { state.library.launch(game) },
                            isPrimary = true,
                            enabled = game.isInstalled
                        )

                        // Botão secundário TESTAR CONEXÃO
                        when (val net = game.networkSupport) {
                            is GameNetworkSupport.LagcheckSupported -> {
                                LibraryButton(
                                    text = "Testar Conexão",
                                    onClick = { state.startForPcGame(game) },
                                    isPrimary = false
                                )
                            }
                            is GameNetworkSupport.GeneralConnectionOnly -> {
                                LibraryButton(
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

                // Sem banner, mas com capa: mostra a capa emoldurada à direita
                if (heroBitmap == null && coverBitmap != null) {
                    Spacer(Modifier.width(28.dp))
                    Box(
                        modifier = Modifier
                            .size(width = 170.dp, height = 230.dp)
                            .clip(RoundedCornerShape(LcRadius.r13))
                            .border(1.dp, LcColor.BorderStrong, RoundedCornerShape(LcRadius.r13))
                    ) {
                        Image(coverBitmap, game.title, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
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
