package com.lagcheck.android.ui.games

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.R
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.FavoriteGames

/** Seleção direta: a tela só apresenta arte editorial e nome de jogos já conhecidos. */
@Composable
fun GameSelectionScreen(
    allGames: List<CatalogGame>,
    showBackButton: Boolean = false,
    onBack: () -> Unit,
    onGameSelected: (game: CatalogGame) -> Unit,
    onStartGeneralCheck: () -> Unit,
    recentChecks: List<CheckHistoryItem> = emptyList(),
    favorites: FavoriteGames = FavoriteGames.EMPTY,
    onToggleFavorite: (CatalogGame) -> Unit = {},
    showNativeAd: Boolean = false,
    modifier: Modifier = Modifier
) {
    val nativeAd = if (showNativeAd) {
        com.lagcheck.android.ads.rememberNativeAd(com.lagcheck.session.ads.AdPlacement.GAMES)
    } else null
    var searchOpen by remember { mutableStateOf(false) }
    var searchQuery by remember { mutableStateOf("") }
    val focusRequester = remember { FocusRequester() }
    val content = remember(allGames, recentChecks, favorites, searchQuery) {
        gameSelectionContent(allGames, recentChecks, favorites, searchQuery)
    }
    val hasSearchText = searchQuery.isNotBlank()

    LaunchedEffect(searchOpen) { if (searchOpen) focusRequester.requestFocus() }

    LazyColumn(
        modifier = modifier.fillMaxSize().background(LagCheckColors.Background).padding(horizontal = 24.dp)
    ) {
        item {
            TopBar(showBackButton, onBack)
            Spacer(Modifier.height(14.dp))
            Text(tr("Jogos"), style = LagCheckTypography.PageTitle, color = LagCheckColors.TextPrimary)
            Spacer(Modifier.height(16.dp))
            if (searchOpen) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text(tr("Buscar jogo"), color = LagCheckColors.TextMuted, fontSize = 14.sp) },
                    leadingIcon = { com.lagcheck.core.designsystem.components.SearchIcon(size = 18.dp, color = LagCheckColors.TextMuted) },
                    trailingIcon = {
                        Box(
                            Modifier.size(48.dp).clip(CircleShape).clickable {
                                searchQuery = ""
                                searchOpen = false
                            }.semantics { contentDescription = tr("Fechar busca") },
                            contentAlignment = Alignment.Center
                        ) { com.lagcheck.core.designsystem.components.CloseIcon(size = 16.dp, color = LagCheckColors.TextMuted) }
                    },
                    modifier = Modifier.fillMaxWidth().defaultMinSize(minHeight = 52.dp).focusRequester(focusRequester),
                    singleLine = true,
                    shape = RoundedCornerShape(percent = 50),
                    colors = searchFieldColors()
                )
            } else {
                SearchTrigger { searchOpen = true }
            }
            Spacer(Modifier.height(20.dp))
        }

        if (hasSearchText) {
            if (content.searchResults.isEmpty()) {
                item { EmptySearch(onStartGeneralCheck) }
            } else {
                item { GameRail(trf("RESULTADOS (%d)", content.searchResults.size), content.searchResults, favorites, onToggleFavorite, onGameSelected) }
            }
        } else {
            if (content.recentGames.isNotEmpty()) {
                item { GameRail(tr("RECENTES"), content.recentGames, favorites, onToggleFavorite, onGameSelected) }
            }
            if (content.favoriteGames.isNotEmpty()) {
                item { GameRail(tr("FAVORITOS"), content.favoriteGames, favorites, onToggleFavorite, onGameSelected) }
            }
            item { GameRail(tr("TODOS OS JOGOS A–Z"), content.allGames, favorites, onToggleFavorite, onGameSelected) }
            // A escolha essencial terminou; anúncio nunca entra em busca ou vazio.
            if (nativeAd != null) {
                item(key = "native_ad") {
                    com.lagcheck.android.ads.NativeAdSlot(nativeAd, Modifier.padding(top = 8.dp, bottom = 32.dp))
                }
            } else item { Spacer(Modifier.height(40.dp)) }
        }
    }
}

@Composable
private fun TopBar(showBackButton: Boolean, onBack: () -> Unit) {
    Box(Modifier.fillMaxWidth().height(52.dp).padding(top = 8.dp)) {
        if (showBackButton) {
            Box(Modifier.size(48.dp).clip(CircleShape).clickable(onClick = onBack), Alignment.CenterStart) {
                com.lagcheck.core.designsystem.components.ChevronLeftIcon(
                    modifier = Modifier.padding(start = 4.dp),
                    size = 20.dp,
                    color = LagCheckColors.TextPrimary
                )
            }
        }
        Image(
            painter = painterResource(R.drawable.wordmark_primary), contentDescription = "lagcheck",
            modifier = Modifier.width(110.dp).height(30.dp).align(Alignment.Center)
        )
    }
}

@Composable
private fun SearchTrigger(onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().defaultMinSize(minHeight = 52.dp).clip(RoundedCornerShape(percent = 50))
            .background(LagCheckColors.Surface).clickable(onClick = onClick)
            .semantics { contentDescription = tr("Buscar jogo") }.padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        com.lagcheck.core.designsystem.components.SearchIcon(size = 18.dp, color = LagCheckColors.TextMuted)
        Spacer(Modifier.width(10.dp))
        Text(tr("Buscar jogo"), color = LagCheckColors.TextMuted, fontSize = 14.sp)
    }
}

@Composable
private fun GameRail(
    title: String,
    games: List<CatalogGame>,
    favorites: FavoriteGames,
    onToggleFavorite: (CatalogGame) -> Unit,
    onGameSelected: (CatalogGame) -> Unit
) {
    RailTitle(title)
    LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        items(games, key = { "rail-$title-${it.id}" }) { game ->
            GameCard(game, game.id in favorites, onToggleFavorite, onGameSelected)
        }
    }
    Spacer(Modifier.height(24.dp))
}

@Composable
private fun RailTitle(title: String) {
    Text(title, style = LagCheckTypography.MonoKicker, color = LagCheckColors.TextMuted)
    Spacer(Modifier.height(11.dp))
}

@Composable
private fun GameCard(
    game: CatalogGame,
    isFavorite: Boolean,
    onToggleFavorite: (CatalogGame) -> Unit,
    onClick: (CatalogGame) -> Unit
) {
    Column(
        Modifier.width(140.dp).defaultMinSize(minHeight = 174.dp).clip(RoundedCornerShape(16.dp))
            .background(LagCheckColors.Surface).clickable { onClick(game) }
            .semantics { contentDescription = trf("Fazer Check de %s", game.name) }.padding(8.dp)
    ) {
        Box(Modifier.fillMaxWidth().height(116.dp).clip(RoundedCornerShape(10.dp)).background(LagCheckColors.Panel)) {
            com.lagcheck.android.ui.components.RemoteGameArtwork(game, Modifier.fillMaxSize())
        }
        Spacer(Modifier.height(9.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                game.name,
                modifier = Modifier.width(76.dp),
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = LagCheckColors.TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            Box(
                Modifier.size(44.dp).clickable { onToggleFavorite(game) }
                    .semantics { contentDescription = if (isFavorite) tr("Remover dos favoritos") else tr("Favoritar") },
                contentAlignment = Alignment.Center
            ) {
                Text(if (isFavorite) "★" else "☆", color = LagCheckColors.TextMuted, fontSize = 18.sp)
            }
        }
    }
}

@Composable
private fun EmptySearch(onStartGeneralCheck: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(LagCheckColors.Surface).padding(22.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(tr("Nenhum jogo encontrado"), style = LagCheckTypography.SectionHeader, color = LagCheckColors.TextPrimary)
        Spacer(Modifier.height(16.dp))
        Box(
            Modifier.defaultMinSize(minHeight = 48.dp).clip(RoundedCornerShape(percent = 50))
                .border(1.dp, LagCheckColors.BorderStrong, RoundedCornerShape(percent = 50))
                .clickable(onClick = onStartGeneralCheck).padding(horizontal = 18.dp),
            contentAlignment = Alignment.Center
        ) { Text(tr("Fazer Check Geral"), fontSize = 13.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary) }
    }
    Spacer(Modifier.height(40.dp))
}

@Composable
private fun searchFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedContainerColor = LagCheckColors.Surface, unfocusedContainerColor = LagCheckColors.Surface,
    focusedBorderColor = LagCheckColors.AccentPrimary, unfocusedBorderColor = Color.Transparent,
    focusedTextColor = LagCheckColors.TextPrimary, unfocusedTextColor = LagCheckColors.TextPrimary,
    cursorColor = LagCheckColors.AccentPrimary
)

private data class GameSelectionContent(
    val allGames: List<CatalogGame>,
    val recentGames: List<CatalogGame>,
    val favoriteGames: List<CatalogGame>,
    val searchResults: List<CatalogGame>
)

private fun gameSelectionContent(
    allGames: List<CatalogGame>,
    recentChecks: List<CheckHistoryItem>,
    favorites: FavoriteGames,
    searchQuery: String
): GameSelectionContent {
    val alphabetical = allGames.sortedWith(compareBy(String.CASE_INSENSITIVE_ORDER) { it.name })
    val recent = recentChecks
        .distinctBy { it.gameId }
        .mapNotNull { check -> alphabetical.firstOrNull { it.id == check.gameId } }
        .take(3)
    val query = searchQuery.trim()
    val results = if (query.isEmpty()) alphabetical else alphabetical.filter {
        it.name.contains(query, ignoreCase = true) || it.category.contains(query, ignoreCase = true)
    }
    return GameSelectionContent(
        allGames = alphabetical,
        recentGames = recent,
        favoriteGames = favorites.resolve(alphabetical),
        searchResults = results
    )
}
