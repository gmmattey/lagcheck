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
    val drawableResName: String
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
        CatalogGame("rocket-league-sideswipe", "Rocket League Sideswipe", "Competitivo Mobile", listOf("Mobile"), drawableResName = "")
    )

    /** Ids do protótipo anterior que podem estar no histórico de quem já testou. */
    private val legacyIds = mapOf("codm" to "call-of-duty-mobile", "pubg" to "pubg-mobile", "ea-fc" to "eafc")

    fun findById(id: String): CatalogGame {
        val canonical = legacyIds[id] ?: id
        return games.firstOrNull { it.id == canonical } ?: games.first()
    }
}
