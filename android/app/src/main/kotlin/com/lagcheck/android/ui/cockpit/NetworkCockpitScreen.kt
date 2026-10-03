package com.lagcheck.android.ui.cockpit

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.core.content.FileProvider
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.core.designsystem.components.WifiIcon
import com.lagcheck.android.data.NetworkReportPdfExporter
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.domain.presentation.UiStrings
import com.lagcheck.session.CockpitPresenter
import com.lagcheck.session.CockpitRow as CockpitDataRow
import com.lagcheck.session.LocalNetworkReport

/**
 * Cockpit de Rede ("Dados da Rede do Jogador" — Decisões 56 e 67).
 * Mostra só o que foi medido agora no aparelho: rádio (frequência, RSSI, link), gateway, NAT e voz.
 * Campo sem leitura aparece como "—". O protótipo anterior exibia NAT, CGNAT, UPnP e voz que ninguém tinha medido.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NetworkCockpitScreen(
    radioSnapshot: RadioTelemetrySnapshot?,
    report: LocalNetworkReport?,
    isProbing: Boolean,
    language: ReadinessLanguage,
    onClose: () -> Unit,
    onRefresh: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var selectedUseCase by remember { mutableStateOf<CockpitDataRow?>(null) }
    fun tr(pt: String) = UiStrings.translate(pt, language)

    val isWiFi = radioSnapshot?.transportType == RadioTelemetrySnapshot.TransportType.WIFI
    val sections = CockpitPresenter.sections(radioSnapshot, report, language)
    val connKindText = sections.first().rows.first().value

    fun copyData() {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("LagCheck Network", CockpitPresenter.shareText(radioSnapshot, report, language)))
        Toast.makeText(context, tr("Dados da rede copiados!"), Toast.LENGTH_SHORT).show()
    }

    fun exportReport() {
        if (isProbing) return
        val file = NetworkReportPdfExporter.export(context, tr("Dados da Rede"), sections)
        if (file == null) {
            Toast.makeText(context, tr("Não deu para gerar o relatório."), Toast.LENGTH_SHORT).show()
            return
        }
        val shared = runCatching {
            val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                putExtra(Intent.EXTRA_SUBJECT, tr("LagCheck - Dados da Rede"))
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(Intent.createChooser(shareIntent, tr("Exportar Relatório")))
        }.isSuccess
        if (!shared) Toast.makeText(context, tr("Não deu para gerar o relatório."), Toast.LENGTH_SHORT).show()
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
            .padding(horizontal = 22.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // 1. Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .padding(top = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .clickable { onClose() }
                    .defaultMinSize(minWidth = 44.dp, minHeight = 44.dp)
                    .padding(horizontal = 7.dp, vertical = 6.dp)
            ) {
                Text(text = tr("Fechar"), fontSize = 14.sp, color = LagCheckColors.TextMuted)
            }

            Text(
                text = tr("Dados da Rede"),
                style = LagCheckTypography.PageTitle.copy(fontSize = 18.sp),
                color = LagCheckColors.TextPrimary
            )

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .clickable(enabled = !isProbing) { exportReport() }
                    .defaultMinSize(minWidth = 44.dp, minHeight = 44.dp)
                    .padding(horizontal = 7.dp, vertical = 6.dp)
            ) {
                Text(text = tr("PDF"), fontSize = 14.sp, color = if (isProbing) LagCheckColors.TextMuted else LagCheckColors.AccentPrimary)
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // 2. Summary Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(if (isWiFi) LagCheckColors.Good else LagCheckColors.AccentPrimary)
                )
                Text(
                    text = connKindText,
                    style = LagCheckTypography.SectionHeader.copy(fontSize = 18.sp),
                    color = LagCheckColors.TextPrimary
                )
            }

            if (isProbing) {
                Text(
                    text = tr("Medindo…"),
                    fontSize = 12.sp,
                    color = LagCheckColors.TextMuted
                )
            } else {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(LagCheckColors.AccentPrimary.copy(alpha = 0.1f))
                        .clickable { onRefresh() }
                        .defaultMinSize(minWidth = 44.dp, minHeight = 44.dp)
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = tr("Atualizar"),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = LagCheckColors.AccentPrimary
                    )
                }
            }
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = tr("Medido agora no aparelho. O que não foi medido aparece como —."),
            style = LagCheckTypography.Subtext,
            color = LagCheckColors.TextMuted
        )

        Spacer(modifier = Modifier.height(24.dp))

        // 3. Seções geradas só com o que foi observado
        sections.forEachIndexed { index, section ->
            if (index > 0) Spacer(modifier = Modifier.height(20.dp))
            SectionCard(title = section.title) {
                section.rows.forEach { row ->
                    if (index == 2) {
                        UseCaseRow(row = row, enabled = !isProbing, onClick = { selectedUseCase = row })
                    } else {
                        CockpitRow(label = row.label, value = row.value)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(28.dp))

        // 6. Ações: Copiar dados
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .clip(RoundedCornerShape(16.dp))
                .border(1.dp, LagCheckColors.BorderStrong, RoundedCornerShape(16.dp))
                .clickable { copyData() },
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = tr("Copiar dados da rede"),
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                color = LagCheckColors.TextPrimary
            )
        }

        Spacer(modifier = Modifier.height(32.dp))
    }

    selectedUseCase?.let { row ->
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
        ModalBottomSheet(
            onDismissRequest = { selectedUseCase = null },
            sheetState = sheetState,
            containerColor = LagCheckColors.Surface
        ) {
            Column(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 22.dp).padding(bottom = 32.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(row.label, style = LagCheckTypography.SectionHeader, color = LagCheckColors.TextPrimary)
                Text(
                    text = if (row.value == tr("Não avaliado"))
                        tr("Ainda não há uma combinação suficiente de leituras locais para avaliar este caso.")
                    else row.value,
                    style = LagCheckTypography.BodyMedium,
                    color = LagCheckColors.TextSecondary
                )
                Text(
                    text = tr("Esta leitura avalia condições locais observadas no Android. Ela não mede a rota até um serviço, servidor ou partida."),
                    style = LagCheckTypography.Subtext,
                    color = LagCheckColors.TextTertiary
                )
            }
        }
    }
}

@Composable
private fun UseCaseRow(row: CockpitDataRow, enabled: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().defaultMinSize(minHeight = 44.dp).clickable(enabled = enabled, onClick = onClick),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(row.label, style = LagCheckTypography.BodySemibold, color = LagCheckColors.TextPrimary)
        Text("›", fontSize = 20.sp, color = LagCheckColors.TextTertiary)
    }
}

@Composable
private fun SectionCard(
    title: String,
    content: @Composable () -> Unit
) {
    Column {
        Text(
            text = title,
            style = LagCheckTypography.MonoSmall,
            color = LagCheckColors.TextMuted
        )
        Spacer(modifier = Modifier.height(8.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(15.dp))
                .background(LagCheckColors.Surface)
                .border(1.dp, LagCheckColors.BorderStrong, RoundedCornerShape(15.dp))
                .padding(horizontal = 16.dp, vertical = 14.dp)
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                content()
            }
        }
    }
}

@Composable
private fun CockpitRow(
    label: String,
    value: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            fontSize = 13.sp,
            color = LagCheckColors.TextMuted,
            modifier = Modifier.weight(1f)
        )
        Text(
            text = value,
            style = LagCheckTypography.MonoData,
            fontWeight = FontWeight.SemiBold,
            color = LagCheckColors.TextPrimary
        )
    }
}
