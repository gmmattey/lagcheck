package com.lagcheck.android.ui.games

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.lagcheck.android.R
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.components.StarIcon
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
    var searchQuery by remember { mutableStateOf("") }
    val content = remember(allGames, recentChecks, favorites, searchQuery) {
        gameSelectionContent(allGames, recentChecks, favorites, searchQuery)
    }
    val hasSearchText = searchQuery.isNotBlank()

    LazyColumn(
        modifier = modifier.fillMaxSize().background(LagCheckColors.Background).padding(horizontal = LagCheckSpacing.space6)
    ) {
        item {
            TopBar(showBackButton, onBack)
            Spacer(Modifier.height(LagCheckSpacing.space3_5))
            Text(tr("Jogos"), style = LagCheckTypography.PageTitle, color = LagCheckColors.TextPrimary)
            Spacer(Modifier.height(LagCheckSpacing.space4))
            SearchField(searchQuery) { searchQuery = it }
            Spacer(Modifier.height(LagCheckSpacing.space5))
        }

        if (hasSearchText) {
            if (content.searchResults.isEmpty()) {
                item { EmptySearch(onStartGeneralCheck) }
            } else {
                item { RailTitle(trf("RESULTADOS (%d)", content.searchResults.size)) }
                items(content.searchResults, key = { "result-${it.id}" }) { game ->
                    GameRow(game, game.id in favorites, onToggleFavorite, onGameSelected)
                }
                item { Spacer(Modifier.height(LagCheckSpacing.space10)) }
            }
        } else {
            if (content.recentGames.isNotEmpty()) {
                item { GameRail(tr("RECENTES"), content.recentGames, favorites, onToggleFavorite, onGameSelected) }
            }
            if (content.favoriteGames.isNotEmpty()) {
                item { GameRail(tr("FAVORITOS"), content.favoriteGames, favorites, onToggleFavorite, onGameSelected) }
            }
            item { RailTitle(tr("TODOS OS JOGOS A–Z")) }
            items(content.allGames.chunked(2), key = { row -> "grid-${row.first().id}" }) { row ->
                Row(Modifier.padding(bottom = LagCheckSpacing.space3), horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)) {
                    row.forEach { game ->
                        GameCard(game, game.id in favorites, onToggleFavorite, onGameSelected, Modifier.weight(1f))
                    }
                    if (row.size == 1) Spacer(Modifier.weight(1f))
                }
            }
            // A escolha essencial terminou; anúncio nunca entra em busca ou vazio.
            if (nativeAd != null) {
                item(key = "native_ad") {
                    com.lagcheck.android.ads.NativeAdSlot(nativeAd, Modifier.padding(top = LagCheckSpacing.space2, bottom = LagCheckSpacing.space8))
                }
            } else item { Spacer(Modifier.height(LagCheckSpacing.space10)) }
        }
    }
}

@Composable
private fun TopBar(showBackButton: Boolean, onBack: () -> Unit) {
    Box(Modifier.fillMaxWidth().height(52.dp).padding(top = LagCheckSpacing.space2)) {
        if (showBackButton) {
            Box(Modifier.size(48.dp).clip(CircleShape).clickable(onClick = onBack), Alignment.CenterStart) {
                com.lagcheck.core.designsystem.components.ChevronLeftIcon(
                    modifier = Modifier.padding(start = LagCheckSpacing.space1),
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

/** Busca sempre visível: a pessoa no lobby digita sem abrir nada antes. */
@Composable
private fun SearchField(query: String, onQueryChange: (String) -> Unit) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = { Text(tr("Buscar jogo"), color = LagCheckColors.TextMuted, style = LagCheckTypography.BodyMedium) },
        textStyle = LagCheckTypography.BodyMedium,
        leadingIcon = { com.lagcheck.core.designsystem.components.SearchIcon(size = 18.dp, color = LagCheckColors.TextMuted) },
        trailingIcon = if (query.isEmpty()) null else {
            {
                Box(
                    Modifier.size(48.dp).clip(CircleShape).clickable { onQueryChange("") }
                        .semantics { contentDescription = tr("Fechar busca") },
                    contentAlignment = Alignment.Center
                ) { com.lagcheck.core.designsystem.components.CloseIcon(size = 16.dp, color = LagCheckColors.TextMuted) }
            }
        },
        modifier = Modifier.fillMaxWidth().defaultMinSize(minHeight = 52.dp),
        singleLine = true,
        shape = RoundedCornerShape(percent = 50),
        colors = searchFieldColors()
    )
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
    LazyRow(horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)) {
        items(games, key = { "rail-$title-${it.id}" }) { game ->
            GameCard(game, game.id in favorites, onToggleFavorite, onGameSelected, Modifier.width(140.dp))
        }
    }
    Spacer(Modifier.height(LagCheckSpacing.space6))
}

@Composable
private fun RailTitle(title: String) {
    Text(title, style = LagCheckTypography.MonoKicker, color = LagCheckColors.TextMuted)
    Spacer(Modifier.height(LagCheckSpacing.space3))
}

/** Estrela de favorito: alvo de 44 dp próprio, separado do toque que inicia o Check. */
@Composable
private fun FavoriteToggle(game: CatalogGame, isFavorite: Boolean, onToggle: (CatalogGame) -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier.size(44.dp).clip(CircleShape).clickable { onToggle(game) }
            .semantics { contentDescription = if (isFavorite) tr("Remover dos favoritos") else tr("Favoritar") },
        contentAlignment = Alignment.Center
    ) {
        Box(Modifier.size(30.dp).clip(CircleShape).background(LagCheckColors.Scrim), contentAlignment = Alignment.Center) {
            StarIcon(
                filled = isFavorite,
                size = 17.dp,
                color = if (isFavorite) LagCheckColors.AccentPrimaryLight else LagCheckColors.TextPrimary
            )
        }
    }
}

@Composable
private fun GameCard(
    game: CatalogGame,
    isFavorite: Boolean,
    onToggleFavorite: (CatalogGame) -> Unit,
    onClick: (CatalogGame) -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier) {
        Column(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(LagCheckRadius.md)).clickable { onClick(game) }
                .semantics { contentDescription = trf("Fazer Check de %s", game.name) }
        ) {
            Box(Modifier.fillMaxWidth().aspectRatio(4f / 3f).clip(RoundedCornerShape(LagCheckRadius.md)).background(LagCheckColors.Panel)) {
                com.lagcheck.android.ui.components.RemoteGameArtwork(game, Modifier.fillMaxSize())
            }
            Text(
                game.name,
                modifier = Modifier.padding(top = LagCheckSpacing.space2).defaultMinSize(minHeight = 44.dp),
                style = LagCheckTypography.Subtext.copy(fontWeight = FontWeight.SemiBold),
                color = LagCheckColors.TextPrimary
            )
        }
        FavoriteToggle(game, isFavorite, onToggleFavorite, Modifier.align(Alignment.TopEnd))
    }
}

/** Resultado de busca: lista vertical A–Z, mais rápida de varrer que um trilho. */
@Composable
private fun GameRow(
    game: CatalogGame,
    isFavorite: Boolean,
    onToggleFavorite: (CatalogGame) -> Unit,
    onClick: (CatalogGame) -> Unit
) {
    Row(Modifier.fillMaxWidth().padding(bottom = LagCheckSpacing.space2), verticalAlignment = Alignment.CenterVertically) {
        Row(
            Modifier.weight(1f).defaultMinSize(minHeight = 60.dp).clip(RoundedCornerShape(LagCheckRadius.md))
                .clickable { onClick(game) }
                .semantics { contentDescription = trf("Fazer Check de %s", game.name) },
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(Modifier.size(width = 80.dp, height = 60.dp).clip(RoundedCornerShape(LagCheckRadius.sm)).background(LagCheckColors.Panel)) {
                com.lagcheck.android.ui.components.RemoteGameArtwork(game, Modifier.fillMaxSize())
            }
            Text(
                game.name,
                modifier = Modifier.weight(1f).padding(horizontal = LagCheckSpacing.space3),
                style = LagCheckTypography.BodySemibold,
                color = LagCheckColors.TextPrimary
            )
        }
        FavoriteToggle(game, isFavorite, onToggleFavorite)
    }
}

@Composable
private fun EmptySearch(onStartGeneralCheck: () -> Unit) {
    Column(Modifier.fillMaxWidth().padding(vertical = LagCheckSpacing.space6), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(tr("Nenhum jogo encontrado"), style = LagCheckTypography.SectionHeader, color = LagCheckColors.TextPrimary)
        Spacer(Modifier.height(LagCheckSpacing.space4))
        PrimaryButton(text = tr("Fazer Check Geral"), onClick = onStartGeneralCheck, modifier = Modifier.width(260.dp), height = 52.dp)
    }
    Spacer(Modifier.height(LagCheckSpacing.space10))
}

@Composable
private fun searchFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedContainerColor = LagCheckColors.Surface, unfocusedContainerColor = LagCheckColors.Surface,
    focusedBorderColor = LagCheckColors.AccentPrimary, unfocusedBorderColor = LagCheckColors.BorderStrong,
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
        it.name.contains(query, ignoreCase = true)
    }
    return GameSelectionContent(
        allGames = alphabetical,
        recentGames = recent,
        favoriteGames = favorites.resolve(alphabetical),
        searchResults = results
    )
}
