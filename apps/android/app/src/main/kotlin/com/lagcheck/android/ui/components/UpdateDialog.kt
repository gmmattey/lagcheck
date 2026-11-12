package com.lagcheck.android.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.ui.tr
import com.lagcheck.android.update.AppUpdateUiState
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UpdateDialog(
    state: AppUpdateUiState,
    onStartUpdate: () -> Unit,
    onInstallApk: (File) -> Unit,
    onDismiss: () -> Unit,
    onCancelDownload: () -> Unit,
    onOpenInBrowser: () -> Unit,
    onOpenInStore: () -> Unit
) {
    val isVisible = state is AppUpdateUiState.UpdateAvailable ||
        state is AppUpdateUiState.Downloading ||
        state is AppUpdateUiState.ReadyToInstall ||
        state is AppUpdateUiState.NeedsInstallPermission ||
        state is AppUpdateUiState.Error

    if (!isVisible) return

    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(
        onDismissRequest = {
            if (state is AppUpdateUiState.Downloading) {
                onCancelDownload()
            } else {
                onDismiss()
            }
        },
        sheetState = sheetState,
        containerColor = LagCheckColors.Background,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(top = 12.dp, bottom = 8.dp)
                    .size(width = 36.dp, height = 4.dp)
                    .clip(CircleShape)
                    .background(LagCheckColors.TextMuted.copy(alpha = 0.4f))
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = LagCheckSpacing.screenMarginHorizontal)
                .padding(bottom = LagCheckSpacing.space8),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            when (state) {
                is AppUpdateUiState.UpdateAvailable -> {
                    // Badge esportiva
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(LagCheckRadius.xs))
                            .background(LagCheckColors.AccentPrimary.copy(alpha = 0.15f))
                            .border(1.dp, LagCheckColors.AccentPrimary.copy(alpha = 0.4f), RoundedCornerShape(LagCheckRadius.xs))
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = tr("Nova versão disponível").uppercase(),
                            style = LagCheckTypography.BodySemibold.copy(
                                color = LagCheckColors.AccentPrimary,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 1.sp,
                                fontSize = 12.sp
                            )
                        )
                    }

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space3_5))

                    Text(
                        text = "LagCheck v${state.newVersion}",
                        style = LagCheckTypography.SectionHeader.copy(
                            color = LagCheckColors.TextPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 24.sp
                        ),
                        textAlign = TextAlign.Center
                    )

                    if (state.downloadSize > 0) {
                        val sizeMb = state.downloadSize.toDouble() / (1024 * 1024)
                        Spacer(modifier = Modifier.height(LagCheckSpacing.space1))
                        Text(
                            text = String.format(java.util.Locale.ROOT, "%.1f MB", sizeMb),
                            style = LagCheckTypography.BodyMedium.copy(color = LagCheckColors.TextMuted)
                        )
                    }

                    if (state.releaseNotes.isNotBlank()) {
                        Spacer(modifier = Modifier.height(LagCheckSpacing.space4))
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(LagCheckRadius.md))
                                .background(LagCheckColors.Surface)
                                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(LagCheckRadius.md))
                                .padding(LagCheckSpacing.cardPadding)
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .verticalScroll(rememberScrollState())
                            ) {
                                Text(
                                    text = state.releaseNotes,
                                    style = LagCheckTypography.BodyMedium.copy(
                                        color = LagCheckColors.TextSecondary,
                                        lineHeight = 20.sp
                                    )
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space6))

                    PrimaryButton(
                        text = if (state.isFromStore) tr("Ver na loja") else tr("ATUALIZAR AGORA"),
                        onClick = onStartUpdate
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space3))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = tr("Agora não"),
                            style = LagCheckTypography.BodyMedium.copy(
                                color = LagCheckColors.TextMuted,
                                fontWeight = FontWeight.Medium
                            ),
                            modifier = Modifier
                                .clickable(onClick = onDismiss)
                                .padding(8.dp)
                        )

                        Text(
                            text = if (state.isFromStore) tr("Ver na loja") else tr("Baixar pelo navegador"),
                            style = LagCheckTypography.BodyMedium.copy(
                                color = LagCheckColors.AccentPrimary,
                                fontWeight = FontWeight.Medium
                            ),
                            modifier = Modifier
                                .clickable {
                                    if (state.isFromStore) onOpenInStore() else onOpenInBrowser()
                                }
                                .padding(8.dp)
                        )
                    }
                }

                is AppUpdateUiState.Downloading -> {
                    Text(
                        text = tr("Baixando atualização…"),
                        style = LagCheckTypography.SectionHeader.copy(
                            color = LagCheckColors.TextPrimary,
                            fontWeight = FontWeight.Bold
                        )
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space4_5))

                    if (state.progressPercent >= 0) {
                        LinearProgressIndicator(
                            progress = { state.progressPercent / 100f },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(8.dp)
                                .clip(RoundedCornerShape(LagCheckRadius.xs)),
                            color = LagCheckColors.AccentPrimary,
                            trackColor = LagCheckColors.Surface
                        )

                        Spacer(modifier = Modifier.height(LagCheckSpacing.space2_5))

                        val mbDownloaded = state.bytesDownloaded.toDouble() / (1024 * 1024)
                        val mbTotal = state.totalBytes.toDouble() / (1024 * 1024)
                        Text(
                            text = String.format(java.util.Locale.ROOT, "%d%% (%.1f / %.1f MB)", state.progressPercent, mbDownloaded, mbTotal),
                            style = LagCheckTypography.BodyMedium.copy(color = LagCheckColors.TextSecondary)
                        )
                    } else {
                        LinearProgressIndicator(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(8.dp)
                                .clip(RoundedCornerShape(LagCheckRadius.xs)),
                            color = LagCheckColors.AccentPrimary,
                            trackColor = LagCheckColors.Surface
                        )
                    }

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space6))

                    Text(
                        text = tr("Cancelar"),
                        style = LagCheckTypography.BodyMedium.copy(
                            color = LagCheckColors.TextMuted,
                            fontWeight = FontWeight.Medium
                        ),
                        modifier = Modifier
                            .clickable(onClick = onCancelDownload)
                            .padding(12.dp)
                    )
                }

                is AppUpdateUiState.ReadyToInstall -> {
                    Text(
                        text = tr("Download concluído!"),
                        style = LagCheckTypography.SectionHeader.copy(
                            color = LagCheckColors.TextPrimary,
                            fontWeight = FontWeight.Bold
                        )
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space5))

                    PrimaryButton(
                        text = tr("INSTALAR AGORA"),
                        onClick = { onInstallApk(state.apkFile) }
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space3))

                    Text(
                        text = tr("Agora não"),
                        style = LagCheckTypography.BodyMedium.copy(
                            color = LagCheckColors.TextMuted,
                            fontWeight = FontWeight.Medium
                        ),
                        modifier = Modifier
                            .clickable(onClick = onDismiss)
                            .padding(8.dp)
                    )
                }

                is AppUpdateUiState.NeedsInstallPermission -> {
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(LagCheckRadius.xs))
                            .background(LagCheckColors.SemanticCaution.copy(alpha = 0.15f))
                            .border(1.dp, LagCheckColors.SemanticCaution.copy(alpha = 0.4f), RoundedCornerShape(LagCheckRadius.xs))
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = tr("PERMITIR E INSTALAR"),
                            style = LagCheckTypography.BodySemibold.copy(
                                color = LagCheckColors.SemanticCaution,
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp
                            )
                        )
                    }

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space3_5))

                    Text(
                        text = tr("Para atualizar, autorize a instalação do app nas configurações do sistema."),
                        style = LagCheckTypography.BodyMedium.copy(
                            color = LagCheckColors.TextSecondary,
                            textAlign = TextAlign.Center
                        )
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space5))

                    PrimaryButton(
                        text = tr("PERMITIR E INSTALAR"),
                        onClick = { onInstallApk(state.apkFile) }
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space3))

                    Text(
                        text = tr("Agora não"),
                        style = LagCheckTypography.BodyMedium.copy(
                            color = LagCheckColors.TextMuted,
                            fontWeight = FontWeight.Medium
                        ),
                        modifier = Modifier
                            .clickable(onClick = onDismiss)
                            .padding(8.dp)
                    )
                }

                is AppUpdateUiState.Error -> {
                    Text(
                        text = tr("Falha no download da atualização"),
                        style = LagCheckTypography.SectionHeader.copy(
                            color = LagCheckColors.CoralWarning,
                            fontWeight = FontWeight.Bold
                        )
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space2_5))

                    Text(
                        text = state.message,
                        style = LagCheckTypography.BodyMedium.copy(
                            color = LagCheckColors.TextSecondary,
                            textAlign = TextAlign.Center
                        )
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space5))

                    PrimaryButton(
                        text = tr("Baixar pelo navegador"),
                        onClick = onOpenInBrowser
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space3))

                    Text(
                        text = tr("Voltar"),
                        style = LagCheckTypography.BodyMedium.copy(
                            color = LagCheckColors.TextMuted,
                            fontWeight = FontWeight.Medium
                        ),
                        modifier = Modifier
                            .clickable(onClick = onDismiss)
                            .padding(8.dp)
                    )
                }

                else -> Unit
            }
        }
    }
}
