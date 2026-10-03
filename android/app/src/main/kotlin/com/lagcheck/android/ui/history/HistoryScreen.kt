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

/**
 * 06 · Histórico.
 * Paridade 1:1 estrita com o protótipo de alta fidelidade Open Design (Screen 06 · Histórico).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
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
                    title = "Histórico",
                    onBack = onBack,
                    trailingAction = {
                        if (historyItems.isNotEmpty()) {
                            Text(
                                text = "Limpar",
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
                            text = "Nenhum check ainda",
                            style = LagCheckTypography.PageTitle.copy(fontSize = 25.sp),
                            color = LagCheckColors.TextPrimary
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Text(
                            text = "Faça seu primeiro teste na Home",
                            style = LagCheckTypography.BodyMedium,
                            color = LagCheckColors.TextMuted,
                            textAlign = TextAlign.Center
                        )

                        Spacer(modifier = Modifier.height(19.dp))

                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(12.dp))
                                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(12.dp))
                                .clickable { onGoToHome() }
                                .padding(horizontal = 16.dp, vertical = 12.dp)
                        ) {
                            Text(
                                text = "Ir para a Home",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = LagCheckColors.TextPrimary
                            )
                        }
                    }
                }
            } else {
                // 3. Grupos por Jogo
                groupedByGame.forEach { (gameId, checks) ->
                    val catalogGame = OfficialGameCatalog.findById(gameId)
                    val resId = context.resources.getIdentifier(catalogGame.drawableResName, "drawable", context.packageName)

                    // Header do grupo do jogo
                    item(key = "header_$gameId") {
                        Spacer(modifier = Modifier.height(15.dp))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(56.dp)
                                .border(width = 0.5.dp, color = LagCheckColors.Border.copy(alpha = 0.5f))
                                .padding(bottom = 10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Capa 38x46
                            Box(
                                modifier = Modifier
                                    .size(width = 38.dp, height = 46.dp)
                                    .clip(RoundedCornerShape(7.dp))
                                    .background(LagCheckColors.Surface)
                                    .border(1.dp, LagCheckColors.Border, RoundedCornerShape(7.dp))
                            ) {
                                if (resId != 0) {
                                    Image(
                                        painter = painterResource(id = resId),
                                        contentDescription = catalogGame.name,
                                        contentScale = ContentScale.Crop,
                                        modifier = Modifier.fillMaxSize()
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.width(10.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = catalogGame.name,
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = LagCheckColors.TextPrimary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Spacer(modifier = Modifier.height(3.dp))
                                Text(
                                    text = "${checks.firstOrNull()?.platform ?: "PlayStation"} · última plataforma",
                                    style = LagCheckTypography.MonoSmall,
                                    color = LagCheckColors.TextMuted
                                )
                            }

                            Text(
                                text = "›",
                                fontSize = 18.sp,
                                color = LagCheckColors.TextMuted
                            )
                        }
                    }

                    // Itens do histórico para este jogo
                    items(checks, key = { it.id }) { item ->
                        HistoryRowItem(
                            item = item,
                            onClick = { onSelectCheck(item) }
                        )
                    }
                }

                // Nota de rodapé
                item {
                    Spacer(modifier = Modifier.height(28.dp))
                    Text(
                        text = "Histórico salvo neste dispositivo · até 100 checks por jogo",
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
                        text = "Apagar todo o histórico?",
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                        color = LagCheckColors.TextPrimary
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = "Esta ação não pode ser desfeita.",
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
                                .clip(RoundedCornerShape(11.dp))
                                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(11.dp))
                                .clickable { showConfirmDeleteSheet = false },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "Cancelar",
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
                                .clip(RoundedCornerShape(11.dp))
                                .background(LagCheckColors.CoralWarning)
                                .clickable {
                                    showConfirmDeleteSheet = false
                                    onClearHistory()
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "Apagar",
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
    val symbolColor = when (item.verdict) {
        GameReadinessVerdict.READY -> LagCheckColors.Good
        GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY -> LagCheckColors.CoralWarning
        GameReadinessVerdict.INCONCLUSIVE -> LagCheckColors.TextMuted
    }

    val symbol = when (item.verdict) {
        GameReadinessVerdict.READY -> "●"
        GameReadinessVerdict.CAUTION, GameReadinessVerdict.NOT_READY -> "▲"
        GameReadinessVerdict.INCONCLUSIVE -> "—"
    }

    val headlineText = when (item.verdict) {
        GameReadinessVerdict.READY -> "Pronto para Ranked"
        GameReadinessVerdict.CAUTION -> "Condições Instáveis"
        GameReadinessVerdict.NOT_READY -> "Evitaria Ranked Agora"
        GameReadinessVerdict.INCONCLUSIVE -> "Inconclusivo"
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .border(width = 0.5.dp, color = LagCheckColors.Border.copy(alpha = 0.5f))
            .padding(vertical = 11.dp),
        verticalAlignment = Alignment.Top
    ) {
        Text(
            text = symbol,
            fontSize = 13.sp,
            color = symbolColor,
            modifier = Modifier.padding(top = 1.dp, end = 8.dp)
        )

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = headlineText,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = LagCheckColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(3.dp))
            Text(
                text = item.formattedDate,
                fontSize = 11.sp,
                color = LagCheckColors.TextMuted
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = item.metricsString,
                style = LagCheckTypography.MonoSmall,
                color = LagCheckColors.TextMuted
            )
        }
    }
}
