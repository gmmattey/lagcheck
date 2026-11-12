package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.scanner.LibraryScanner
import com.lagcheck.desktop.library.scanner.ScanResult

/** Jogos de teste. Existem só aqui: a biblioteca de produção nunca recebe jogo de demonstração. */
object TestGames {
    val cs2 = PcGame("steam_730", "Counter-Strike 2", GamePlatform.STEAM)
    val fallGuys = PcGame("epic_Sugar", "Fall Guys", GamePlatform.EPIC_GAMES)
    val cities = PcGame("steam_949230", "Cities: Skylines II", GamePlatform.STEAM)
    val apex = PcGame("steam_1172470", "Apex Legends", GamePlatform.STEAM, isInstalled = false)
}

class FakeScanner(
    private val games: List<PcGame>,
    private val fail: Boolean = false,
    override val platform: GamePlatform = GamePlatform.STEAM,
) : LibraryScanner {
    override val name = "fake"
    override fun scan(): ScanResult = if (fail) error("launcher fora do ar") else ScanResult.Found(games)
}

/** Scanner cujo resultado muda entre varreduras, para simular desinstalar, launcher fora do ar etc. */
class MutableScanner(var result: ScanResult, override val platform: GamePlatform = GamePlatform.STEAM) : LibraryScanner {
    override val name = "mutable"
    override fun scan(): ScanResult = result
}
