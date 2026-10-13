package com.lagcheck.android.ui.settings

import android.content.Intent
import android.net.Uri
import android.widget.Toast
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.ui.components.SecondaryScreenHeader
import com.lagcheck.core.designsystem.components.rowDivider
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.android.ui.tr
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
    onBack: () -> Unit,
    /** Só quando o UMP exigir (anúncios ligados). */
    privacyOptionsRequired: Boolean = false,
    onOpenPrivacyOptions: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var showLanguageSheet by remember { mutableStateOf(false) }
    var showIconSheet by remember { mutableStateOf(false) }
    var currentIcon by remember { mutableStateOf(com.lagcheck.android.data.AppIconManager.current(context)) }
    var showDeleteConfirmSheet by remember { mutableStateOf(false) }
    var showRegionSheet by remember { mutableStateOf(false) }
    var showLicensesSheet by remember { mutableStateOf(false) }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp)
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
            }

            Spacer(modifier = Modifier.height(18.dp))

            // 2. Grupo: Histórico
            SettingsSectionHeader(title = tr("HISTÓRICO"))

            SettingsGroup {

            SettingRowDestructive(
                title = tr("Apagar histórico"),
                subtext = tr("Remove todos os checks salvos neste dispositivo"),
                onClick = { showDeleteConfirmSheet = true }
            )
            }

            Spacer(modifier = Modifier.height(18.dp))

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
            }

            Spacer(modifier = Modifier.height(18.dp))

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
                Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 24.dp)) {
                    Text(
                        text = tr("Licenças de código aberto"),
                        style = LagCheckTypography.SectionHeader,
                        color = LagCheckColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
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
                            .padding(top = 10.dp, bottom = 18.dp)
                            .size(width = 35.dp, height = 4.dp)
                            .clip(RoundedCornerShape(9.dp))
                            .background(LagCheckColors.Border)
                    )
                }
            ) {
                Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 32.dp)) {
                    Text(tr("Ícone do app"), style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp), color = LagCheckColors.TextPrimary)
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(tr("O launcher atualiza em alguns segundos."), fontSize = 12.sp, color = LagCheckColors.TextMuted)
                    Spacer(modifier = Modifier.height(12.dp))
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
                            Spacer(modifier = Modifier.width(14.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(tr(icon.title), fontSize = 15.sp, fontWeight = FontWeight.Bold, color = if (selected) LagCheckColors.AccentPrimary else LagCheckColors.TextPrimary)
                                Spacer(modifier = Modifier.height(3.dp))
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
                        .padding(horizontal = 24.dp)
                        .padding(bottom = 32.dp)
                ) {
                    Text(
                        text = tr("Idioma"),
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                        color = LagCheckColors.TextPrimary
                    )

                    Spacer(modifier = Modifier.height(16.dp))

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
                        .padding(horizontal = 24.dp)
                        .padding(bottom = 32.dp)
                        .verticalScroll(rememberScrollState())
                ) {
                    Text(
                        text = tr("Região de referência"),
                        style = LagCheckTypography.SectionHeader.copy(fontSize = 24.sp),
                        color = LagCheckColors.TextPrimary
                    )

                    Spacer(modifier = Modifier.height(16.dp))

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
                        .padding(horizontal = 24.dp)
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

                    Spacer(modifier = Modifier.height(18.dp))

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
        modifier = Modifier.padding(bottom = 10.dp)
    )
}

/** Grupo de linhas dentro de um cartão Surface com raio 26 (protótipo Android). */
@Composable
private fun SettingsGroup(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(26.dp))
            .background(LagCheckColors.Surface)
            .padding(horizontal = 20.dp)
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
                Spacer(modifier = Modifier.padding(horizontal = 4.dp))
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
            Spacer(modifier = Modifier.height(3.dp))
            Text(text = subtext, fontSize = 12.sp, color = LagCheckColors.TextMuted)
        }

        Text(text = "›", fontSize = 20.sp, color = LagCheckColors.TextMuted)
    }
}

/** Abre um link no navegador. Sem navegador disponível, não faz nada (nunca derruba o app). */
private fun openUrl(context: android.content.Context, url: String) {
    runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
}

/** Miniatura redonda do ícone: glifo roxo sobre o fundo escuro, ou mascote sobre o brilho roxo. */
@Composable
private fun IconPreview(icon: com.lagcheck.android.data.AppIcon) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(androidx.compose.foundation.shape.CircleShape)
            .background(
                if (icon.foreground == null) androidx.compose.ui.graphics.Brush.linearGradient(listOf(LagCheckColors.Background, LagCheckColors.Background))
                else androidx.compose.ui.graphics.Brush.radialGradient(
                    0f to androidx.compose.ui.graphics.Color(0xFF3B2A78),
                    1f to LagCheckColors.Background
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        androidx.compose.foundation.Image(
            painter = androidx.compose.ui.res.painterResource(icon.foreground ?: com.lagcheck.android.R.mipmap.ic_launcher_foreground),
            contentDescription = null,
            modifier = Modifier.size(if (icon.foreground == null) 48.dp else 62.dp)
        )
    }
}
