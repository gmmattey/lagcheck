package com.lagcheck.desktop.library.scanner

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame

/** Resultado de uma varredura. Só [Found] autoriza concluir que um jogo sumiu. */
sealed interface ScanResult {
    /**
     * O launcher foi encontrado e lido.
     * @param unreachableRoots pastas de instalação listadas pelo launcher mas inacessíveis agora (disco desconectado).
     * @param unreadableIds jogos cuja entrada existe mas não foi possível ler.
     * @param incomplete true quando alguma entrada ilegível não permite saber a qual jogo pertencia.
     */
    data class Found(
        val games: List<PcGame>,
        val unreachableRoots: List<String> = emptyList(),
        val unreadableIds: Set<String> = emptySet(),
        val incomplete: Boolean = false,
    ) : ScanResult

    /** Launcher não encontrado ou ilegível: o resultado não diz nada sobre quais jogos existem. */
    data class Unavailable(val reason: String) : ScanResult
}

/**
 * Contrato para scanners de launchers e plataformas de jogos PC (Steam, Epic, Xbox).
 */
interface LibraryScanner {
    val name: String
    val platform: GamePlatform
    fun scan(): ScanResult
}
