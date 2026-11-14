package com.lagcheck.desktop.library.artwork

import com.lagcheck.desktop.library.model.PcGame
import java.nio.file.Path

/** `COVER` é a capa vertical da grade, `HERO` o banner horizontal do destaque, `ICON` o ícone quando existir. */
enum class ArtworkType(val key: String) { COVER("cover"), HERO("hero"), ICON("icon") }

sealed interface ArtworkResult {
    /** Arquivo de imagem pronto para exibir (cache do app ou cache do próprio launcher). */
    data class Available(val path: Path) : ArtworkResult

    /** Nenhuma imagem oficial disponível: a interface mostra a miniatura neutra com o nome do jogo. */
    data object Fallback : ArtworkResult
}

/** Onde uma fonte sugere procurar uma imagem. */
sealed interface ArtworkCandidate {
    data class LocalFile(val path: Path) : ArtworkCandidate
    /** [dimensions] só é preenchida quando a loja publica o tamanho do asset de forma estável. */
    data class Remote(val url: String, val dimensions: ImageBytes.Dimensions? = null) : ArtworkCandidate
}

interface ArtworkSource {
    /** Candidatos em ordem de preferência. Vazio quando a fonte não conhece o jogo. */
    fun candidates(game: PcGame, type: ArtworkType): List<ArtworkCandidate>
}

sealed interface FetchResult {
    class Bytes(val data: ByteArray) : FetchResult
    /** O servidor respondeu que a imagem não existe (resultado estável). */
    data object NotFound : FetchResult
    /** Falha que pode passar sozinha: sem rede, timeout, erro do servidor, resposta fora do esperado. */
    data class Failed(val reason: String) : FetchResult
}

/** Download bloqueante de uma imagem. A implementação real é [HttpArtworkFetcher]; os testes usam um falso. */
interface ArtworkFetcher {
    fun fetch(url: String): FetchResult
}
