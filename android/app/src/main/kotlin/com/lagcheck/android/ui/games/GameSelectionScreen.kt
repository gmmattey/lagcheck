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
    showBackButton: Boolean = false,
    onBack: () -> Unit,
    onGameSelected: (game: CatalogGame, platform: String, connectionType: String, declaredExternalLink: com.lagcheck.domain.model.ExternalEquipmentLink?) -> Unit,
    onStartGeneralCheck: () -> Unit,
    /** Últimos checks reais do histórico. Sem histórico, a seção de recentes não aparece. */
    recentChecks: List<CheckHistoryItem> = emptyList(),
    favorites: FavoriteGames = FavoriteGames.EMPTY,
    onToggleFavorite: (CatalogGame) -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var searchQuery by remember { mutableStateOf("") }
    var isSearchActive by remember { mutableStateOf(false) }

    // Bottom sheet state para selecionar plataforma e conexão
    var pendingGameForSheet by remember { mutableStateOf<CatalogGame?>(null) }
    var selectedPlatform by remember { mutableStateOf("PlayStation") }
    var selectedDeclaredLink by remember(pendingGameForSheet?.id) { mutableStateOf(com.lagcheck.domain.model.ExternalEquipmentLink.WIFI) }

    val allGames = OfficialGameCatalog.games
    val filteredGames = remember(searchQuery) {
        if (searchQuery.isBlank()) allGames
        else allGames.filter { it.name.contains(searchQuery, ignoreCase = true) || it.category.contains(searchQuery, ignoreCase = true) }
    }

    // Recentes saem do histórico real; favoritos, da escolha da pessoa (salva no aparelho).
    val favoriteGames = remember(favorites) { favorites.resolve(allGames) }
    val recentGames = remember(recentChecks) {
        recentChecks.distinctBy { it.gameId }.take(3).map { it to OfficialGameCatalog.findById(it.gameId) }
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
            // 1. Barra de Topo: Voltar '‹' + Wordmark + Ícone de Busca
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

                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .clip(CircleShape)
                            .clickable { isSearchActive = !isSearchActive },
                        contentAlignment = Alignment.Center
                    ) {
                        if (isSearchActive) {
                            com.lagcheck.core.designsystem.components.CloseIcon(
                                size = 18.dp,
                                color = LagCheckColors.TextPrimary
                            )
                        } else {
                            com.lagcheck.core.designsystem.components.SearchIcon(
                                size = 18.dp,
                                color = LagCheckColors.TextPrimary
                            )
                        }
                    }
                }
            }

            // Barra de Busca expansível
            if (isSearchActive) {
                item {
                    Spacer(modifier = Modifier.height(10.dp))
                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { searchQuery = it },
                        placeholder = { Text(tr("Buscar jogo"), color = LagCheckColors.TextMuted, fontSize = 14.sp) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        singleLine = true,
                        shape = RoundedCornerShape(13.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedContainerColor = LagCheckColors.Surface,
                            unfocusedContainerColor = LagCheckColors.Surface,
                            focusedBorderColor = LagCheckColors.AccentPrimary,
                            unfocusedBorderColor = LagCheckColors.Border,
                            focusedTextColor = LagCheckColors.TextPrimary,
                            unfocusedTextColor = LagCheckColors.TextPrimary
                        )
                    )
                }
            }

            // 2. Título de Seção: "Jogos" + "trocar quando precisar"
            item {
                Spacer(modifier = Modifier.height(14.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = tr("Jogos"),
                        style = LagCheckTypography.PageTitle,
                        color = LagCheckColors.TextPrimary
                    )
                    Text(
                        text = tr("trocar quando precisar"),
                        style = LagCheckTypography.MonoData,
                        color = LagCheckColors.TextMuted
                    )
                }
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
                                onClick = {
                                    pendingGameForSheet = game
                                    selectedPlatform = game.platforms.firstOrNull() ?: "PlayStation"
                                }
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
                            .clip(RoundedCornerShape(12.dp))
                            .background(LagCheckColors.Surface)
                            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(12.dp))
                            .clickable {
                                pendingGameForSheet = recentGame
                                selectedPlatform = recentGame.platforms.firstOrNull { it == check.platform }
                                    ?: recentGame.platforms.firstOrNull() ?: "Mobile"
                            }
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
                            Text(
                                text = check.platform,
                                style = LagCheckTypography.MonoSmall,
                                color = LagCheckColors.TextMuted
                            )
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
            }

            items(filteredGames) { game ->
                CatalogRowItem(
                    game = game,
                    isFavorite = game.id in favorites,
                    onToggleFavorite = { onToggleFavorite(game) },
                    onClick = {
                        pendingGameForSheet = game
                        selectedPlatform = game.platforms.firstOrNull() ?: "PlayStation"
                    }
                )
            }

            // 6. Card Assist: "Não encontrou o jogo? Faça um Check Geral"
            item {
                Spacer(modifier = Modifier.height(32.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(18.dp))
                        .background(LagCheckColors.Surface)
                        .border(1.dp, LagCheckColors.Border, RoundedCornerShape(18.dp))
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
                            .clip(RoundedCornerShape(12.dp))
                            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(12.dp))
                            .clickable { onStartGeneralCheck() }
                            .padding(horizontal = 16.dp, vertical = 12.dp)
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

        // 7. Bottom Sheet de Seleção de Plataforma e Tipo de Conexão
        pendingGameForSheet?.let { game ->
            val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

            ModalBottomSheet(
                onDismissRequest = { pendingGameForSheet = null },
                sheetState = sheetState,
                containerColor = LagCheckColors.Surface,
                dragHandle = {
                    Box(
                        modifier = Modifier
                            .padding(top = 10.dp, bottom = 18.dp)
                            .size(width = 35.dp, height = 4.dp)
                            .clip(RoundedCornerShape(9.dp))
                            .background(LagCheckColors.Border)
                    )
                }
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 32.dp)
                ) {
                    Column(
                        modifier = Modifier
                            .weight(1f, fill = false)
                            .verticalScroll(rememberScrollState())
                            .padding(horizontal = 22.dp)
                    ) {
                        Text(
                            text = game.name,
                            style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                            color = LagCheckColors.TextPrimary,
                            modifier = Modifier.padding(top = 16.dp, bottom = 2.dp)
                        )

                        Text(
                            text = tr("Onde você joga?"),
                            fontSize = 13.sp,
                            color = LagCheckColors.TextMuted,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )

                        // Lista de escolhas de plataforma
                        game.platforms.forEach { platform ->
                            val isSelected = selectedPlatform == platform
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(48.dp)
                                    .clickable { selectedPlatform = platform }
                            ) {
                                // Top divider
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(1.dp)
                                        .background(LagCheckColors.BorderStrong)
                                )

                                Row(
                                    modifier = Modifier.fillMaxSize(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = platform,
                                        fontSize = 15.sp,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                        color = if (isSelected) LagCheckColors.AccentPrimary else LagCheckColors.TextPrimary
                                    )
                                    if (isSelected) {
                                        Text(
                                            text = "✓",
                                            fontSize = 16.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = LagCheckColors.AccentPrimary
                                        )
                                    }
                                }
                            }
                        }

                        if (PlatformLabels.toPlatform(selectedPlatform) != Platform.MOBILE) {
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = String.format(tr("Como o %s está conectado?"), selectedPlatform),
                                fontSize = 13.sp,
                                color = LagCheckColors.TextMuted,
                                modifier = Modifier.padding(bottom = 8.dp)
                            )

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                listOf(
                                    com.lagcheck.domain.model.ExternalEquipmentLink.WIFI to "Wi-Fi",
                                    com.lagcheck.domain.model.ExternalEquipmentLink.ETHERNET to tr("Cabo")
                                ).forEach { (link, label) ->
                                    val isSelected = selectedDeclaredLink == link
                                    Box(
                                        modifier = Modifier
                                            .weight(1f)
                                            .defaultMinSize(minHeight = 44.dp)
                                            .height(42.dp)
                                            .clip(RoundedCornerShape(11.dp))
                                            .background(Color.Transparent)
                                            .border(
                                                width = 1.dp,
                                                color = if (isSelected) LagCheckColors.AccentPrimary else LagCheckColors.BorderStrong,
                                                shape = RoundedCornerShape(11.dp)
                                            )
                                            .clickable { selectedDeclaredLink = link },
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = label,
                                            fontSize = 14.sp,
                                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                            color = if (isSelected) LagCheckColors.AccentPrimary else LagCheckColors.TextPrimary
                                        )
                                    }
                                }
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                        }
                    }

                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 22.dp, vertical = 12.dp)
                    ) {
                        PrimaryButton(
                            text = tr("Iniciar Check"),
                            onClick = {
                                val targetGame = pendingGameForSheet ?: game
                                val chosenPlatform = selectedPlatform
                                val declaredLink = if (PlatformLabels.toPlatform(chosenPlatform) == Platform.MOBILE) null else selectedDeclaredLink
                                pendingGameForSheet = null
                                onGameSelected(targetGame, chosenPlatform, "", declaredLink)
                            },
                            height = 56.dp
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun FavoriteCard(
    game: CatalogGame,
    onClick: () -> Unit
) {
    val context = LocalContext.current
    val resId = context.resources.getIdentifier(game.drawableResName, "drawable", context.packageName)

    Column(
        modifier = Modifier
            .size(width = 93.dp, height = 110.dp)
            .clip(RoundedCornerShape(13.dp))
            .background(LagCheckColors.Surface)
            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(13.dp))
            .clickable { onClick() }
            .padding(6.dp)
    ) {
        Box(
            modifier = Modifier
                .size(width = 79.dp, height = 67.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(LagCheckColors.Panel)
        ) {
            if (resId != 0) {
                Image(
                    painter = painterResource(id = resId),
                    contentDescription = game.name,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            }
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
    val context = LocalContext.current
    val resId = context.resources.getIdentifier(game.drawableResName, "drawable", context.packageName)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(78.dp)
            .clickable { onClick() }
            .border(width = 0.5.dp, color = LagCheckColors.Border.copy(alpha = 0.5f))
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
            if (resId != 0) {
                Image(
                    painter = painterResource(id = resId),
                    contentDescription = game.name,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            }
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
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = game.platformsFormatted,
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
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
