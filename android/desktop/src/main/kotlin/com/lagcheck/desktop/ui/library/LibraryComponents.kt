package com.lagcheck.desktop.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.desktop.ds.*
import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame

@Composable
fun LibraryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isPrimary: Boolean = true,
    enabled: Boolean = true
) {
    val interaction = remember { MutableInteractionSource() }
    val hovered by interaction.collectIsHoveredAsState()
    val focused by interaction.collectIsFocusedAsState()

    val bg = when {
        !enabled -> LcColor.Panel
        isPrimary && hovered -> LcColor.AccentHover
        isPrimary -> LcColor.Accent
        hovered -> LcColor.HoverOverlay
        else -> Color.Transparent
    }

    val textColor = when {
        !enabled -> LcColor.TextTertiary
        isPrimary -> Color.White
        else -> LcColor.TextPrimary
    }

    val borderModifier = if (!isPrimary) {
        Modifier.border(1.dp, if (hovered) LcColor.BorderHover else LcColor.BorderStrong, RoundedCornerShape(LcRadius.r13))
    } else Modifier

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(LcRadius.r13))
            .background(bg)
            .then(borderModifier)
            .then(if (focused) Modifier.border(LcSize.focusRing, LcColor.AccentLight, RoundedCornerShape(LcRadius.r13)) else Modifier)
            .semantics { contentDescription = text }
            .clickable(interactionSource = interaction, indication = null, enabled = enabled, role = Role.Button, onClick = onClick)
            .padding(horizontal = 24.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text.uppercase(),
            style = LcType.Button.copy(fontWeight = FontWeight.ExtraBold),
            color = textColor,
            letterSpacing = 1.2.sp
        )
    }
}

@Composable
fun PlatformBadge(platform: GamePlatform) {
    val (label, bg, color) = when (platform) {
        GamePlatform.STEAM -> Triple("STEAM", Color(0xFF171A21), Color(0xFF66C0F4))
        GamePlatform.EPIC_GAMES -> Triple("EPIC GAMES", Color(0xFF202020), Color(0xFFF4F5F7))
        GamePlatform.XBOX -> Triple("XBOX / PC", Color(0xFF107C10), Color.White)
        GamePlatform.MANUAL -> Triple("LOCAL", Color(0xFF262B34), LcColor.TextSecondary)
    }

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(LcRadius.r8))
            .background(bg)
            .border(1.dp, LcColor.BorderHairline, RoundedCornerShape(LcRadius.r8))
            .padding(horizontal = 8.dp, vertical = 3.dp)
    ) {
        Text(
            text = label,
            style = LcType.Section.copy(fontSize = 10.sp, letterSpacing = 0.8.sp),
            color = color
        )
    }
}

@Composable
fun NetworkBadge(support: GameNetworkSupport) {
    val (text, color, bg) = when (support) {
        is GameNetworkSupport.LagcheckSupported -> Triple("DIAGNÓSTICO HOMOLOGADO", LcColor.Good, Color(0x1F22C55E))
        is GameNetworkSupport.GeneralConnectionOnly -> Triple("CONEXÃO GERAL", LcColor.AccentLight, Color(0x1F7C3AED))
        is GameNetworkSupport.OfflineSingleplayer -> Triple("JOGO OFFLINE / SOLO", LcColor.TextTertiary, Color(0x1AFFFFFF))
    }

    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(LcRadius.pill))
            .background(bg)
            .border(1.dp, color.copy(alpha = 0.3f), RoundedCornerShape(LcRadius.pill))
            .padding(horizontal = 10.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            Modifier
                .size(6.dp)
                .clip(CircleShape)
                .background(color)
        )
        Spacer(Modifier.width(6.dp))
        Text(
            text = text,
            style = LcType.Section.copy(fontSize = 10.sp, letterSpacing = 0.8.sp),
            color = color
        )
    }
}
