package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.scanner.LibraryScanner

/** Jogos de teste. Existem só aqui: a biblioteca de produção nunca recebe jogo de demonstração. */
object TestGames {
    val cs2 = PcGame("steam_730", "Counter-Strike 2", GamePlatform.STEAM, networkSupport = GameNetworkSupport.LagcheckSupported("cs2"))
    val fallGuys = PcGame("epic_Sugar", "Fall Guys", GamePlatform.EPIC_GAMES, networkSupport = GameNetworkSupport.GeneralConnectionOnly())
    val cities = PcGame("steam_949230", "Cities: Skylines II", GamePlatform.STEAM, networkSupport = GameNetworkSupport.OfflineSingleplayer())
    val apex = PcGame("steam_1172470", "Apex Legends", GamePlatform.STEAM, isInstalled = false)
}

class FakeScanner(private val games: List<PcGame>, private val fail: Boolean = false) : LibraryScanner {
    override val name = "fake"
    override fun scan(): List<PcGame> = if (fail) error("launcher fora do ar") else games
}
