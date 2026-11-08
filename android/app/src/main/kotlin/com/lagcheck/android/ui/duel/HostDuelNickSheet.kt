package com.lagcheck.android.ui.duel

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.android.ui.tr
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius
import com.lagcheck.core.designsystem.theme.LagCheckSpacing

/**
 * Bottom Sheet para definir ou alterar o Nick Gamer local para o Duelo de Host (Decisão 112).
 * Salvo estritamente no dispositivo via PreferencesRepository — sem login, sem conta e sem servidor.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HostDuelNickSheet(
    initialNick: String,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    var nick by remember { mutableStateOf(initialNick) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    fun submit() {
        val trimmed = nick.trim().take(16)
        onConfirm(trimmed)
    }

    ModalBottomSheet(
        onDismissRequest = { onDismiss() },
        sheetState = sheetState,
        containerColor = LagCheckColors.Background,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(top = LagCheckSpacing.space2_5, bottom = LagCheckSpacing.space3)
                    .size(width = 36.dp, height = 4.dp)
                    .clip(RoundedCornerShape(LagCheckRadius.xs))
                    .background(LagCheckColors.Border)
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = LagCheckSpacing.space6)
                .padding(bottom = LagCheckSpacing.space9),
            verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space4)
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(LagCheckSpacing.space1_5)) {
                Text(
                    text = tr("SEU NICK NO LOBBY"),
                    style = LagCheckTypography.MonoSmall,
                    color = LagCheckColors.TextTertiary,
                    letterSpacing = 1.sp
                )
                Text(
                    text = tr("Como quer aparecer no duelo?"),
                    style = LagCheckTypography.SectionHeader.copy(fontSize = 22.sp),
                    color = LagCheckColors.TextPrimary
                )
                Text(
                    text = tr("Fica salvo só no seu aparelho. Sem conta, sem login."),
                    fontSize = 13.sp,
                    color = LagCheckColors.TextSecondary
                )
            }

            // Input com profundidade tonal de superfície (sem linhas de bordas)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
                    .clip(RoundedCornerShape(LagCheckRadius.md))
                    .background(LagCheckColors.Surface)
                    .padding(horizontal = LagCheckSpacing.space4),
                contentAlignment = Alignment.CenterStart
            ) {
                if (nick.isEmpty()) {
                    Text(
                        text = tr("Ex: Luiz, FalleN, Coringa"),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium,
                        color = LagCheckColors.TextTertiary
                    )
                }
                BasicTextField(
                    value = nick,
                    onValueChange = { if (it.length <= 16) nick = it },
                    singleLine = true,
                    textStyle = TextStyle(
                        color = LagCheckColors.TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    ),
                    cursorBrush = SolidColor(LagCheckColors.AccentPrimary),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = { submit() }),
                    modifier = Modifier.fillMaxWidth()
                )
            }

            Spacer(modifier = Modifier.height(LagCheckSpacing.space1))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(LagCheckSpacing.space3)
            ) {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(52.dp)
                        .clip(RoundedCornerShape(LagCheckRadius.md))
                        .background(LagCheckColors.Surface)
                        .clickable { onDismiss() },
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = tr("Cancelar"),
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = LagCheckColors.TextSecondary
                    )
                }

                PrimaryButton(
                    text = tr("Gerar Desafio"),
                    onClick = { submit() },
                    height = 52.dp,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}
