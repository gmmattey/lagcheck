package com.lagcheck.android.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import com.lagcheck.android.data.RemoteArtworkRepository
import com.lagcheck.domain.model.CatalogGame

val LocalArtworkDownloadsAllowed = staticCompositionLocalOf { true }

@Composable
fun RemoteGameArtwork(game: CatalogGame, modifier: Modifier = Modifier) {
    val context = LocalContext.current.applicationContext
    val allowed = LocalArtworkDownloadsAllowed.current
    val image by produceState<ImageBitmap?>(null, game.artworkUrl, game.artworkRevision, allowed) {
        if (!allowed) return@produceState
        value = null
        value = RemoteArtworkRepository.load(context, game.artworkUrl, game.artworkRevision)?.asImageBitmap()
    }
    val local = context.resources.getIdentifier(game.drawableResName, "drawable", context.packageName)
    val remote = image
    when {
        remote != null -> Image(remote, game.name, modifier, contentScale = ContentScale.Crop)
        local != 0 -> Image(painterResource(local), game.name, modifier, contentScale = ContentScale.Crop)
        else -> Box(modifier)
    }
}
