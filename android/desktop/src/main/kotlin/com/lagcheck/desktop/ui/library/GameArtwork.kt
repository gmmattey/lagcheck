package com.lagcheck.desktop.ui.library

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.toComposeImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.lagcheck.desktop.ds.LcColor
import com.lagcheck.desktop.ds.LcType
import com.lagcheck.desktop.library.artwork.ArtworkResult
import com.lagcheck.desktop.library.artwork.ArtworkType
import com.lagcheck.desktop.library.artwork.GameArtworkResolver
import com.lagcheck.desktop.library.artwork.LruCache
import com.lagcheck.desktop.library.model.PcGame
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.nio.file.Files
import java.nio.file.Path
import org.jetbrains.skia.Image as SkiaImage

sealed interface ArtworkState {
    data object Loading : ArtworkState
    data class Loaded(val bitmap: ImageBitmap) : ArtworkState
    data object Missing : ArtworkState
}

/** Imagens já decodificadas, com teto de memória (~96 MB). Evita decodificar de novo ao rolar a grade. */
private val decodedCache = LruCache<String, ImageBitmap>(96L * 1024 * 1024) { it.width.toLong() * it.height * 4 }

private fun decode(path: Path): ImageBitmap? =
    runCatching { SkiaImage.makeFromEncoded(Files.readAllBytes(path)).toComposeImageBitmap() }.getOrNull()

/**
 * Carrega a imagem do jogo sem travar a tela: começa em [ArtworkState.Loading], vira [ArtworkState.Loaded]
 * ou [ArtworkState.Missing]. `generation` muda quando o usuário atualiza as imagens, para recarregar.
 */
@Composable
fun rememberArtwork(game: PcGame, type: ArtworkType, resolver: GameArtworkResolver, generation: Int): State<ArtworkState> =
    produceState<ArtworkState>(ArtworkState.Loading, game.id, type, resolver, generation) {
        val key = "${game.id}.${type.key}.$generation"
        val cached = decodedCache.get(key)
        if (cached != null) {
            value = ArtworkState.Loaded(cached)
            return@produceState
        }
        value = ArtworkState.Loading
        value = when (val result = resolver.resolve(game, type)) {
            is ArtworkResult.Available -> {
                val bitmap = withContext(Dispatchers.IO) { decode(result.path) }
                if (bitmap != null) {
                    decodedCache.put(key, bitmap)
                    ArtworkState.Loaded(bitmap)
                } else ArtworkState.Missing
            }
            ArtworkResult.Fallback -> ArtworkState.Missing
        }
    }

/** Imagem do jogo, com placeholder enquanto carrega e miniatura neutra com o nome quando não há imagem. */
@Composable
fun GameArtwork(
    game: PcGame,
    type: ArtworkType,
    resolver: GameArtworkResolver,
    generation: Int,
    modifier: Modifier = Modifier,
    alignment: Alignment = Alignment.Center,
) {
    val state by rememberArtwork(game, type, resolver, generation)
    when (val s = state) {
        is ArtworkState.Loaded -> Image(s.bitmap, game.title, modifier, alignment = alignment, contentScale = ContentScale.Crop)
        ArtworkState.Loading -> Box(modifier.background(LcColor.Panel))
        ArtworkState.Missing -> NeutralArtwork(game.title, modifier)
    }
}

/** Miniatura neutra do LagCheck: o nome do jogo sobre a superfície padrão. */
@Composable
fun NeutralArtwork(title: String, modifier: Modifier = Modifier) {
    Box(modifier.background(LcColor.Panel).padding(12.dp), contentAlignment = Alignment.Center) {
        Text(
            text = title,
            style = LcType.BodyStrong,
            color = LcColor.TextSecondary,
            textAlign = TextAlign.Center,
            maxLines = 4,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
