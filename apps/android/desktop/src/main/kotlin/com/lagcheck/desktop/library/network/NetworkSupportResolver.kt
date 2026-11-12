package com.lagcheck.desktop.library.network

import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.PcGame

/** Jogo que o catálogo local deixa medir a partir de um PC. */
data class CatalogGame(val id: String, val name: String)

/**
 * Decide que tipo de diagnóstico um jogo recebe. Nada é adivinhado por trecho de título:
 * ou o jogo casa de forma exata com o catálogo (por id de loja conhecido ou por nome), ou recebe só o diagnóstico geral.
 *
 * - Casou com o catálogo e o catálogo mede em PC: [GameNetworkSupport.LagcheckSupported].
 * - Está na lista de jogos solo verificados: [GameNetworkSupport.OfflineSingleplayer].
 * - Qualquer outro: [GameNetworkSupport.GeneralConnectionOnly], que a interface rotula como conexão geral.
 */
class NetworkSupportResolver(
    private val catalog: () -> List<CatalogGame>,
    private val regionLabel: (String) -> String? = { null },
) {
    fun resolve(game: PcGame): GameNetworkSupport {
        val titleKey = TitleKey.of(game.title)
        if (titleKey in OFFLINE_TITLES) return GameNetworkSupport.OfflineSingleplayer("Jogo solo, sem servidor para medir")
        val games = catalog()
        val byId = STEAM_APP_TO_CATALOG[game.id]?.let { id -> games.firstOrNull { it.id == id } }
        val match = byId ?: games.firstOrNull { TitleKey.of(it.name) == titleKey }
        return if (match != null) {
            GameNetworkSupport.LagcheckSupported(match.id, regionLabel(match.id))
        } else {
            GameNetworkSupport.GeneralConnectionOnly("Só conexão geral")
        }
    }

    companion object {
        /** Tudo vira conexão geral: usado quando não há catálogo carregado. */
        val NONE = NetworkSupportResolver(catalog = { emptyList() })

        /**
         * Ids da Steam cujo nome na loja difere do nome do catálogo.
         * Só entram ids verificados; o restante casa pelo nome exato.
         */
        val STEAM_APP_TO_CATALOG: Map<String, String> = mapOf(
            "steam_730" to "cs2",
            "steam_570" to "dota2",
            "steam_1172470" to "apex-legends",
            "steam_1938090" to "warzone", // app "Call of Duty" da Steam, que traz o Warzone
            "steam_381210" to "dead-by-daylight",
            "steam_304390" to "for-honor",
            "steam_252490" to "rust",
            "steam_1361210" to "warhammer-darktide",
            "steam_1623730" to "palworld",
            "steam_359550" to "rainbow-six",
        )

        /** Jogos exclusivamente solo, verificados um a um. Não adicionar por suposição. */
        private val OFFLINE_TITLES: Set<String> = setOf("Cities: Skylines", "Cities: Skylines II").map(TitleKey::of).toSet()
    }
}

/** Normaliza título para comparação: sem símbolos, acentos de marca registrada, espaços ou caixa. */
object TitleKey {
    fun of(title: String): String = title.lowercase().filter { it.isLetterOrDigit() }
}
