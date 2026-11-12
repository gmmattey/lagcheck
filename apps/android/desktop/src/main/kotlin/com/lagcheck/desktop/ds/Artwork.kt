package com.lagcheck.desktop.ds

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.toComposeImageBitmap
import androidx.compose.ui.layout.ContentScale
import org.jetbrains.skia.Image

/**
 * Assets aprovados do Android, embalados no classpath desktop pelo Gradle.
 * Sem fetch remoto: quando a arte local não existir, a superfície fica neutra.
 */
@Composable
fun ApprovedArtwork(resourceName: String?, contentDescription: String?, modifier: Modifier = Modifier) {
    val image = remember(resourceName) { resourceName?.let(::loadApprovedImage) }
    if (image == null) Box(modifier.background(LcColor.Panel))
    else Image(image, contentDescription, modifier, contentScale = ContentScale.Crop)
}

@Composable
fun OfficialWordmark(modifier: Modifier = Modifier) {
    val image = remember { loadApprovedImage("wordmark_primary.png") }
    if (image != null) Image(image, "lagcheck", modifier, contentScale = ContentScale.Fit)
}

private fun loadApprovedImage(resourceName: String): ImageBitmap? = sequenceOf(resourceName, "$resourceName.png", "$resourceName.jpg")
    .mapNotNull { candidate ->
        runCatching {
            ArtworkAnchor::class.java.getResourceAsStream("/$candidate")?.use { input ->
                Image.makeFromEncoded(input.readBytes()).toComposeImageBitmap()
            }
        }.getOrNull()
    }
    .firstOrNull()

private object ArtworkAnchor
