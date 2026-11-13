package com.lagcheck.desktop.library.model

/**
 * Diz se um item da biblioteca é jogo. Existe porque os launchers misturam software (OBS, ferramentas, engines)
 * com jogos, e a biblioteca só deve mostrar jogos. `null` significa "não sei": nesse caso o item permanece.
 */
interface GameKindSource {
    /** Resposta que já está em disco ou nos arquivos locais; nunca usa a rede. */
    fun cached(game: PcGame): Boolean?

    /** Pode consultar a loja (se o download estiver permitido) e guarda o resultado para [cached]. */
    suspend fun classify(game: PcGame): Boolean?

    companion object {
        val NONE: GameKindSource = object : GameKindSource {
            override fun cached(game: PcGame): Boolean? = null
            override suspend fun classify(game: PcGame): Boolean? = null
        }
    }
}
