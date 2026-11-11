package com.lagcheck.desktop.library.model

enum class GamePlatform(val label: String, val badgeColorHex: Long) {
    STEAM("Steam", 0xFF171A21),
    EPIC_GAMES("Epic Games", 0xFF2F3136),
    XBOX("Xbox / PC", 0xFF107C10),
    MANUAL("PC Local", 0xFF374151)
}

sealed interface GameNetworkSupport {
    /** Jogo com servidor dedicado catalogado e medível pelo LagCheck. */
    data class LagcheckSupported(val catalogId: String, val regionLabel: String? = null) : GameNetworkSupport

    /** Jogo multiplayer/online genérico (matchmaking P2P ou sem IP de sonda dedicado). */
    data class GeneralConnectionOnly(val note: String = "Testar conexão geral") : GameNetworkSupport

    /** Jogo estritamente offline/campanha (não inventa medição nem ping). */
    data class OfflineSingleplayer(val note: String = "Jogo solo / Sem servidores dedicados") : GameNetworkSupport
}

data class PcGame(
    val id: String,
    val title: String,
    val platform: GamePlatform,
    val installDirectory: String? = null,
    val executablePath: String? = null,
    val launchUri: String? = null,
    val isInstalled: Boolean = true,
    val isFavorite: Boolean = false,
    val playTimeMinutes: Long = 0,
    /** Última execução registrada pelo próprio launcher. Só preenche quando o dado é confiável. */
    val lastPlayedEpochMs: Long? = null,
    /** Última vez que o jogo foi iniciado pelo LagCheck (botão Jogar). */
    val lastLaunchedEpochMs: Long? = null,
    /** Data de instalação, quando o launcher a expõe. Nunca estimada. */
    val installedAtEpochMs: Long? = null,
    val coverArtworkUrl: String? = null,
    val heroArtworkUrl: String? = null,
    val localArtworkRes: String? = null,
    val networkSupport: GameNetworkSupport = GameNetworkSupport.GeneralConnectionOnly(),
    val tags: List<String> = emptyList(),
    val description: String? = null
)
