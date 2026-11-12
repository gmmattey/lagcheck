package com.lagcheck.desktop.ui.library

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
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
    val refreshInteraction = remember { MutableInteractionSource() }
    val refreshFocused by refreshInteraction.collectIsFocusedAsState()
    val favoriteInteraction = remember { MutableInteractionSource() }
    val favoriteFocused by favoriteInteraction.collectIsFocusedAsState()

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(LcRadius.r17))
            .background(
                LcColor.Surface
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
                        .background(LcColor.Background)
                        .border(if (refreshFocused) LcSize.focusRing else 1.dp, if (refreshFocused) LcColor.AccentLight else LcColor.BorderStrong, RoundedCornerShape(LcRadius.r8))
                        .semantics { contentDescription = "Atualizar imagem de ${game.title}" }
                        .clickable(interactionSource = refreshInteraction, indication = null, role = Role.Button) { state.refreshArtwork(game) }
                        .heightIn(min = 40.dp)
                        .padding(horizontal = 12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text("ATUALIZAR IMAGEM", style = LcType.Section.copy(fontSize = 11.sp), color = LcColor.TextSecondary)
                }

                // Botão de Favorito
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(LcRadius.r8))
                        .background(LcColor.Background)
                        .border(if (favoriteFocused) LcSize.focusRing else 1.dp, if (favoriteFocused) LcColor.AccentLight else if (game.isFavorite) LcColor.AccentLight else LcColor.BorderStrong, RoundedCornerShape(LcRadius.r8))
                        .semantics { contentDescription = if (game.isFavorite) "Remover ${game.title} dos favoritos" else "Adicionar ${game.title} aos favoritos" }
                        .clickable(interactionSource = favoriteInteraction, indication = null, role = Role.Button) { state.library.toggleFavorite(game) }
                        .heightIn(min = 40.dp)
                        .padding(horizontal = 12.dp),
                    contentAlignment = Alignment.Center
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

                // Sem banner: mantém uma coluna visual à direita com a capa ou fallback neutro.
                if (heroBitmap == null) {
                    Spacer(Modifier.width(28.dp))
                    Box(
                        modifier = Modifier
                            .size(width = 170.dp, height = 230.dp)
                            .clip(RoundedCornerShape(LcRadius.r13))
                            .border(1.dp, LcColor.BorderStrong, RoundedCornerShape(LcRadius.r13))
                    ) {
                        if (coverBitmap != null) {
                            Image(coverBitmap, game.title, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                        } else {
                            NeutralArtwork(game.title, ArtworkType.COVER, Modifier.fillMaxSize())
                        }
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
