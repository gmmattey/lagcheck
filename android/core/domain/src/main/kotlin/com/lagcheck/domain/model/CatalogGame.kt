package com.lagcheck.domain.model

/**
 * Representação de jogo do catálogo do Lagcheck (Decisões 18, 31, 56 e 66).
 * Alinhado 1:1 com o protótipo de alta fidelidade Open Design.
 */
data class CatalogGame(
    val id: String,
    val name: String,
    val category: String,
    val platforms: List<String> = listOf("PC"),
    val primaryRegion: String = "São Paulo (sa-east-1)",
    val drawableResName: String,
    val artworkUrl: String? = null,
    val artworkRevision: String = ""
) {
    val platformsFormatted: String
        get() = platforms.joinToString(" · ")
}

/**
 * Prateleira de jogos exibida na UI, alinhada 1:1 com o catálogo v3 assinado (ids, nomes e plataformas).
 * Ela só dá apresentação (categoria e arte). Se um jogo é medível, quem decide é o catálogo verificado:
 * `MeasurementPlanner` resolve o destino e o teste de aderência garante que esta lista não se afasta do envelope.
 * "Mobile" é o contexto de celular do catálogo (publicado como `iphone`). Os dois jogos sem arte aprovada em
 * `res/drawable` (`drawableResName` vazio) caem no título tipográfico da UI, sem arte de terceiros (Decisão 18).
 */
object OfficialGameCatalog {
    /** A expansão da Decisão 89 já está no envelope Schema 3 assinado. */
    val pendingExpansion: List<CatalogGame> = emptyList()

    val games: List<CatalogGame> = listOf(
        CatalogGame("fortnite", "Fortnite", "Battle Royale", listOf("PlayStation", "Xbox", "PC", "Nintendo", "Mobile"), drawableResName = "game_fortnite"),
        CatalogGame("valorant", "VALORANT", "FPS Tático", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_valorant"),
        CatalogGame("warzone", "Call of Duty: Warzone", "Battle Royale", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_warzone"),
        CatalogGame("cs2", "Counter-Strike 2", "FPS Competitivo", listOf("PC"), drawableResName = "game_cs2"),
        CatalogGame("league-of-legends", "League of Legends", "MOBA", listOf("PC"), drawableResName = "game_league_of_legends"),
        CatalogGame("apex-legends", "Apex Legends", "Battle Royale", listOf("PlayStation", "Xbox", "PC", "Nintendo"), drawableResName = "game_apex_legends"),
        CatalogGame("rainbow-six", "Rainbow Six Siege", "FPS Tático", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_rainbow_six"),
        CatalogGame("rocket-league", "Rocket League", "Competitivo", listOf("PlayStation", "Xbox", "PC", "Nintendo"), drawableResName = "game_rocket_league"),
        CatalogGame("dota2", "Dota 2", "MOBA", listOf("PC"), drawableResName = "game_dota2"),
        CatalogGame("free-fire", "Free Fire", "Battle Royale Mobile", listOf("Mobile"), drawableResName = "game_free_fire"),
        CatalogGame("call-of-duty-mobile", "Call of Duty: Mobile", "FPS Mobile", listOf("Mobile"), drawableResName = "game_codm"),
        CatalogGame("brawl-stars", "Brawl Stars", "Ação Competitiva", listOf("Mobile"), drawableResName = "game_brawl_stars"),
        CatalogGame("blood-strike", "Blood Strike", "FPS Mobile", listOf("PC", "Mobile"), drawableResName = "game_blood_strike"),
        CatalogGame("pubg-mobile", "PUBG MOBILE", "Battle Royale Mobile", listOf("Mobile"), drawableResName = "game_pubg"),
        CatalogGame("wild-rift", "League of Legends: Wild Rift", "MOBA Mobile", listOf("Mobile"), drawableResName = "game_wild_rift"),
        CatalogGame("roblox", "Roblox", "Sandbox / Comunidade", listOf("PlayStation", "Xbox", "PC", "Mobile"), drawableResName = "game_roblox"),
        CatalogGame("minecraft", "Minecraft", "Sandbox", listOf("PlayStation", "Xbox", "PC", "Nintendo", "Mobile"), drawableResName = "game_minecraft"),
        CatalogGame("eafc", "EA Sports FC", "Esportes", listOf("PlayStation", "Xbox", "PC", "Nintendo", "Mobile"), drawableResName = "game_ea_fc"),
        CatalogGame("rust", "Rust", "Sobrevivência", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_rust"),
        CatalogGame("palworld", "Palworld", "Sobrevivência", listOf("Xbox", "PC"), drawableResName = "game_palworld"),
        CatalogGame("rainbow-six-mobile", "Rainbow Six Mobile", "FPS Tático Mobile", listOf("Mobile"), drawableResName = ""),
        CatalogGame("rocket-league-sideswipe", "Rocket League Sideswipe", "Competitivo Mobile", listOf("Mobile"), drawableResName = ""),
        CatalogGame("dead-by-daylight", "Dead by Daylight", "Sobrevivência / Terror", listOf("PlayStation", "Xbox", "PC", "Nintendo"), drawableResName = "game_dead_by_daylight"),
        CatalogGame("for-honor", "For Honor", "Combate Medieval", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_for_honor"),
        CatalogGame("borderlands-3", "Borderlands 3", "FPS / Cooperação", listOf("PlayStation", "Xbox", "PC", "Nintendo"), drawableResName = "game_borderlands_3"),
        CatalogGame("new-world", "New World: Aeternum", "MMORPG", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_new_world"),
        CatalogGame("squid-game-unleashed", "Squid Game: Unleashed", "Ação Competitiva", listOf("PlayStation", "Xbox", "PC", "Mobile"), drawableResName = "game_squid_game_unleashed"),
        CatalogGame("warhammer-darktide", "Warhammer 40,000: Darktide", "Cooperação", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_warhammer_darktide"),
        CatalogGame("marvel-snap", "MARVEL SNAP", "Cartas / Estratégia", listOf("PC", "Mobile"), drawableResName = "game_marvel_snap"),
        CatalogGame("the-outlast-trials", "The Outlast Trials", "Sobrevivência / Terror", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_the_outlast_trials"),
        CatalogGame("tribes-of-midgard", "Tribes of Midgard", "Ação / Cooperação", listOf("PlayStation", "Xbox", "PC", "Nintendo"), drawableResName = "game_tribes_of_midgard"),
        CatalogGame("crossfar", "Crossfar", "FPS Competitivo", listOf("PC"), drawableResName = "game_crossfar"),
        CatalogGame("lost-rift", "Lost Rift", "Sobrevivência", listOf("PC"), drawableResName = "game_lost_rift"),
        CatalogGame("star-wars-hunters", "Star Wars: Hunters", "Arena Competitiva", listOf("Nintendo", "Mobile"), drawableResName = "game_star_wars_hunters"),
        CatalogGame("rematch", "Rematch", "Esportes", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_rematch"),
        CatalogGame("predecessor", "Predecessor", "MOBA", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_predecessor"),
        CatalogGame("super-mega-baseball-4", "Super Mega Baseball 4", "Esportes", listOf("PlayStation", "Xbox", "PC", "Nintendo"), drawableResName = "game_super_mega_baseball_4"),
        CatalogGame("marauders", "Marauders", "FPS / Extração", listOf("PC"), drawableResName = "game_marauders"),
        CatalogGame("legacy-steel-and-sorcery", "Legacy: Steel & Sorcery", "RPG / Ação", listOf("PC"), drawableResName = "game_legacy_steel_and_sorcery"),
        CatalogGame("ninjala", "Ninjala", "Ação Competitiva", listOf("Nintendo"), drawableResName = "game_ninjala"),
        CatalogGame("roller-champions", "Roller Champions", "Esportes", listOf("PlayStation", "Xbox", "PC", "Nintendo"), drawableResName = "game_roller_champions"),
        CatalogGame("ghost-recon-breakpoint", "Ghost Recon Breakpoint", "FPS Tático", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_ghost_recon_breakpoint"),
        CatalogGame("dark-alliance", "Dungeons & Dragons: Dark Alliance", "RPG / Ação", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_dark_alliance"),
        CatalogGame("wolcen-lords-of-mayhem", "Wolcen: Lords of Mayhem", "RPG / Ação", listOf("PlayStation", "Xbox", "PC"), drawableResName = "game_wolcen_lords_of_mayhem"),
        CatalogGame("streamline", "Streamline", "Ação Competitiva", listOf("PC"), drawableResName = "game_streamline"),
        CatalogGame("tacticool", "Tacticool", "FPS Tático", listOf("PC", "Mobile"), drawableResName = "game_tacticool"),
        CatalogGame("ghost-war", "Ghost War", "FPS Mobile", listOf("Mobile"), drawableResName = "game_ghost_war"),
        CatalogGame("overwatch-2", "Overwatch 2", "FPS Competitivo", listOf("PlayStation", "Xbox", "PC", "Nintendo"), drawableResName = "game_overwatch_2"),
        CatalogGame("clash-royale", "Clash Royale", "Estratégia Mobile", listOf("Mobile"), drawableResName = "game_clash_royale"),
        CatalogGame("pokemon-unite", "Pokémon UNITE", "MOBA Mobile", listOf("Nintendo", "Mobile"), drawableResName = "game_pokemon_unite"),
        CatalogGame("genshin-impact", "Genshin Impact", "RPG / Ação", listOf("PlayStation", "PC", "Mobile"), drawableResName = "game_genshin_impact"),
        CatalogGame("mobile-legends", "Mobile Legends: Bang Bang", "MOBA Mobile", listOf("Mobile"), drawableResName = "game_mobile_legends"),
        CatalogGame("delta-force", "Delta Force", "FPS Tático", listOf("PlayStation", "Xbox", "PC", "Mobile"), drawableResName = "game_delta_force"),
        CatalogGame("standoff-2", "Standoff 2", "FPS Mobile", listOf("Mobile"), drawableResName = "game_standoff_2")
    )

    /** Ids do protótipo anterior que podem estar no histórico de quem já testou. */
    private val legacyIds = mapOf("codm" to "call-of-duty-mobile", "pubg" to "pubg-mobile", "ea-fc" to "eafc")

    fun findById(id: String): CatalogGame {
        val canonical = legacyIds[id] ?: id
        return games.firstOrNull { it.id == canonical } ?: games.first()
    }
}
