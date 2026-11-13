package com.lagcheck.desktop.library.model

/**
 * O que as lojas publicam sobre um jogo (descrição, estúdio, lançamento, gêneros e modos de jogo).
 * Só entra o que a fonte devolveu: nada é estimado nem inventado. Campo ausente fica nulo/vazio.
 */
data class GameInfo(
    val description: String? = null,
    val developer: String? = null,
    val publisher: String? = null,
    /** Data como a fonte publicou (ISO `2012-07-28` na Microsoft, texto localizado na Steam). */
    val releaseDate: String? = null,
    val genres: List<String> = emptyList(),
    /** Chaves estáveis de [GameModes]; a interface traduz para texto. */
    val modes: List<String> = emptyList(),
    /** `false` quando a loja classifica o item como software/ferramenta e não como jogo; `null` quando não se sabe. */
    val isGame: Boolean? = null,
) {
    val isEmpty: Boolean
        get() = description == null && developer == null && publisher == null && releaseDate == null && genres.isEmpty() && modes.isEmpty() && isGame == null

    /** `true` quando alguma fonte declarou jogo com componente online. */
    val isOnline: Boolean get() = modes.any { it in GameModes.ONLINE }
}

object GameModes {
    const val SINGLEPLAYER = "singleplayer"
    const val MULTIPLAYER = "multiplayer"
    const val ONLINE_MULTIPLAYER = "online_multiplayer"
    const val COOP = "coop"
    const val ONLINE_COOP = "online_coop"
    const val MMO = "mmo"
    const val CROSSPLAY = "crossplay"

    val ONLINE = setOf(ONLINE_MULTIPLAYER, ONLINE_COOP, MMO, CROSSPLAY)
}
