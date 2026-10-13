package com.lagcheck.android.ui.games

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.R
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.FavoriteGames
import com.lagcheck.domain.model.OfficialGameCatalog
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.catalog.Platform
import com.lagcheck.session.PlatformLabels

/**
 * 02 · Trocar Jogo (Seleção de Jogos e Plataforma).
 * Paridade 1:1 com o protótipo de alta fidelidade Open Design (Screen 02 · Trocar jogo).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GameSelectionScreen(
    allGames: List<CatalogGame>,
    showBackButton: Boolean = false,
    onBack: () -> Unit,
    onGameSelected: (game: CatalogGame) -> Unit,
    onStartGeneralCheck: () -> Unit,
    /** Últimos checks reais do histórico. Sem histórico, a seção de recentes não aparece. */
    recentChecks: List<CheckHistoryItem> = emptyList(),
    favorites: FavoriteGames = FavoriteGames.EMPTY,
    onToggleFavorite: (CatalogGame) -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var searchQuery by remember { mutableStateOf("") }


    val filteredGames = remember(searchQuery, allGames) {
        if (searchQuery.isBlank()) allGames
        else allGames.filter { it.name.contains(searchQuery, ignoreCase = true) || it.category.contains(searchQuery, ignoreCase = true) }
    }

    // Recentes saem do histórico real; favoritos, da escolha da pessoa (salva no aparelho).
    val favoriteGames = remember(favorites, allGames) { favorites.resolve(allGames) }
    val recentGames = remember(recentChecks, allGames) {
        recentChecks.distinctBy { it.gameId }.mapNotNull { check -> allGames.firstOrNull { it.id == check.gameId }?.let { check to it } }.take(3)
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 22.dp)
        ) {
            // 1. Barra de Topo: Voltar + Wordmark
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                        .padding(top = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (showBackButton) {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(CircleShape)
                                .clickable { onBack() },
                            contentAlignment = Alignment.CenterStart
                        ) {
                            com.lagcheck.core.designsystem.components.ChevronLeftIcon(
                                size = 20.dp,
                                color = LagCheckColors.TextPrimary,
                                modifier = Modifier.padding(start = 4.dp)
                            )
                        }
                    } else {
                        Spacer(modifier = Modifier.size(44.dp))
                    }

                    Image(
                        painter = painterResource(id = R.drawable.wordmark_primary),
                        contentDescription = "lagcheck",
                        modifier = Modifier
                            .width(88.dp)
                            .height(20.dp)
                    )

                    Spacer(modifier = Modifier.size(44.dp))
                }
            }

            // 2. Título de Seção: "Jogos"
            item {
                Spacer(modifier = Modifier.height(14.dp))
                Text(
                    text = tr("Jogos"),
                    style = LagCheckTypography.PageTitle,
                    color = LagCheckColors.TextPrimary
                )
                Spacer(modifier = Modifier.height(20.dp))
            }

            // 2.5 Seção FAVORITOS
            if (searchQuery.isBlank()) {
                val favs = if (favoriteGames.isEmpty()) allGames.take(3) else favoriteGames
                item {
                    Text(
                        text = tr("FAVORITOS"),
                        style = LagCheckTypography.MonoKicker,
                        color = LagCheckColors.TextMuted
                    )
                    Spacer(modifier = Modifier.height(11.dp))

                    androidx.compose.foundation.lazy.LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        items(favs, key = { "favcard-${it.id}" }) { game ->
                            FavoriteCard(
                                game = game,
                                onClick = { onGameSelected(game) }
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                }
            }

            // 3. Seção USADOS RECENTEMENTE (só quando há histórico real)
            if (searchQuery.isBlank() && recentGames.isNotEmpty()) {
                val (check, recentGame) = recentGames.first()
                item {
                    Text(
                        text = tr("USADOS RECENTEMENTE"),
                        style = LagCheckTypography.MonoKicker,
                        color = LagCheckColors.TextMuted
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(20.dp))
                            .background(LagCheckColors.Surface)
                            .clickable { onGameSelected(recentGame) }
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = recentGame.name,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = LagCheckColors.TextPrimary,
                                maxLines = 1
                            )
                            Spacer(modifier = Modifier.height(5.dp))
                            com.lagcheck.core.designsystem.components.PlatformGlyph(platform = check.platform)
                        }

                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                text = check.formattedDate,
                                style = LagCheckTypography.MonoSmall,
                                color = LagCheckColors.TextMuted
                            )
                            Text(
                                text = "›",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = LagCheckColors.TextMuted
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                }
            }

            // 5. Seção MAIS JOGADOS NO BRASIL (Catálogo Completo)
            item {
                Text(
                    text = if (searchQuery.isBlank()) tr("JOGOS") else trf("RESULTADOS (%d)", filteredGames.size),
                    style = LagCheckTypography.MonoKicker,
                    color = LagCheckColors.TextMuted
                )
                Spacer(modifier = Modifier.height(11.dp))
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text(tr("Buscar jogo"), color = LagCheckColors.TextMuted, fontSize = 14.sp) },
                    leadingIcon = {
                        com.lagcheck.core.designsystem.components.SearchIcon(size = 18.dp, color = LagCheckColors.TextMuted)
                    },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            Box(
                                modifier = Modifier
                                    .size(44.dp)
                                    .clip(CircleShape)
                                    .clickable { searchQuery = "" },
                                contentAlignment = Alignment.Center
                            ) {
                                com.lagcheck.core.designsystem.components.CloseIcon(size = 16.dp, color = LagCheckColors.TextMuted)
                            }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .defaultMinSize(minHeight = 52.dp),
                    singleLine = true,
                    shape = RoundedCornerShape(percent = 50),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedContainerColor = LagCheckColors.Surface,
                        unfocusedContainerColor = LagCheckColors.Surface,
                        focusedBorderColor = LagCheckColors.AccentPrimary,
                        unfocusedBorderColor = Color.Transparent,
                        focusedTextColor = LagCheckColors.TextPrimary,
                        unfocusedTextColor = LagCheckColors.TextPrimary,
                        cursorColor = LagCheckColors.AccentPrimary
                    )
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

            items(filteredGames) { game ->
                CatalogRowItem(
                    game = game,
                    isFavorite = game.id in favorites,
                    onToggleFavorite = { onToggleFavorite(game) },
                    onClick = { onGameSelected(game) }
                )
            }

            // Jogo fora da lista: Check Geral com a rota regional de referência
            item {
                Spacer(modifier = Modifier.height(32.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(24.dp))
                        .background(LagCheckColors.Surface)
                        .padding(22.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = tr("Não encontrou o jogo?"),
                        style = LagCheckTypography.SectionHeader,
                        color = LagCheckColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = tr("Faça um Check Geral com rota regional de referência"),
                        style = LagCheckTypography.Subtext,
                        color = LagCheckColors.TextMuted
                    )
                    Spacer(modifier = Modifier.height(18.dp))
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(percent = 50))
                            .border(1.dp, LagCheckColors.BorderStrong, RoundedCornerShape(percent = 50))
                            .clickable { onStartGeneralCheck() }
                            .defaultMinSize(minHeight = 44.dp)
                            .padding(horizontal = 18.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = tr("Fazer Check Geral"),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                            color = LagCheckColors.TextPrimary
                        )
                    }
                }
                Spacer(modifier = Modifier.height(48.dp))
            }
        }
    }
}

@Composable
private fun FavoriteCard(
    game: CatalogGame,
    onClick: () -> Unit
) {

    Column(
        modifier = Modifier
            .size(width = 93.dp, height = 110.dp)
            .clip(RoundedCornerShape(22.dp))
            .background(LagCheckColors.Surface)
            .clickable { onClick() }
            .padding(6.dp)
    ) {
        Box(
            modifier = Modifier
                .size(width = 79.dp, height = 67.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(LagCheckColors.Panel)
        ) {
            com.lagcheck.android.ui.components.RemoteGameArtwork(game, Modifier.fillMaxSize())
        }

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = game.name,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            color = LagCheckColors.TextPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun CatalogRowItem(
    game: CatalogGame,
    isFavorite: Boolean,
    onToggleFavorite: () -> Unit,
    onClick: () -> Unit
) {

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(78.dp)
            .clickable { onClick() }
            .drawBehind {
                val y = size.height - 0.25.dp.toPx()
                drawLine(Color.White.copy(alpha = 0.08f), androidx.compose.ui.geometry.Offset(0f, y), androidx.compose.ui.geometry.Offset(size.width, y), 0.5.dp.toPx())
            }
            .padding(vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Capa 46x56
        Box(
            modifier = Modifier
                .size(width = 46.dp, height = 56.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(LagCheckColors.Surface)
                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(8.dp))
        ) {
            com.lagcheck.android.ui.components.RemoteGameArtwork(game, Modifier.fillMaxSize())
        }

        Spacer(modifier = Modifier.width(12.dp))

        // Nome e Plataformas
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = game.name,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = LagCheckColors.TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(7.dp))
            com.lagcheck.core.designsystem.components.PlatformGlyphRow(platforms = game.platforms)
        }

        // Estrela (alvo de 44 dp): o estado vai em texto, não só em cor.
        val favLabel = if (isFavorite) tr("Remover dos favoritos") else tr("Favoritar")
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .clickable { onToggleFavorite() }
                .semantics { contentDescription = favLabel },
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = if (isFavorite) "★" else "☆",
                fontSize = 20.sp,
                color = if (isFavorite) LagCheckColors.SemanticCaution else LagCheckColors.TextMuted
            )
        }

        Text(
            text = "›",
            fontSize = 20.sp,
            color = LagCheckColors.TextMuted,
            modifier = Modifier.padding(end = 4.dp)
        )
    }
}
