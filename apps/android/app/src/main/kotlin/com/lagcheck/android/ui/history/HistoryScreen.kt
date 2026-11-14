package com.lagcheck.android.ui.history

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.android.data.HistoryRitualSummary
import com.lagcheck.android.ui.components.SecondaryScreenHeader
import com.lagcheck.core.designsystem.components.rowDivider
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import com.lagcheck.domain.model.CatalogGame
import com.lagcheck.domain.model.GameReadinessEvaluation
import com.lagcheck.domain.model.GameReadinessVerdict
import com.lagcheck.domain.model.OfficialGameCatalog
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf

/**
 * 06 · Histórico.
 * Paridade 1:1 estrita com o protótipo de alta fidelidade Open Design (Screen 06 · Histórico).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    catalogGames: List<com.lagcheck.domain.model.CatalogGame>,
    historyItems: List<CheckHistoryItem>,
    onBack: () -> Unit,
    onSelectCheck: (CheckHistoryItem) -> Unit,
    onClearHistory: () -> Unit,
    onGoToHome: () -> Unit,
    showNativeAd: Boolean = false,
    modifier: Modifier = Modifier
) {
    val nativeAd = if (showNativeAd) com.lagcheck.android.ads.rememberNativeAd(com.lagcheck.session.ads.AdPlacement.HISTORY) else null
    val context = LocalContext.current
    var showConfirmDeleteSheet by remember { mutableStateOf(false) }
    var selectedRitualWindow by remember { mutableStateOf(14) }

    // Agrupamento por jogo idêntico ao protótipo
    val groupedByGame = remember(historyItems) {
        historyItems.groupBy { it.gameId }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = LagCheckSpacing.space6)
        ) {
            // 1. Header Canônico: Voltar '‹' + Histórico + Limpar
            item {
                SecondaryScreenHeader(
                    title = tr("Histórico"),
                    onBack = null,
                    trailingAction = {
                        if (historyItems.isNotEmpty()) {
                            Text(
                                text = tr("Limpar"),
                                fontSize = 13.sp,
                                color = LagCheckColors.TextMuted,
                                modifier = Modifier
                                    .clickable { showConfirmDeleteSheet = true }
                                    .padding(horizontal = LagCheckSpacing.space2, vertical = LagCheckSpacing.space1_5)
                            )
                        }
                    }
                )
            }

            // 2. Se vazio: Estado Vazio idêntico ao protótipo
            if (historyItems.isEmpty()) {
                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(475.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Box(
                            modifier = Modifier
                                .size(55.dp)
                                .clip(CircleShape)
                                .background(LagCheckColors.Surface),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "—",
                                fontSize = 22.sp,
                                color = LagCheckColors.TextMuted
                            )
                        }

                        Spacer(modifier = Modifier.height(LagCheckSpacing.space3))

                        Text(
                            text = tr("Nenhum check ainda"),
                            style = LagCheckTypography.PageTitle.copy(fontSize = 25.sp),
                            color = LagCheckColors.TextPrimary
                        )

                        Spacer(modifier = Modifier.height(LagCheckSpacing.space2))

                        Text(
                            text = tr("Faça seu primeiro teste na Home"),
                            style = LagCheckTypography.BodyMedium,
                            color = LagCheckColors.TextMuted,
                            textAlign = TextAlign.Center
                        )

                        Spacer(modifier = Modifier.height(LagCheckSpacing.space5))

                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(LagCheckRadius.lg))
                                .background(LagCheckColors.Surface)
                                .clickable { onGoToHome() }
                                .padding(horizontal = LagCheckSpacing.space4, vertical = LagCheckSpacing.space3)
                        ) {
                            Text(
                                text = tr("Ir para a Home"),
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = LagCheckColors.TextPrimary
                            )
                        }
                    }
                }
                if (nativeAd != null) {
                    item(key = "native_ad_empty") {
                        com.lagcheck.android.ads.NativeAdSlot(
                            nativeAd,
                            Modifier.padding(bottom = LagCheckSpacing.space4)
                        )
                    }
                }
            } else {
                item(key = "ritual_window") {
                    RitualWindowPicker(selectedWindow = selectedRitualWindow, onSelected = { selectedRitualWindow = it })
                }

                // 3. Resumo: checks · prontos · jogos
                item(key = "summary") {
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space3_5))
                    val summaryShape = RoundedCornerShape(LagCheckRadius.md)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .shadow(elevation = 6.dp, shape = summaryShape)
                            .clip(summaryShape)
                            .background(LagCheckColors.Surface)
                            .padding(horizontal = LagCheckSpacing.space5, vertical = LagCheckSpacing.space4_5)
                    ) {
                        listOf(
                            Triple(historyItems.size.toString(), tr("checks"), 0.8f),
                            Triple(historyItems.count { it.verdict == GameReadinessVerdict.READY }.toString(), tr("prontos p/ Ranked"), 1.5f),
                            Triple(groupedByGame.size.toString(), tr("jogos"), 0.8f)
                        ).forEach { (value, label, w) ->
                            Column(modifier = Modifier.weight(w)) {
                                Text(text = value, fontSize = 26.sp, fontWeight = FontWeight.Medium, color = LagCheckColors.TextPrimary)
                                Spacer(modifier = Modifier.height(LagCheckSpacing.space1))
                                Text(text = label, fontSize = 12.sp, color = LagCheckColors.TextMuted)
                            }
                        }
                    }
                }

                if (nativeAd != null) {
                    item(key = "native_ad") {
                        com.lagcheck.android.ads.NativeAdSlot(
                            nativeAd,
                            Modifier.padding(top = LagCheckSpacing.space4, bottom = LagCheckSpacing.space1_5)
                        )
                    }
                }

                // 4. Um cartão por jogo, com seus checks dentro
                groupedByGame.forEach { (gameId, checks) ->
                    val catalogGame = catalogGames.firstOrNull { it.id == gameId }
                        ?: (OfficialGameCatalog.games + OfficialGameCatalog.pendingExpansion).firstOrNull { it.id == gameId }
                        ?: com.lagcheck.domain.model.CatalogGame(gameId, checks.first().gameName, "Online", drawableResName = "")

                    item(key = "group_$gameId") {
                        val groupShape = RoundedCornerShape(LagCheckRadius.md)
                        Column(
                            modifier = Modifier
                                .padding(top = LagCheckSpacing.space2_5)
                                .fillMaxWidth()
                                .shadow(elevation = 6.dp, shape = groupShape)
                                .clip(groupShape)
                                .background(LagCheckColors.Surface)
                                .padding(start = LagCheckSpacing.space4_5, end = LagCheckSpacing.space4_5, top = LagCheckSpacing.space1_5, bottom = LagCheckSpacing.space1)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = LagCheckSpacing.space3, bottom = LagCheckSpacing.space2_5),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(42.dp)
                                        .clip(RoundedCornerShape(LagCheckRadius.md))
                                        .background(LagCheckColors.Panel)
                                ) {
                                    com.lagcheck.android.ui.components.RemoteGameArtwork(catalogGame, Modifier.fillMaxSize())
                                }
                                Spacer(modifier = Modifier.width(LagCheckSpacing.space3))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = catalogGame.name,
                                        fontSize = 16.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = LagCheckColors.TextPrimary,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                    Spacer(modifier = Modifier.height(LagCheckSpacing.space1))
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
                                    ) {
                                        com.lagcheck.core.designsystem.components.PlatformGlyph(platform = "Mobile")
                                        Text(
                                            text = if (checks.size == 1) tr("1 check") else trf("%d checks", checks.size),
                                            fontSize = 12.sp,
                                            color = LagCheckColors.TextMuted
                                        )
                                    }
                                }
                            }

                            HistoryRitualSummary.forEntries(checks, selectedRitualWindow)
                                ?.takeIf { it.hasEnoughEvidence }
                                ?.let { summary ->
                                    Column(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = LagCheckSpacing.space3)
                                    ) {
                                        Text(
                                            text = trf("Pronto em %d de %d checks", summary.readyCount, summary.comparableCount),
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = LagCheckColors.TextPrimary
                                        )
                                        Spacer(modifier = Modifier.height(LagCheckSpacing.space1))
                                        Text(
                                            text = trf("Instável: %d · Evitaria: %d · Inconclusivos: %d", summary.cautionCount, summary.notReadyCount, summary.inconclusiveCount),
                                            style = LagCheckTypography.MonoSmall,
                                            color = LagCheckColors.TextMuted
                                        )
                                    }
                                }
                            checks.forEachIndexed { index, item ->
                                HistoryRowItem(item = item, showDivider = index < checks.lastIndex, onClick = { onSelectCheck(item) })
                            }
                        }
                    }
                }

                // Nota de rodapé
                item {
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space7))
                    Text(
                        text = tr("Histórico salvo neste dispositivo · até 100 checks"),
                        style = LagCheckTypography.MonoSmall,
                        color = LagCheckColors.TextMuted,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space10))
                }
            }
        }

        // Sheet de Confirmação para Apagar Todo o Histórico
        if (showConfirmDeleteSheet) {
            val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

            ModalBottomSheet(
                onDismissRequest = { showConfirmDeleteSheet = false },
                sheetState = sheetState,
                containerColor = LagCheckColors.Surface,
                dragHandle = {
                    Box(
                        modifier = Modifier
                            .padding(top = LagCheckSpacing.space2_5, bottom = LagCheckSpacing.space4_5)
                            .size(width = 35.dp, height = 4.dp)
                            .clip(RoundedCornerShape(LagCheckRadius.sm))
                            .background(LagCheckColors.Border)
                    )
                }
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = LagCheckSpacing.space6)
                        .padding(bottom = LagCheckSpacing.space8)
                ) {
                    Text(
                        text = tr("Apagar todo o histórico?"),
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                        color = LagCheckColors.TextPrimary
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space2))

                    Text(
                        text = tr("Esta ação não pode ser desfeita."),
                        style = LagCheckTypography.BodyMedium,
                        color = LagCheckColors.TextMuted
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space6))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
                    ) {
                        // Cancelar
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(52.dp)
                                .clip(RoundedCornerShape(LagCheckRadius.lg))
                                .background(LagCheckColors.Panel)
                                .clickable { showConfirmDeleteSheet = false },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = tr("Cancelar"),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = LagCheckColors.TextPrimary
                            )
                        }

                        // Apagar (Coral Solar destrutivo)
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(52.dp)
                                .clip(RoundedCornerShape(LagCheckRadius.lg))
                                .background(LagCheckColors.CoralWarning)
                                .clickable {
                                    showConfirmDeleteSheet = false
                                    onClearHistory()
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = tr("Apagar"),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun RitualWindowPicker(selectedWindow: Int, onSelected: (Int) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = LagCheckSpacing.space3_5, bottom = LagCheckSpacing.space1),
        horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
    ) {
        listOf(7, 14, 30).forEach { days ->
            val selected = days == selectedWindow
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(percent = 50))
                    .background(if (selected) LagCheckColors.Panel else LagCheckColors.Surface)
                    .clickable { onSelected(days) }
                    .height(44.dp)
                    .padding(horizontal = LagCheckSpacing.space3),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = trf("Últimos %d dias", days),
                    style = LagCheckTypography.MonoSmall,
                    color = if (selected) LagCheckColors.TextPrimary else LagCheckColors.TextMuted
                )
            }
        }
    }
}

@Composable
private fun HistoryRowItem(
    item: CheckHistoryItem,
    showDivider: Boolean = true,
    onClick: () -> Unit
) {
    val chipColor = when (item.verdict) {
        GameReadinessVerdict.READY -> LagCheckColors.Good
        GameReadinessVerdict.CAUTION -> LagCheckColors.SemanticCaution
        GameReadinessVerdict.NOT_READY -> LagCheckColors.CoralWarning
        GameReadinessVerdict.INCONCLUSIVE -> LagCheckColors.TextMuted
    }

    val headlineText = when (item.verdict) {
        GameReadinessVerdict.READY -> tr("Pronto para Ranked")
        GameReadinessVerdict.CAUTION -> tr("Condições Instáveis")
        GameReadinessVerdict.NOT_READY -> tr("Evitaria Ranked Agora")
        GameReadinessVerdict.INCONCLUSIVE -> tr("Inconclusivo")
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (showDivider) Modifier.rowDivider() else Modifier)
            .clickable { onClick() }
            .padding(vertical = LagCheckSpacing.space3)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = Modifier
                    .height(26.dp)
                    .clip(RoundedCornerShape(percent = 50))
                    .background(chipColor.copy(alpha = 0.15f))
                    .padding(horizontal = LagCheckSpacing.space3),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
            ) {
                Box(Modifier.size(7.dp).clip(CircleShape).background(chipColor))
                Text(text = headlineText, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = chipColor)
            }
            Text(text = item.formattedDate, fontSize = 12.sp, color = LagCheckColors.TextMuted)
        }
        Spacer(modifier = Modifier.height(LagCheckSpacing.space2))
        Text(text = item.metricsString, style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
    }
}
