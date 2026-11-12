package com.lagcheck.android.ui.settings

import android.content.Intent
import android.net.Uri
import android.widget.Toast
import android.app.TimePickerDialog
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
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.Switch
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.ui.components.SecondaryScreenHeader
import com.lagcheck.core.designsystem.components.rowDivider
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing
import com.lagcheck.core.designsystem.theme.LagCheckBrandColors
import com.lagcheck.android.ui.tr
import com.lagcheck.android.ui.trf
import com.lagcheck.android.ui.MainViewModel.RegionCandidate

/**
 * 07 · Ajustes.
 * Paridade 1:1 estrita com o protótipo de alta fidelidade Open Design (Screen 07 · Ajustes).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    currentLanguage: String,
    onLanguageSelected: (String) -> Unit,
    regionCandidates: List<RegionCandidate>,
    manualRegionId: String?,
    onRegionSelected: (String?) -> Unit,
    onOpenHistory: () -> Unit,
    onClearHistory: () -> Unit,
    reminderEnabled: Boolean,
    reminderHour: Int,
    reminderMinute: Int,
    reminderGameName: String?,
    reminderPermissionDenied: Boolean,
    onReminderToggle: (Boolean) -> Unit,
    onReminderTimeChanged: (Int, Int) -> Unit,
    onOpenNotificationSettings: () -> Unit,
    onBack: () -> Unit,
    analyticsCollectionAvailable: Boolean = false,
    analyticsCollectionEnabled: Boolean = false,
    onAnalyticsCollectionEnabledChanged: (Boolean) -> Unit = {},
    /** Só quando o UMP exigir (anúncios ligados). */
    privacyOptionsRequired: Boolean = false,
    onOpenPrivacyOptions: () -> Unit = {},
    onCheckForUpdates: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var showLanguageSheet by remember { mutableStateOf(false) }
    var showIconSheet by remember { mutableStateOf(false) }
    var currentIcon by remember { mutableStateOf(com.lagcheck.android.data.AppIconManager.current(context)) }
    var showDeleteConfirmSheet by remember { mutableStateOf(false) }
    var showRegionSheet by remember { mutableStateOf(false) }
    var showLicensesSheet by remember { mutableStateOf(false) }
    var reminderIsEnabled by remember(reminderEnabled) { mutableStateOf(reminderEnabled) }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = LagCheckSpacing.space6)
                .verticalScroll(rememberScrollState())
        ) {
            // Header Canônico: Voltar '‹' + Ajustes
            SecondaryScreenHeader(
                title = tr("Configurações"),
                onBack = null
            )

            // 1. Grupo: Preferências
            SettingsSectionHeader(title = tr("PREFERÊNCIAS"))

            SettingsGroup {

            SettingRow(
                title = tr("Idioma"),
                value = currentLanguage,
                onClick = { showLanguageSheet = true }
            )

            SettingRow(
                title = tr("Ícone do app"),
                value = tr(currentIcon.title),
                onClick = { showIconSheet = true }
            )

            if (regionCandidates.isNotEmpty()) {
                val activeRegionId = manualRegionId ?: "automatic"
                val regionLabel = if (activeRegionId == "automatic") {
                    tr("Automática")
                } else {
                    regionCandidates.firstOrNull { it.id == activeRegionId }?.label ?: tr("Automática")
                }
                SettingRow(
                    title = tr("Região de referência"),
                    value = regionLabel,
                    onClick = { showRegionSheet = true }
                )
            }
            val hasGame = !reminderGameName.isNullOrBlank()
            Row(modifier = Modifier.fillMaxWidth().height(if (reminderIsEnabled || !hasGame) 72.dp else 56.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(tr("Lembrete pré-partida"), fontSize = 14.sp, fontWeight = FontWeight.Bold, color = if (hasGame) LagCheckColors.TextPrimary else LagCheckColors.TextMuted)
                    if (!hasGame) Text(tr("Escolha um jogo para ativar."), fontSize = 12.sp, color = LagCheckColors.TextMuted)
                    else if (reminderIsEnabled) Text(trf("Todos os dias às %02d:%02d · %s", reminderHour, reminderMinute, reminderGameName), fontSize = 12.sp, color = LagCheckColors.TextMuted)
                }
                Switch(checked = reminderIsEnabled, enabled = hasGame, onCheckedChange = { enabled -> reminderIsEnabled = enabled; onReminderToggle(enabled) }, modifier = Modifier.size(width = 52.dp, height = 44.dp))
            }
            if (reminderIsEnabled) {
                SettingRow(title = tr("Horário"), value = String.format(java.util.Locale.getDefault(), "%02d:%02d", reminderHour, reminderMinute), onClick = {
                    TimePickerDialog(context, { _, hour, minute -> onReminderTimeChanged(hour, minute) }, reminderHour, reminderMinute, true).show()
                })
            }
            if (reminderPermissionDenied) {
                SettingRow(title = tr("Abrir ajustes do aparelho"), onClick = onOpenNotificationSettings)
            }
            }

            Spacer(modifier = Modifier.height(LagCheckSpacing.space4_5))

            // 2. Grupo: Histórico
            SettingsSectionHeader(title = tr("HISTÓRICO"))

            SettingsGroup {

            SettingRowDestructive(
                title = tr("Apagar histórico"),
                subtext = tr("Remove todos os checks salvos neste dispositivo"),
                onClick = { showDeleteConfirmSheet = true }
            )
            }

            Spacer(modifier = Modifier.height(LagCheckSpacing.space4_5))

            // 3. Grupo: Sobre o Lagcheck
            SettingsSectionHeader(title = tr("SOBRE O LAGCHECK"))

            SettingsGroup {

            // Versão real do pacote instalado (antes era o texto fixo "1.0.0 (build 1)")
            val versionText = remember {
                runCatching {
                    val info = context.packageManager.getPackageInfo(context.packageName, 0)
                    "${info.versionName} (${info.longVersionCode})"
                }.getOrDefault("—")
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(text = tr("Versão"), fontSize = 14.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)
                Text(text = versionText, style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
            }

            SettingRow(
                title = tr("Verificar atualizações"),
                onClick = onCheckForUpdates
            )

            // Termos e "avaliar" no iOS atual só exibem um aviso; permanecem fora até haver destino real.
            SettingRow(
                title = tr("Política de Privacidade"),
                onClick = { openUrl(context, "https://lagcheck.signallq.com/privacy/") }
            )

            SettingRow(
                title = tr("Licenças de código aberto"),
                onClick = { showLicensesSheet = true }
            )

            if (privacyOptionsRequired) {
                SettingRow(
                    title = tr("Opções de privacidade"),
                    onClick = onOpenPrivacyOptions
                )
            }
            if (analyticsCollectionAvailable) {
                Row(
                    modifier = Modifier.fillMaxWidth().height(72.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(tr("Compartilhar dados de uso"), fontSize = 14.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)
                        Text(tr("Ajuda a melhorar o app. Não envia dados da sua rede."), fontSize = 12.sp, color = LagCheckColors.TextMuted)
                    }
                    Switch(
                        checked = analyticsCollectionEnabled,
                        onCheckedChange = onAnalyticsCollectionEnabledChanged,
                        modifier = Modifier.size(width = 52.dp, height = 44.dp)
                    )
                }
            }
            }

            Spacer(modifier = Modifier.height(LagCheckSpacing.space4_5))

            // 4. Grupo: Suporte
            SettingsSectionHeader(title = tr("SUPORTE"))

            SettingsGroup {

            SettingRow(
                title = tr("Suporte"),
                onClick = { openUrl(context, "https://lagcheck.signallq.com/support/") }
            )

            SettingRow(
                title = tr("Enviar feedback"),
                onClick = {
                    val emailIntent = Intent(Intent.ACTION_SENDTO).apply {
                        data = Uri.parse("mailto:suporte@signallq.com?subject=Feedback%20LagCheck%20Android")
                    }
                    try {
                        context.startActivity(emailIntent)
                    } catch (e: Exception) {
                        Toast.makeText(context, "suporte@signallq.com", Toast.LENGTH_LONG).show()
                    }
                }
            )
            }

            Spacer(modifier = Modifier.height(48.dp))
        }

        if (showLicensesSheet) {
            val licenseText = remember(context) {
                runCatching {
                    context.assets.open("licenses/google-sans-flex-OFL.txt").bufferedReader().use { it.readText() }
                }.getOrDefault("—")
            }
            ModalBottomSheet(
                onDismissRequest = { showLicensesSheet = false },
                containerColor = LagCheckColors.Surface
            ) {
                Column(modifier = Modifier.fillMaxWidth().padding(horizontal = LagCheckSpacing.space6).padding(bottom = LagCheckSpacing.space6)) {
                    Text(
                        text = tr("Licenças de código aberto"),
                        style = LagCheckTypography.SectionHeader,
                        color = LagCheckColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space4))
                    Text(
                        text = licenseText,
                        style = LagCheckTypography.Subtext,
                        color = LagCheckColors.TextSecondary,
                        modifier = Modifier.fillMaxWidth().height(360.dp).verticalScroll(rememberScrollState())
                    )
                }
            }
        }

        // Sheet Seletor de Ícone do app (Decisão 83)
        if (showIconSheet) {
            ModalBottomSheet(
                onDismissRequest = { showIconSheet = false },
                sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
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
                Column(modifier = Modifier.fillMaxWidth().padding(horizontal = LagCheckSpacing.space6).padding(bottom = LagCheckSpacing.space8)) {
                    Text(tr("Ícone do app"), style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp), color = LagCheckColors.TextPrimary)
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space1_5))
                    Text(tr("O launcher atualiza em alguns segundos."), fontSize = 12.sp, color = LagCheckColors.TextMuted)
                    Spacer(modifier = Modifier.height(LagCheckSpacing.space3))
                    com.lagcheck.android.data.AppIcon.entries.forEach { icon ->
                        val selected = icon == currentIcon
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(72.dp)
                                .rowDivider()
                                .clickable {
                                    com.lagcheck.android.data.AppIconManager.set(context, icon)
                                    currentIcon = icon
                                    showIconSheet = false
                                },
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            IconPreview(icon)
                            Spacer(modifier = Modifier.width(LagCheckSpacing.space3_5))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(tr(icon.title), fontSize = 15.sp, fontWeight = FontWeight.Bold, color = if (selected) LagCheckColors.AccentPrimary else LagCheckColors.TextPrimary)
                                Spacer(modifier = Modifier.height(LagCheckSpacing.space1))
                                Text(tr(icon.subtitle), fontSize = 12.sp, color = LagCheckColors.TextMuted)
                            }
                            if (selected) Text("✓", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.AccentPrimary)
                        }
                    }
                }
            }
        }

        // Sheet Seletor de Idioma
        if (showLanguageSheet) {
            val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

            ModalBottomSheet(
                onDismissRequest = { showLanguageSheet = false },
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
                        text = tr("Idioma"),
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                        color = LagCheckColors.TextPrimary
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space4))

                    listOf("Português (Brasil)", "English", "Español").forEach { lang ->
                        val isSelected = currentLanguage == lang
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(48.dp)
                                .rowDivider()
                                .clickable {
                                    onLanguageSelected(lang)
                                    showLanguageSheet = false
                                },
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = lang,
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
            }
        }


        if (showRegionSheet) {
            val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

            ModalBottomSheet(
                onDismissRequest = { showRegionSheet = false },
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
                        .verticalScroll(rememberScrollState())
                ) {
                    Text(
                        text = tr("Região de referência"),
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                        color = LagCheckColors.TextPrimary
                    )

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space4))

                    val activeId = manualRegionId ?: "automatic"

                    regionCandidates.forEach { candidate ->
                        val isSelected = activeId == candidate.id
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(48.dp)
                                .rowDivider()
                                .clickable {
                                    onRegionSelected(if (candidate.id == "automatic") null else candidate.id)
                                    showRegionSheet = false
                                },
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = candidate.label,
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
            }
        }
        // Sheet de Confirmação para Apagar Todo o Histórico
        if (showDeleteConfirmSheet) {
            val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

            ModalBottomSheet(
                onDismissRequest = { showDeleteConfirmSheet = false },
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

                    Spacer(modifier = Modifier.height(LagCheckSpacing.space4_5))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space2)
                    ) {
                        // Cancelar
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(52.dp)
                                .clip(RoundedCornerShape(percent = 50))
                                .border(1.dp, LagCheckColors.Border, RoundedCornerShape(percent = 50))
                                .clickable { showDeleteConfirmSheet = false },
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
                                    showDeleteConfirmSheet = false
                                    onClearHistory()
                                    Toast.makeText(context, tr("Histórico apagado com sucesso"), Toast.LENGTH_SHORT).show()
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
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        style = LagCheckTypography.MonoSmall,
        color = LagCheckColors.TextMuted,
        modifier = Modifier.padding(bottom = LagCheckSpacing.space2_5)
    )
}

/** Grupo de linhas dentro de um cartão Surface com raio 26 (protótipo Android). */
@Composable
private fun SettingsGroup(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(LagCheckRadius.xl))
            .background(LagCheckColors.Surface)
            .padding(horizontal = LagCheckSpacing.space5)
    ) { content() }
}

@Composable
private fun SettingRow(
    title: String,
    value: String? = null,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .clickable { onClick() },
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)

        Row(verticalAlignment = Alignment.CenterVertically) {
            if (value != null) {
                Text(text = value, style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
                Spacer(modifier = Modifier.padding(horizontal = LagCheckSpacing.space1))
            }
            Text(text = "›", fontSize = 20.sp, color = LagCheckColors.TextMuted)
        }
    }
}

@Composable
private fun SettingRowDestructive(
    title: String,
    subtext: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(64.dp)
            .clickable { onClick() },
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(text = title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.CoralWarning)
            Spacer(modifier = Modifier.height(LagCheckSpacing.space1))
            Text(text = subtext, fontSize = 12.sp, color = LagCheckColors.TextMuted)
        }

        Text(text = "›", fontSize = 20.sp, color = LagCheckColors.TextMuted)
    }
}

/** Abre um link no navegador. Sem navegador disponível, não faz nada (nunca derruba o app). */
private fun openUrl(context: android.content.Context, url: String) {
    runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
}

/** Miniatura redonda do ícone: o Clássico mostra as camadas reais do ícone adaptativo; o mascote, sobre o brilho roxo. */
@Composable
private fun IconPreview(icon: com.lagcheck.android.data.AppIcon) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(androidx.compose.foundation.shape.CircleShape)
            .background(
                if (icon.foreground == null) androidx.compose.ui.graphics.Brush.linearGradient(listOf(LagCheckColors.Background, LagCheckColors.Background))
                else androidx.compose.ui.graphics.Brush.radialGradient(
                    0f to LagCheckBrandColors.AppIconViolet,
                    1f to LagCheckColors.Background
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        if (icon.foreground == null) {
            // Camadas de 108 dp recortadas pela área visível de 72 dp, como o launcher faz.
            androidx.compose.foundation.Image(
                painter = androidx.compose.ui.res.painterResource(com.lagcheck.android.R.mipmap.ic_launcher_background),
                contentDescription = null,
                modifier = Modifier.requiredSize(72.dp)
            )
            androidx.compose.foundation.Image(
                painter = androidx.compose.ui.res.painterResource(com.lagcheck.android.R.mipmap.ic_launcher_foreground),
                contentDescription = null,
                modifier = Modifier.requiredSize(72.dp)
            )
        } else {
            androidx.compose.foundation.Image(
                painter = androidx.compose.ui.res.painterResource(icon.foreground),
                contentDescription = null,
                modifier = Modifier.size(62.dp)
            )
        }
    }
}
