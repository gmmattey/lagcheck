package com.lagcheck.android.ui.home

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.collectIsDraggedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsTopHeight
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.R
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.ui.components.PlatformHealthBanner
import com.lagcheck.android.ui.components.RemoteGameArtwork
import com.lagcheck.android.ui.tr
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.FavoriteGames
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.network.health.PlatformHealth
import kotlinx.coroutines.delay

/**
 * 01 · Home Cockpit (Decisão 113).
 * Check Geral de Conexão protagonista com Gauge Circular ("TESTAR" no centro)
 * e carrossel inferior dos jogos favoritos/recentes.
 */
@Composable
fun HomeScreen(
    selectedGame: CatalogGame,
    platform: String,
    connectionType: String,
    latestCheck: CheckHistoryItem?,
    recentGameChecks: List<Pair<CatalogGame, CheckHistoryItem>> = emptyList(),
    favoriteGames: List<CatalogGame> = emptyList(),
    popularGames: List<CatalogGame> = emptyList(),
    onStartCheck: () -> Unit,
    onStartGameCheck: (CatalogGame) -> Unit = {},
    onOpenGames: () -> Unit,
    onOpenLatestResult: () -> Unit,
    onOpenHistoryItem: (CheckHistoryItem) -> Unit = { onOpenLatestResult() },
    platformHealth: PlatformHealth? = null,
    showNativeAd: Boolean = false,
    modifier: Modifier = Modifier
) {
    val nativeAd = if (showNativeAd) com.lagcheck.android.ads.rememberNativeAd(com.lagcheck.session.ads.AdPlacement.HOME) else null

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            // 1. Hero full-bleed até o topo (edge-to-edge com fade contínuo na base)
            HomeHeroCarousel(
                recentGameChecks = recentGameChecks,
                fallbackLatestCheck = latestCheck,
                onStartGeneralCheck = onStartCheck,
                onStartGameCheck = onStartGameCheck,
                onOpenHistoryItem = onOpenHistoryItem
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = LagCheckSpacing.space6)
            ) {
                Spacer(modifier = Modifier.height(LagCheckSpacing.space4))

                // 2. Barra de busca logo abaixo da capa principal
                val searchShape = RoundedCornerShape(LagCheckRadius.md)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .defaultMinSize(minHeight = 46.dp)
                        .clip(searchShape)
                        .background(LagCheckColors.Surface)
                        .clickable { onOpenGames() }
                        .padding(horizontal = LagCheckSpacing.space4, vertical = LagCheckSpacing.space3),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2_5)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Search,
                        contentDescription = null,
                        tint = LagCheckColors.TextMuted,
                        modifier = Modifier.size(18.dp)
                    )
                    Text(
                        text = tr("Buscar jogo..."),
                        style = LagCheckTypography.BodyMedium.copy(fontSize = 14.sp),
                        color = LagCheckColors.TextMuted,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                if (platformHealth != null) {
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space4))
                    PlatformHealthBanner(platformHealth)
                }

                Spacer(modifier = Modifier.height(LagCheckSpacing.space6))

                // 3. Trilho 1: SEUS FAVORITOS (pôsteres 3:4)
                val gamesList = favoriteGames.take(FavoriteGames.MAX)
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
                ) {
                    HomeSectionHeader(
                        title = tr("SEUS FAVORITOS"),
                        onSeeAll = onOpenGames
                    )

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
                    ) {
                        gamesList.forEach { game ->
                            HomeGameCard(
                                game = game,
                                onClick = { onStartGameCheck(game) }
                            )
                        }

                        if (gamesList.size < FavoriteGames.MAX) {
                            AddFavoriteGameCard(onClick = onOpenGames)
                        }
                    }
                }

                // 4. Grade 2x3: POPULARES
                if (popularGames.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space6))

                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
                    ) {
                        Column(
                            verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space1)
                        ) {
                            HomeSectionHeader(
                                title = tr("POPULARES"),
                                onSeeAll = onOpenGames
                            )
                            Text(
                                text = tr("Toque no jogo para iniciar o teste"),
                                style = LagCheckTypography.Subtext,
                                color = LagCheckColors.TextMuted
                            )
                        }

                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
                        ) {
                            popularGames.take(6).chunked(3).forEach { rowGames ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
                                ) {
                                    rowGames.forEach { game ->
                                        HomeGameCard(
                                            game = game,
                                            onClick = { onStartGameCheck(game) },
                                            modifier = Modifier
                                                .weight(1f)
                                                .aspectRatio(0.75f)
                                        )
                                    }
                                    repeat(3 - rowGames.size) {
                                        Spacer(modifier = Modifier.weight(1f))
                                    }
                                }
                            }
                        }
                    }
                }

                if (nativeAd != null) {
                    com.lagcheck.android.ads.NativeAdSlot(
                        nativeAd,
                        Modifier.padding(top = LagCheckSpacing.space6)
                    )
                }
                Spacer(modifier = Modifier.height(LagCheckSpacing.space6))
            }
        }

        // Protege os ícones da barra de status durante a rolagem sobre a arte e o conteúdo
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .windowInsetsTopHeight(WindowInsets.statusBars)
                .background(
                    Brush.verticalGradient(
                        0.0f to LagCheckColors.Background.copy(alpha = 0.85f),
                        1.0f to LagCheckColors.Background.copy(alpha = 0.35f)
                    )
                )
        )
    }
}

@Composable
private fun HomeSectionHeader(
    title: String,
    onSeeAll: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = LagCheckTypography.MonoSmall,
            color = LagCheckColors.TextSecondary,
            letterSpacing = 1.2.sp
        )

        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(LagCheckRadius.sm))
                .clickable { onSeeAll() }
                .padding(horizontal = LagCheckSpacing.space1_5, vertical = LagCheckSpacing.space1),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = tr("Ver todos"),
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = LagCheckColors.AccentPrimaryLight
            )
            Text(
                text = " ›",
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                color = LagCheckColors.AccentPrimaryLight
            )
        }
    }
}

@Composable
private fun HomeGameCard(
    game: CatalogGame,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
        .width(114.dp)
        .height(152.dp)
) {
    val shape = RoundedCornerShape(LagCheckRadius.md)
    Box(
        modifier = modifier
            .clip(shape)
            .background(LagCheckColors.Surface)
            .clickable { onClick() }
    ) {
        RemoteGameArtwork(
            game = game,
            modifier = Modifier.fillMaxSize()
        )

        // Gradiente escuro para contraste
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        0.0f to Color.Transparent,
                        0.4f to Color.Transparent,
                        0.75f to LagCheckColors.Background.copy(alpha = 0.85f),
                        1.0f to LagCheckColors.Background
                    )
                )
        )

        // Conteúdo
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(LagCheckSpacing.space2_5),
            verticalArrangement = Arrangement.Bottom
        ) {
            Text(
                text = game.name,
                fontSize = 12.sp,
                lineHeight = 14.sp,
                fontWeight = FontWeight.Bold,
                color = LagCheckColors.TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun AddFavoriteGameCard(
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val shape = RoundedCornerShape(LagCheckRadius.md)
    Box(
        modifier = modifier
            .width(114.dp)
            .height(152.dp)
            .clip(shape)
            .background(LagCheckColors.Surface)
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
        ) {
            Icon(
                imageVector = Icons.Filled.Add,
                contentDescription = null,
                tint = LagCheckColors.AccentPrimaryLight
            )
            Text(
                text = tr("Adicionar"),
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = LagCheckColors.TextSecondary
            )
        }
    }
}

@Composable
private fun HomeHeroCarousel(
    recentGameChecks: List<Pair<CatalogGame, CheckHistoryItem>>,
    fallbackLatestCheck: CheckHistoryItem?,
    onStartGeneralCheck: () -> Unit,
    onStartGameCheck: (CatalogGame) -> Unit,
    onOpenHistoryItem: (CheckHistoryItem) -> Unit
) {
    val statusBarTop = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val heroHeight = 288.dp + statusBarTop

    if (recentGameChecks.isEmpty()) {
        HomeHeroSlideCard(
            title = tr("PRONTO PRA RANKED?"),
            latestCheck = fallbackLatestCheck,
            onStartClick = onStartGeneralCheck,
            onOpenCheck = { fallbackLatestCheck?.let(onOpenHistoryItem) },
            modifier = Modifier
                .fillMaxWidth()
                .height(heroHeight),
            backgroundContent = {
                Image(
                    painter = painterResource(id = R.drawable.home_hero_default),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            }
        )
        return
    }

    val pagerState = rememberPagerState(pageCount = { recentGameChecks.size })
    val isDragged by pagerState.interactionSource.collectIsDraggedAsState()
    LaunchedEffect(pagerState, recentGameChecks.size, isDragged) {
        if (!isDragged && recentGameChecks.size > 1) {
            while (true) {
                delay(5_000L)
                val nextPage = (pagerState.currentPage + 1) % recentGameChecks.size
                pagerState.animateScrollToPage(nextPage)
            }
        }
    }

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
    ) {
        HorizontalPager(
            state = pagerState,
            pageSpacing = 0.dp,
            modifier = Modifier.fillMaxWidth()
        ) { page ->
            val (game, check) = recentGameChecks[page]
            HomeHeroSlideCard(
                title = game.name.uppercase(),
                latestCheck = check,
                onStartClick = { onStartGameCheck(game) },
                onOpenCheck = { onOpenHistoryItem(check) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(heroHeight),
                backgroundContent = {
                    RemoteGameArtwork(
                        game = game,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            )
        }

        if (recentGameChecks.size > 1) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                repeat(recentGameChecks.size) { index ->
                    val active = pagerState.currentPage == index
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 3.dp)
                            .width(if (active) 18.dp else 6.dp)
                            .height(6.dp)
                            .clip(CircleShape)
                            .background(if (active) LagCheckColors.AccentPrimary else LagCheckColors.TextTertiary)
                    )
                }
            }
        }
    }
}

@Composable
private fun HomeHeroSlideCard(
    title: String,
    latestCheck: CheckHistoryItem?,
    onStartClick: () -> Unit,
    onOpenCheck: () -> Unit,
    modifier: Modifier = Modifier,
    backgroundContent: @Composable () -> Unit
) {
    Box(
        modifier = modifier.background(LagCheckColors.Background)
    ) {
        backgroundContent()

        // Gradiente contínuo da arte para legibilidade da status bar no topo e fusão ao fundo #0B0D10 na base
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        0.00f to LagCheckColors.Background.copy(alpha = 0.45f),
                        0.26f to LagCheckColors.Background.copy(alpha = 0.10f),
                        0.56f to LagCheckColors.Background.copy(alpha = 0.65f),
                        0.86f to LagCheckColors.Background.copy(alpha = 0.96f),
                        1.00f to LagCheckColors.Background
                    )
                )
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        0.0f to LagCheckColors.Background.copy(alpha = 0.35f),
                        0.70f to Color.Transparent
                    )
                )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .padding(
                    start = LagCheckSpacing.space6,
                    end = LagCheckSpacing.space6,
                    top = LagCheckSpacing.space3,
                    bottom = LagCheckSpacing.space4
                ),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            HeroLastCheckPill(
                latestCheck = latestCheck,
                onClick = onOpenCheck
            )

            Column(
                verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
            ) {
                Text(
                    text = title,
                    style = LagCheckTypography.VerdictHero.copy(fontSize = 32.sp, lineHeight = 34.sp),
                    color = LagCheckColors.TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                PrimaryButton(
                    text = tr("TESTAR AGORA"),
                    onClick = onStartClick,
                    height = 46.dp,
                    contentColor = Color.White
                )
            }
        }
    }
}

@Composable
private fun HeroLastCheckPill(
    latestCheck: CheckHistoryItem?,
    onClick: () -> Unit
) {
    val pillShape = RoundedCornerShape(percent = 50)
    if (latestCheck == null) {
        Row(
            modifier = Modifier
                .clip(pillShape)
                .background(LagCheckColors.Background.copy(alpha = 0.72f))
                .padding(horizontal = LagCheckSpacing.space3, vertical = LagCheckSpacing.space1_5),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = tr("— Nenhum check ainda"),
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        return
    }

    val symbol = when (latestCheck.verdict) {
        GameReadinessVerdict.READY -> "●"
        GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY -> "▲"
        GameReadinessVerdict.INCONCLUSIVE -> "—"
    }
    val verdictName = when (latestCheck.verdict) {
        GameReadinessVerdict.READY -> tr("PRONTO PARA RANKED")
        GameReadinessVerdict.CAUTION -> tr("CONDIÇÕES INSTÁVEIS")
        GameReadinessVerdict.NOT_READY -> tr("EVITARIA RANKED AGORA")
        GameReadinessVerdict.INCONCLUSIVE -> tr("INCONCLUSIVO")
    }
    val verdictColor = when (latestCheck.verdict) {
        GameReadinessVerdict.READY -> LagCheckColors.Good
        GameReadinessVerdict.CAUTION -> LagCheckColors.SemanticCaution
        GameReadinessVerdict.NOT_READY -> LagCheckColors.CoralWarning
        GameReadinessVerdict.INCONCLUSIVE -> LagCheckColors.TextMuted
    }

    Row(
        modifier = Modifier
            .clip(pillShape)
            .background(LagCheckColors.Background.copy(alpha = 0.72f))
            .clickable { onClick() }
            .padding(horizontal = LagCheckSpacing.space3, vertical = LagCheckSpacing.space1_5),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space1_5)
    ) {
        Text(
            text = symbol,
            style = LagCheckTypography.MonoSmall,
            color = verdictColor
        )
        Text(
            text = verdictName,
            style = LagCheckTypography.MonoSmall,
            color = LagCheckColors.TextPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f, fill = false)
        )
        Text(
            text = "›",
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = LagCheckColors.TextMuted
        )
    }
}
