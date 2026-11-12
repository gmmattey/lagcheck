package com.lagcheck.desktop.library.repository

import com.lagcheck.desktop.library.model.PcGame

/**
 * Escolhe o jogo em destaque quando o usuário ainda não selecionou nenhum.
 * Só considera jogos instalados. Ordem de prioridade:
 * 1. último iniciado pelo LagCheck;
 * 2. último executado, quando o launcher informa com confiança;
 * 3. instalado mais recentemente, quando a data existe;
 * 4. primeiro por título (desempate determinístico por id).
 */
object HeroSelector {
    private val byTitle = compareBy<PcGame>({ it.title.lowercase() }, { it.id })

    fun pick(games: List<PcGame>): PcGame? {
        val installed = games.filter { it.isInstalled }
        if (installed.isEmpty()) return null
        return mostRecent(installed) { it.lastLaunchedEpochMs }
            ?: mostRecent(installed) { it.lastPlayedEpochMs }
            ?: mostRecent(installed) { it.installedAtEpochMs }
            ?: installed.sortedWith(byTitle).first()
    }

    private fun mostRecent(games: List<PcGame>, at: (PcGame) -> Long?): PcGame? =
        games.filter { at(it) != null }
            .sortedWith(compareByDescending<PcGame> { at(it) }.then(byTitle))
            .firstOrNull()
}
