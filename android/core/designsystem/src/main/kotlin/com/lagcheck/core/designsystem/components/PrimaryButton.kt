package com.lagcheck.core.designsystem.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography

/**
 * Botão de Ação Primária Oficial do Lagcheck (Open Design / Brand Spec / Decisões 51 e 66).
 * Altura de 62dp (ou custom), cantos arredondados de 17dp, fundo Roxo Gamer (#7C3AED), texto em negrito 17sp.
 */
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    height: Dp = 62.dp,
    containerColor: Color = LagCheckColors.AccentPrimary,
    contentColor: Color = LagCheckColors.TextPrimary,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .height(height),
        shape = RoundedCornerShape(17.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = containerColor,
            contentColor = contentColor,
            disabledContainerColor = LagCheckColors.Surface,
            disabledContentColor = LagCheckColors.TextMuted
        )
    ) {
        Text(
            text = text,
            style = LagCheckTypography.CtaPrimary
        )
    }
}
