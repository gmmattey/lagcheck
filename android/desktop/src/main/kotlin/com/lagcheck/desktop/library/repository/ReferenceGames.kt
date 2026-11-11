package com.lagcheck.desktop.library.repository

import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame

/**
 * Jogos iniciais de referência para validação da interface ORBIT (Fase 4):
 * - Cities: Skylines II: Valida o comportamento de jogo solo/offline (sem testes fictícios de latência).
 * - Fall Guys: Valida jogo casual/party game na Epic Games Store.
 * - Call of Duty: Valida o jogo competitivo hardcore com diagnóstico completo de rede.
 */
object ReferenceGames {
    val CITIES_SKYLINES_2 = PcGame(
        id = "ref_cities_skylines_2",
        title = "Cities: Skylines II",
        platform = GamePlatform.STEAM,
        launchUri = "steam://rungameid/949230",
        isInstalled = true,
        isFavorite = false,
        playTimeMinutes = 420,
        localArtworkRes = null,
        networkSupport = GameNetworkSupport.OfflineSingleplayer("Jogo de simulação solo. Não requer verificação de servidores de rede."),
        tags = listOf("Simulação", "Construção de Cidades", "Estratégia"),
        description = "Construa uma metrópole próspera e veja sua cidade ganhar vida nesta simulação urbana realista e detalhada."
    )

    val FALL_GUYS = PcGame(
        id = "ref_fall_guys",
        title = "Fall Guys",
        platform = GamePlatform.EPIC_GAMES,
        launchUri = "com.epicgames.launcher://apps/Sugar?action=launch",
        isInstalled = true,
        isFavorite = true,
        playTimeMinutes = 890,
        localArtworkRes = null,
        networkSupport = GameNetworkSupport.GeneralConnectionOnly("Party game online via Epic Online Services. O teste avalia a estabilidade geral da rota."),
        tags = listOf("Party Game", "Battle Royale", "Multiplayer", "Casual"),
        description = "Junte-se a multidões de jogadores tropeçando em arenas caóticas e percursos de obstáculos hilários até a coroa final."
    )

    val CALL_OF_DUTY = PcGame(
        id = "ref_call_of_duty",
        title = "Call of Duty: Warzone",
        platform = GamePlatform.STEAM,
        launchUri = "steam://rungameid/1938090",
        isInstalled = true,
        isFavorite = true,
        playTimeMinutes = 2460,
        localArtworkRes = "game_warzone",
        networkSupport = GameNetworkSupport.LagcheckSupported(catalogId = "warzone", regionLabel = "São Paulo, BR"),
        tags = listOf("FPS Competitivo", "Battle Royale", "Ação"),
        description = "Combate massivo em primeira pessoa no battle royale competitivo de ritmo acelerado. Cada milissegundo de latência conta."
    )

    val list: List<PcGame> = listOf(
        CALL_OF_DUTY,
        FALL_GUYS,
        CITIES_SKYLINES_2
    )
}
