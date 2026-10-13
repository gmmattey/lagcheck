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
import com.lagcheck.android.ui.components.SecondaryScreenHeader
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
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
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var showConfirmDeleteSheet by remember { mutableStateOf(false) }

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
                .padding(horizontal = 22.dp)
        ) {
            // 1. Header Canônico: Voltar '‹' + Histórico + Limpar
            item {
                SecondaryScreenHeader(
                    title = tr("Histórico"),
                    onBack = onBack,
                    trailingAction = {
                        if (historyItems.isNotEmpty()) {
                            Text(
                                text = tr("Limpar"),
                                fontSize = 13.sp,
                                color = LagCheckColors.TextMuted,
                                modifier = Modifier
                                    .clickable { showConfirmDeleteSheet = true }
                                    .padding(horizontal = 7.dp, vertical = 6.dp)
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
                                .border(1.dp, LagCheckColors.Border, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "—",
                                fontSize = 22.sp,
                                color = LagCheckColors.TextMuted
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Text(
                            text = tr("Nenhum check ainda"),
                            style = LagCheckTypography.PageTitle.copy(fontSize = 25.sp),
                            color = LagCheckColors.TextPrimary
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Text(
                            text = tr("Faça seu primeiro teste na Home"),
                            style = LagCheckTypography.BodyMedium,
                            color = LagCheckColors.TextMuted,
                            textAlign = TextAlign.Center
                        )

                        Spacer(modifier = Modifier.height(19.dp))

                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(percent = 50))
                                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(percent = 50))
                                .clickable { onGoToHome() }
                                .padding(horizontal = 16.dp, vertical = 12.dp)
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
            } else {
                // 3. Resumo: checks · prontos · jogos
                item(key = "summary") {
                    Spacer(modifier = Modifier.height(14.dp))
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(26.dp))
                            .background(LagCheckColors.Surface)
                            .padding(horizontal = 20.dp, vertical = 18.dp)
                    ) {
                        listOf(
                            historyItems.size.toString() to tr("checks"),
                            historyItems.count { it.verdict == GameReadinessVerdict.READY }.toString() to tr("prontos p/ Ranked"),
                            groupedByGame.size.toString() to tr("jogos")
                        ).forEach { (value, label) ->
                            Column(modifier = Modifier.weight(1f)) {
                                Text(text = value, fontSize = 26.sp, fontWeight = FontWeight.Medium, color = LagCheckColors.TextPrimary)
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(text = label, fontSize = 12.sp, color = LagCheckColors.TextMuted)
                            }
                        }
                    }
                }

                // 4. Um cartão por jogo, com seus checks dentro
                groupedByGame.forEach { (gameId, checks) ->
                    val catalogGame = catalogGames.firstOrNull { it.id == gameId }
                        ?: (OfficialGameCatalog.games + OfficialGameCatalog.pendingExpansion).firstOrNull { it.id == gameId }
                        ?: com.lagcheck.domain.model.CatalogGame(gameId, checks.first().gameName, "Online", drawableResName = "")

                    item(key = "group_$gameId") {
                        Column(
                            modifier = Modifier
                                .padding(top = 10.dp)
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(26.dp))
                                .background(LagCheckColors.Surface)
                                .padding(start = 18.dp, end = 18.dp, top = 6.dp, bottom = 4.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 12.dp, bottom = 10.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(42.dp)
                                        .clip(RoundedCornerShape(14.dp))
                                        .background(LagCheckColors.Panel)
                                ) {
                                    com.lagcheck.android.ui.components.RemoteGameArtwork(catalogGame, Modifier.fillMaxSize())
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = catalogGame.name,
                                        fontSize = 16.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = LagCheckColors.TextPrimary,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        checks.firstOrNull()?.platform?.let {
                                            com.lagcheck.core.designsystem.components.PlatformGlyph(platform = it)
                                        }
                                        Text(
                                            text = if (checks.size == 1) tr("1 check") else trf("%d checks", checks.size),
                                            fontSize = 12.sp,
                                            color = LagCheckColors.TextMuted
                                        )
                                    }
                                }
                            }
                            checks.forEach { item ->
                                HistoryRowItem(item = item, onClick = { onSelectCheck(item) })
                            }
                        }
                    }
                }

                // Nota de rodapé
                item {
                    Spacer(modifier = Modifier.height(28.dp))
                    Text(
                        text = tr("Histórico salvo neste dispositivo · até 100 checks"),
                        style = LagCheckTypography.MonoSmall,
                        color = LagCheckColors.TextMuted,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(40.dp))
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
                        .padding(horizontal = 22.dp)
                        .padding(bottom = 32.dp)
                ) {
                    Text(
                        text = tr("Apagar todo o histórico?"),
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                        color = LagCheckColors.TextPrimary
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = tr("Esta ação não pode ser desfeita."),
                        style = LagCheckTypography.BodyMedium,
                        color = LagCheckColors.TextMuted
                    )

                    Spacer(modifier = Modifier.height(24.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        // Cancelar
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(52.dp)
                                .clip(RoundedCornerShape(percent = 50))
                                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(percent = 50))
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
                                .clip(RoundedCornerShape(percent = 50))
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
private fun HistoryRowItem(
    item: CheckHistoryItem,
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
            .border(width = 0.5.dp, color = Color.White.copy(alpha = 0.08f))
            .clickable { onClick() }
            .padding(vertical = 12.dp)
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
                    .padding(horizontal = 11.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(7.dp)
            ) {
                Box(Modifier.size(7.dp).clip(CircleShape).background(chipColor))
                Text(text = headlineText, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = chipColor)
            }
            Text(text = item.formattedDate, fontSize = 12.sp, color = LagCheckColors.TextMuted)
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(text = item.metricsString, style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
    }
}
