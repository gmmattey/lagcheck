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
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography

/**
 * 07 · Ajustes.
 * Paridade 1:1 estrita com o protótipo de alta fidelidade Open Design (Screen 07 · Ajustes).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    currentLanguage: String,
    onLanguageSelected: (String) -> Unit,
    onClearHistory: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var showLanguageSheet by remember { mutableStateOf(false) }
    var showDeleteConfirmSheet by remember { mutableStateOf(false) }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 22.dp)
                .verticalScroll(rememberScrollState())
        ) {
            // Header Canônico: Voltar '‹' + Ajustes
            SecondaryScreenHeader(
                title = "Ajustes",
                onBack = onBack
            )

            // 1. Grupo: Preferências
            SettingsSectionHeader(title = "PREFERÊNCIAS")

            SettingRow(
                title = "Idioma",
                value = currentLanguage,
                onClick = { showLanguageSheet = true }
            )

            Spacer(modifier = Modifier.height(26.dp))

            // 2. Grupo: Histórico
            SettingsSectionHeader(title = "HISTÓRICO")

            SettingRowDestructive(
                title = "Apagar histórico",
                subtext = "Remove todos os checks salvos neste dispositivo",
                onClick = { showDeleteConfirmSheet = true }
            )

            Spacer(modifier = Modifier.height(26.dp))

            // 3. Grupo: Sobre o Lagcheck
            SettingsSectionHeader(title = "SOBRE O LAGCHECK")

            // Versão
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .border(width = 0.5.dp, color = LagCheckColors.Border.copy(alpha = 0.5f)),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(text = "Versão", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.TextPrimary)
                Text(text = "1.0.0 (build 1)", style = LagCheckTypography.MonoSmall, color = LagCheckColors.TextMuted)
            }

            SettingRow(
                title = "Termos de Uso",
                onClick = {
                    Toast.makeText(context, "Termos de uso do Lagcheck", Toast.LENGTH_SHORT).show()
                }
            )

            SettingRow(
                title = "Política de Privacidade",
                onClick = {
                    Toast.makeText(context, "Política de privacidade sem rastreamento de IP/PII", Toast.LENGTH_SHORT).show()
                }
            )

            SettingRow(
                title = "Licenças de código aberto",
                onClick = {
                    Toast.makeText(context, "Licenças: Kotlin, Coroutines, Jetpack Compose", Toast.LENGTH_SHORT).show()
                }
            )

            Spacer(modifier = Modifier.height(26.dp))

            // 4. Grupo: Suporte
            SettingsSectionHeader(title = "SUPORTE")

            SettingRow(
                title = "Enviar feedback",
                onClick = {
                    val emailIntent = Intent(Intent.ACTION_SENDTO).apply {
                        data = Uri.parse("mailto:suporte@lagcheck.com?subject=Feedback%20Lagcheck%20Android")
                    }
                    try {
                        context.startActivity(emailIntent)
                    } catch (e: Exception) {
                        Toast.makeText(context, "suporte@lagcheck.com", Toast.LENGTH_LONG).show()
                    }
                }
            )

            SettingRow(
                title = "Avaliar o Lagcheck",
                onClick = {
                    Toast.makeText(context, "Obrigado por apoiar o Lagcheck!", Toast.LENGTH_SHORT).show()
                }
            )

            Spacer(modifier = Modifier.height(48.dp))
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
                        .padding(horizontal = 22.dp)
                        .padding(bottom = 32.dp)
                ) {
                    Text(
                        text = "Idioma",
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
                                .border(width = 0.5.dp, color = LagCheckColors.Border.copy(alpha = 0.5f))
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
                                .clickable { showDeleteConfirmSheet = false },
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
                                    showDeleteConfirmSheet = false
                                    onClearHistory()
                                    Toast.makeText(context, "Histórico apagado com sucesso", Toast.LENGTH_SHORT).show()
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
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        style = LagCheckTypography.MonoSmall,
        color = LagCheckColors.TextMuted,
        modifier = Modifier.padding(bottom = 10.dp)
    )
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
            .clickable { onClick() }
            .border(width = 0.5.dp, color = LagCheckColors.Border.copy(alpha = 0.5f)),
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
            .clickable { onClick() }
            .border(width = 0.5.dp, color = LagCheckColors.Border.copy(alpha = 0.5f)),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(text = title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = LagCheckColors.CoralWarning)
            Spacer(modifier = Modifier.height(3.dp))
            Text(text = subtext, fontSize = 11.sp, color = LagCheckColors.TextMuted)
        }

        Text(text = "›", fontSize = 20.sp, color = LagCheckColors.TextMuted)
    }
}
