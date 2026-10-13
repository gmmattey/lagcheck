package com.lagcheck.android.share

import android.content.Context
import android.graphics.Bitmap
import com.lagcheck.domain.presentation.ReadinessLanguage

/** Imagens dos cards e do vídeo. A arte é a autoral local do jogo; sem ela, o fundo é liso. */
internal class ShareMediaImages(val art: Bitmap?, val wordmark: Bitmap?, val badge: Bitmap?, val tiles: List<Bitmap?>) {
    companion object {
        const val STORE_URL = "https://play.google.com/store/apps/details?id=com.buildea.lagcheck"

        /** Artes da grade da primeira cena do vídeo (sem o jogo escolhido). */
        private val gridDrawables = listOf(
            "game_fortnite", "game_cs2", "game_free_fire", "game_league_of_legends", "game_roblox",
            "game_minecraft", "game_ea_fc", "game_apex_legends", "game_valorant"
        )

        fun badgeDrawable(language: ReadinessLanguage): String = when (language) {
            ReadinessLanguage.PT_BR -> "badge_google_play_pt"
            ReadinessLanguage.ES -> "badge_google_play_es"
            ReadinessLanguage.EN -> "badge_google_play_en"
        }

        fun load(context: Context, scene: ShareMediaScene, language: ReadinessLanguage, withTiles: Boolean): ShareMediaImages {
            ShareCanvas.init(context)
            val tiles = if (withTiles) gridDrawables.filter { it != scene.artDrawableName }.take(8).map { ShareCanvas.decode(context, it) } else emptyList()
            return ShareMediaImages(
                art = scene.artDrawableName.takeIf { it.isNotEmpty() }?.let { ShareCanvas.decode(context, it) },
                wordmark = ShareCanvas.decode(context, "lagcheck_wordmark_official"),
                badge = ShareCanvas.decode(context, badgeDrawable(language)),
                tiles = tiles
            )
        }
    }
}
