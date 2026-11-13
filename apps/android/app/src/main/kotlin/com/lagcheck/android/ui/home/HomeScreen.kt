package com.lagcheck.android.ui.home

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.collectIsDraggedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
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
import androidx.compose.ui.draw.shadow
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

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
            .verticalScroll(rememberScrollState())
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = LagCheckSpacing.space6)
        ) {
            Spacer(modifier = Modifier.height(LagCheckSpacing.space3))

            // 1. Barra de busca flutuante em pílula (Decisão 131)
            val searchShape = RoundedCornerShape(percent = 50)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(elevation = 6.dp, shape = searchShape)
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

            Spacer(modifier = Modifier.height(LagCheckSpacing.space4))

            // 2. Hero Carrossel com arte de fundo + veredito limpo (Decisão 132)
            HomeHeroCarousel(
                recentGameChecks = recentGameChecks,
                fallbackLatestCheck = latestCheck,
                onStartGeneralCheck = onStartCheck,
                onStartGameCheck = onStartGameCheck,
                onOpenHistoryItem = onOpenHistoryItem
            )

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

            // 4. Trilho 2: POPULARES (pôsteres 3:4)
            if (popularGames.isNotEmpty()) {
                Spacer(modifier = Modifier.height(LagCheckSpacing.space6))

                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
                ) {
                    HomeSectionHeader(
                        title = tr("POPULARES"),
                        onSeeAll = onOpenGames
                    )

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
                    ) {
                        popularGames.forEach { game ->
                            HomeGameCard(
                                game = game,
                                onClick = { onStartGameCheck(game) }
                            )
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
) {
    val shape = RoundedCornerShape(LagCheckRadius.md)
    Box(
        modifier = modifier
            .width(114.dp)
            .height(152.dp)
            .shadow(elevation = 6.dp, shape = shape)
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
                .padding(LagCheckSpacing.space3),
            verticalArrangement = Arrangement.Bottom
        ) {
            Text(
                text = game.name,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = LagCheckColors.TextPrimary,
                maxLines = 1
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
            .shadow(elevation = 6.dp, shape = shape)
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
    val heroShape = RoundedCornerShape(LagCheckRadius.md)
    if (recentGameChecks.isEmpty()) {
        HomeHeroSlideCard(
            title = tr("PRONTO PRA RANKED?"),
            latestCheck = fallbackLatestCheck,
            onStartClick = onStartGeneralCheck,
            onOpenCheck = { fallbackLatestCheck?.let(onOpenHistoryItem) },
            modifier = Modifier
                .fillMaxWidth()
                .height(216.dp)
                .shadow(elevation = 10.dp, shape = heroShape)
                .clip(heroShape),
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
        verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2_5)
    ) {
        HorizontalPager(
            state = pagerState,
            pageSpacing = LagCheckSpacing.space3,
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
                    .height(216.dp)
                    .shadow(elevation = 10.dp, shape = heroShape)
                    .clip(heroShape),
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
        modifier = modifier.background(LagCheckColors.Surface)
    ) {
        backgroundContent()

        // Gradiente escuro para garantir legibilidade do texto e CTA sobre qualquer arte
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        0.0f to LagCheckColors.Background.copy(alpha = 0.25f),
                        0.45f to LagCheckColors.Background.copy(alpha = 0.62f),
                        1.0f to LagCheckColors.Background.copy(alpha = 0.94f)
                    )
                )
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        0.0f to LagCheckColors.Background.copy(alpha = 0.42f),
                        0.75f to Color.Transparent
                    )
                )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(LagCheckSpacing.space5),
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

                HeroHaloButton(
                    text = tr("TESTAR AGORA"),
                    onClick = onStartClick
                )
            }
        }
    }
}

@Composable
private fun HeroHaloButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val pillShape = RoundedCornerShape(percent = 50)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color.White.copy(alpha = 0.40f),
                        LagCheckColors.AccentPrimaryLight.copy(alpha = 0.28f)
                    )
                ),
                shape = pillShape
            )
            .padding(4.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
                .shadow(
                    elevation = 12.dp,
                    shape = pillShape,
                    ambientColor = LagCheckColors.AccentPrimary,
                    spotColor = LagCheckColors.AccentPrimary
                )
                .clip(pillShape)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color(0xFF8B5CF6),
                            LagCheckColors.AccentPrimary,
                            Color(0xFF6D28D9)
                        )
                    )
                )
                .border(
                    width = 1.dp,
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Color.White.copy(alpha = 0.30f),
                            Color.Transparent
                        )
                    ),
                    shape = pillShape
                )
                .clickable(onClick = onClick)
                .padding(start = LagCheckSpacing.space5, end = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Spacer(modifier = Modifier.width(28.dp))
            Text(
                text = text,
                style = LagCheckTypography.CtaPrimary,
                color = Color.White,
                modifier = Modifier.weight(1f),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Box(
                modifier = Modifier
                    .size(28.dp)
                    .clip(CircleShape)
                    .background(Color.White),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = null,
                    tint = LagCheckColors.AccentPrimary,
                    modifier = Modifier.size(16.dp)
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
