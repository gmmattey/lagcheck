package com.lagcheck.desktop.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.lagcheck.desktop.ds.*
import com.lagcheck.desktop.library.artwork.ArtworkType
import com.lagcheck.desktop.library.artwork.GameArtworkResolver
import com.lagcheck.desktop.library.model.PcGame

@Composable
fun GameCard(
    game: PcGame,
    isSelected: Boolean,
    onClick: () -> Unit,
    onToggleFavorite: () -> Unit,
    artwork: GameArtworkResolver,
    artworkGeneration: Int,
    modifier: Modifier = Modifier
) {
    val interaction = remember { MutableInteractionSource() }
    val isHovered by interaction.collectIsHoveredAsState()

    val borderColor = when {
        isSelected -> LcColor.Accent
        isHovered -> LcColor.BorderHover
        else -> LcColor.BorderHairline
    }

    val bgColor = when {
        isSelected -> LcColor.Surface
        isHovered -> LcColor.Surface.copy(alpha = 0.8f)
        else -> LcColor.Panel
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(LcRadius.r13))
            .background(bgColor)
            .border(if (isSelected) 2.dp else 1.dp, borderColor, RoundedCornerShape(LcRadius.r13))
            .clickable(interactionSource = interaction, indication = null, onClick = onClick)
            .padding(12.dp)
    ) {
        Column(Modifier.fillMaxWidth()) {
            // Capa / Thumbnail
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(2f / 3f)
                    .clip(RoundedCornerShape(LcRadius.r8))
                    .background(Color(0xFF0F1115))
                    .border(1.dp, LcColor.BorderHairline, RoundedCornerShape(LcRadius.r8))
            ) {
                GameArtwork(game, ArtworkType.COVER, artwork, artworkGeneration, Modifier.fillMaxSize())

                // Indicador de favorito no canto superior
                if (game.isFavorite) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(6.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(Color(0xCC0B0D10))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text("★", color = LcColor.AccentLight, fontSize = 11.sp)
                    }
                }
            }

            Spacer(Modifier.height(10.dp))

            // Título
            Text(
                text = game.title,
                style = LcType.BodyStrong.copy(fontWeight = FontWeight.Bold),
                color = if (isSelected || isHovered) LcColor.TextPrimary else LcColor.TextSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(Modifier.height(6.dp))

            // Linha de Plataforma e Estado
            Row(
                Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                PlatformBadge(game.platform)

                Text(
                    text = if (game.isInstalled) "INSTALADO" else "NÃO INSTALADO",
                    style = LcType.Section.copy(fontSize = 10.sp),
                    color = if (game.isInstalled) LcColor.Good else LcColor.TextTertiary
                )
            }
        }
    }
}
