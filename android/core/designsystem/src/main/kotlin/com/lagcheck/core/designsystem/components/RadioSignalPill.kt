package com.lagcheck.core.designsystem.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography
import com.lagcheck.core.designsystem.theme.LagCheckRadius

/**
 * Pílula de telemetria ao vivo (.live-pill).
 * Ex: [●] Wi-Fi 5 GHz · 18 ms
 */
@Composable
fun RadioSignalPill(
    label: String,
    isWarning: Boolean = false,
    modifier: Modifier = Modifier
) {
    val dotColor = if (isWarning) LagCheckColors.CoralWarning else LagCheckColors.Good

    Row(
        modifier = modifier
            .height(28.dp)
            .clip(RoundedCornerShape(LagCheckRadius.pill))
            .border(1.dp, LagCheckColors.Border, RoundedCornerShape(LagCheckRadius.pill))
            .padding(horizontal = 9.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(6.dp)
                .clip(CircleShape)
                .background(dotColor)
        )
        Spacer(modifier = Modifier.width(7.dp))
        Text(
            text = label,
            style = LagCheckTypography.MonoSmall,
            color = LagCheckColors.TextMuted
        )
    }
}
