package com.lagcheck.desktop.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.desktop.AppState
import com.lagcheck.desktop.ds.*
import com.lagcheck.desktop.library.repository.LibraryFilter

@Composable
fun LibraryView(
    state: AppState,
    modifier: Modifier = Modifier
) {
    val repo = state.library
    val games = repo.filteredGames
    // Evita compor centenas de cartões de uma vez no shell com rolagem externa.
    // A virtualização real exige migrar a rolagem do AppShell para um LazyColumn/LazyGrid único.
    var visibleCount by remember { mutableIntStateOf(40) }
    LaunchedEffect(repo.filter, repo.searchQuery) { visibleCount = 40 }
    val visibleGames = games.take(visibleCount)

    if (repo.games.isEmpty()) {
        EmptyLibrary(scanning = repo.isScanning, onSearch = { repo.rescan() }, modifier = modifier)
        return
    }

    Column(modifier.fillMaxWidth()) {
        // Destaque Cinematográfico do Jogo Ativo
        repo.selectedGame?.let { selected ->
            LibraryHero(selected, state)
            Spacer(Modifier.height(28.dp))
        }

        // Barra de Filtros e Busca
        Row(
            Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                LibraryFilter.values().forEach { filter ->
                    val isActive = repo.filter == filter
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(LcRadius.pill))
                            .background(if (isActive) LcColor.Accent else LcColor.Surface)
                            .border(1.dp, if (isActive) LcColor.AccentLight else LcColor.BorderHairline, RoundedCornerShape(LcRadius.pill))
                            .clickable { repo.filter = filter }
                            .padding(horizontal = 14.dp, vertical = 6.dp)
                    ) {
                        Text(
                            text = filter.label.uppercase(),
                            style = LcType.Section.copy(fontSize = 11.sp),
                            color = if (isActive) Color.White else LcColor.TextSecondary
                        )
                    }
                }
            }

            // Contador de Jogos
            Text(
                text = "${games.size} JOGOS",
                style = LcType.Section,
                color = LcColor.TextTertiary
            )
        }

        Spacer(Modifier.height(18.dp))

        // Grade de Cartões
        if (games.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(220.dp)
                    .clip(RoundedCornerShape(LcRadius.r13))
                    .background(LcColor.Surface)
                    .border(1.dp, LcColor.BorderHairline, RoundedCornerShape(LcRadius.r13)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("NENHUM JOGO ENCONTRADO", style = LcType.Section, color = LcColor.TextSecondary)
                    Spacer(Modifier.height(8.dp))
                    Text("Tente ajustar os filtros ou verificar a busca.", style = LcType.Body, color = LcColor.TextTertiary)
                }
            }
        } else {
            BoxWithConstraints(Modifier.fillMaxWidth()) {
                val columns = when {
                    maxWidth < 680.dp -> 2
                    maxWidth < 920.dp -> 3
                    else -> 4
                }

                Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    visibleGames.chunked(columns).forEach { row ->
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                            row.forEach { game ->
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
                            repeat(columns - row.size) {
                                Spacer(Modifier.weight(1f))
                            }
                        }
                    }
                }
            }
            if (visibleCount < games.size) {
                Spacer(Modifier.height(16.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                    LibraryButton(
                        text = "Mostrar mais jogos (${games.size - visibleCount})",
                        onClick = { visibleCount += 40 },
                        isPrimary = false
                    )
                }
            }
        }
    }
}

/** Biblioteca sem nenhum jogo: ou ainda procurando, ou nada encontrado nos launchers. */
@Composable
private fun EmptyLibrary(scanning: Boolean, onSearch: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(320.dp)
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
