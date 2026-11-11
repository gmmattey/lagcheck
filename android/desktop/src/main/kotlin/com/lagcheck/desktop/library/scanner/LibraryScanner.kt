package com.lagcheck.desktop.library.scanner

import com.lagcheck.desktop.library.model.PcGame

/**
 * Contrato para scanners de launchers e plataformas de jogos PC (Steam, Epic, Xbox).
 */
interface LibraryScanner {
    val name: String
    fun scan(): List<PcGame>
}
