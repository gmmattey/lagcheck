package com.lagcheck.desktop.ui.library

import androidx.compose.foundation.clickable
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.desktop.AppState
import com.lagcheck.desktop.ds.*
import com.lagcheck.desktop.library.repository.LibraryFilter

/**
 * Uma única rolagem virtualizada para a Home. Não existe paginação de 40 jogos.
 * O shell não deve aplicar verticalScroll à rota Home.
 */
@Composable
fun LibraryView(
    state: AppState,
    modifier: Modifier = Modifier,
    header: @Composable () -> Unit = {},
    footer: @Composable () -> Unit = {}
) {
    val repo = state.library
    val games = repo.filteredGames
    val listState = rememberLazyListState()

    BoxWithConstraints(modifier.fillMaxSize()) {
        val columns = when {
            maxWidth < 680.dp -> 2
            maxWidth < 920.dp -> 3
            else -> 4
        }
        // Cada item da LazyColumn corresponde a uma linha de cards; somente as
        // linhas visíveis e próximas são compostas.
        val rows = remember(games, columns) { games.chunked(columns) }
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            state = listState,
            contentPadding = PaddingValues(bottom = 30.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item(key = "header") {
                Column {
                    header()
                    if (repo.games.isNotEmpty()) {
                        repo.selectedGame?.let { selected ->
                            LibraryHero(selected, state)
                            Spacer(Modifier.height(28.dp))
                        }
                    }
                }
            }
            if (repo.games.isEmpty()) {
                item(key = "empty") {
                    EmptyLibrary(scanning = repo.isScanning, onSearch = { repo.rescan() })
                }
            } else {
                item(key = "filters") {
                    Row(
                        Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            LibraryFilter.values().forEach { filter ->
                                val active = repo.filter == filter
                                Box(
                                    Modifier
                                        .clip(RoundedCornerShape(LcRadius.pill))
                                        .background(if (active) LcColor.Accent else LcColor.Surface)
                                        .border(1.dp, if (active) LcColor.AccentLight else LcColor.BorderHairline, RoundedCornerShape(LcRadius.pill))
                                        .clickable { repo.filter = filter }
                                        .padding(horizontal = 14.dp, vertical = 6.dp)
                                ) {
                                    Text(filter.label.uppercase(), style = LcType.Section.copy(fontSize = 11.sp),
                                        color = if (active) Color.White else LcColor.TextSecondary)
                                }
                            }
                        }
                        Text("${games.size} JOGOS", style = LcType.Section, color = LcColor.TextTertiary)
                    }
                }
                if (games.isEmpty()) {
                    item(key = "no-matches") {
                        Box(
                            Modifier.fillMaxWidth().height(180.dp)
                                .clip(RoundedCornerShape(LcRadius.r13))
                                .background(LcColor.Surface),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("Nenhum jogo corresponde ao filtro.", style = LcType.Body, color = LcColor.TextSecondary)
                        }
                    }
                } else {
                    items(
                        count = rows.size,
                        key = { index -> "row-${index}" }
                    ) { index ->
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                            rows[index].forEach { game ->
                                GameCard(
                                    game = game,
                                    isSelected = repo.selectedGame?.id == game.id,
                                    onClick = { repo.selectGame(game) },
                                    onToggleFavorite = { repo.toggleFavorite(game) },
                                    artwork = state.artwork,
                                    artworkGeneration = state.artworkGeneration,
                                    modifier = Modifier.weight(1f)
                                )
                            }
                            repeat(columns - rows[index].size) {
                                Spacer(Modifier.weight(1f))
                            }
                        }
                    }
                }
            }
            item(key = "footer") { footer() }
        }
    }
}

@Composable
private fun EmptyLibrary(scanning: Boolean, onSearch: () -> Unit) {
    Box(
        Modifier.fillMaxWidth().height(320.dp)
            .clip(RoundedCornerShape(LcRadius.r17))
            .background(LcColor.Surface)
            .border(1.dp, LcColor.BorderHairline, RoundedCornerShape(LcRadius.r17)),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            if (scanning) {
                Text("Procurando seus jogos…", style = LcType.PageTitle, color = LcColor.TextPrimary)
            } else {
                Text("Nenhum jogo encontrado", style = LcType.PageTitle, color = LcColor.TextPrimary)
                Spacer(Modifier.height(6.dp))
                Text("Procuramos na Steam e na Epic Games.", style = LcType.Body, color = LcColor.TextSecondary)
                Spacer(Modifier.height(20.dp))
                LibraryButton(text = "Procurar de novo", onClick = onSearch)
            }
        }
    }
}
