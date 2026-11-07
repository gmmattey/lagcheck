package com.lagcheck.desktop.ds

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable

/** Dark mode exclusivo. Material só fornece base de foco/seleção; todo visual vem dos tokens. */
@Composable
fun LagCheckTheme(content: @Composable () -> Unit) = MaterialTheme(
    colorScheme = darkColorScheme(
        primary = LcColor.Accent, onPrimary = LcColor.TextPrimary, background = LcColor.Background, onBackground = LcColor.TextPrimary,
        surface = LcColor.Surface, onSurface = LcColor.TextPrimary, error = LcColor.Coral
    ),
    typography = Typography(
        bodyLarge = LcType.Body,
        bodyMedium = LcType.Body,
        titleLarge = LcType.PageTitle,
        labelLarge = LcType.Button,
    ),
    content = content
)
