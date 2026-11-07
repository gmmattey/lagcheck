package com.lagcheck.desktop.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.unit.dp
import com.lagcheck.desktop.ds.*

@Composable
fun SearchField(value: String, onChange: (String) -> Unit, modifier: Modifier = Modifier) {
    val source = remember { MutableInteractionSource() }
    val focused by source.collectIsFocusedAsState()
    val shape = RoundedCornerShape(LcRadius.control)
    BasicTextField(
        value, onChange, modifier.width(260.dp).height(40.dp), singleLine = true, interactionSource = source,
        textStyle = LcType.Body.copy(color = LcColor.TextPrimary), cursorBrush = SolidColor(LcColor.AccentLight),
        decorationBox = { inner ->
            Row(Modifier.fillMaxSize().background(LcColor.Surface, shape)
                .border(if (focused) LcSize.focusRing else 1.dp, if (focused) LcColor.AccentLight else LcColor.BorderStrong, shape)
                .padding(horizontal = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("⌕", style = LcType.BodyStrong, color = LcColor.TextSecondary, modifier = Modifier.padding(end = 8.dp))
                Box(Modifier.weight(1f)) {
                    if (value.isEmpty()) Text("Buscar jogo", style = LcType.Body, color = LcColor.TextTertiary)
                    inner()
                }
            }
        }
    )
}
