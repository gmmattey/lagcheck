package com.lagcheck.desktop.library.repository

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.network.TitleKey
import com.lagcheck.desktop.library.scanner.ScanResult

/**
 * Regras que juntam o que os launchers dizem agora com o que o app já conhecia.
 * Puro e determinístico: não lê disco, não conhece interface.
 */
object LibraryReconciler {

    /** Prioridade ao escolher qual cópia de um jogo duplicado aparece: menor vem primeiro. */
    private val platformOrder = mapOf(GamePlatform.STEAM to 0, GamePlatform.EPIC_GAMES to 1, GamePlatform.XBOX to 2, GamePlatform.MANUAL to 3)

    /**
     * Atualiza a lista de jogos conhecidos com o resultado das varreduras.
     *
     * - Jogo novo entra; jogo já conhecido tem os dados atualizados (pasta, executável, estado de instalação).
     * - Jogo que sumiu de uma varredura bem-sucedida vira "conhecido, não instalado": continua na lista com favorito e histórico.
     * - Varredura indisponível, disco desconectado ou entrada ilegível **nunca** contam como remoção.
     * - Jogos manuais não dependem de launcher e nunca são alterados aqui.
     */
    fun reconcile(known: List<PcGame>, scans: List<Pair<GamePlatform, ScanResult>>): List<PcGame> {
        var current = known
        for ((platform, result) in scans) {
            if (result !is ScanResult.Found) continue
            current = applyFound(current, platform, result)
        }
        return current
    }

    private fun applyFound(known: List<PcGame>, platform: GamePlatform, found: ScanResult.Found): List<PcGame> {
        val scannedById = found.games.associateBy { it.id }
        val result = LinkedHashMap<String, PcGame>()

        for (old in known) {
            if (old.platform != platform) { result[old.id] = old; continue }
            val seen = scannedById[old.id]
            result[old.id] = when {
                seen != null -> merge(old, seen)
                // A entrada pode existir; só não conseguimos ler agora.
                found.incomplete || old.id in found.unreadableIds || isUnderAny(old.installDirectory, found.unreachableRoots) -> old
                old.isInstalled -> old.copy(isInstalled = false)
                else -> old
            }
        }
        for (game in found.games) if (game.id !in result) result[game.id] = game
        return result.values.toList()
    }

    /** Dados do launcher vencem; o que só o app sabe (histórico) é preservado. */
    private fun merge(old: PcGame, seen: PcGame): PcGame = seen.copy(
        lastPlayedEpochMs = seen.lastPlayedEpochMs ?: old.lastPlayedEpochMs,
        lastLaunchedEpochMs = old.lastLaunchedEpochMs,
        installedAtEpochMs = seen.installedAtEpochMs ?: old.installedAtEpochMs,
        playTimeMinutes = if (seen.playTimeMinutes > 0) seen.playTimeMinutes else old.playTimeMinutes,
        isFavorite = old.isFavorite,
    )

    /**
     * Agrupa cópias do mesmo jogo em plataformas diferentes (mesmo título normalizado ou mesma pasta de instalação)
     * e mostra uma só. Instalado vence não instalado; depois a ordem Steam, Epic, Xbox, manual; depois o id.
     * Favorito vale para o grupo e o último início é o mais recente do grupo.
     */
    fun dedupe(games: List<PcGame>): List<PcGame> {
        if (games.size < 2) return games
        val parent = IntArray(games.size) { it }
        fun find(x: Int): Int { var r = x; while (parent[r] != r) r = parent[r]; return r }
        fun union(a: Int, b: Int) { parent[find(a)] = find(b) }

        val byKey = HashMap<String, Int>()
        games.forEachIndexed { i, g ->
            val keys = listOfNotNull(
                TitleKey.of(g.title).takeIf { it.isNotEmpty() }?.let { "t:$it" },
                g.installDirectory?.let(::normalizePath)?.takeIf { it.isNotEmpty() }?.let { "d:$it" },
            )
            for (k in keys) { val seen = byKey.putIfAbsent(k, i); if (seen != null) union(i, seen) }
        }

        val comparator = compareBy<PcGame>({ !it.isInstalled }, { platformOrder[it.platform] ?: 9 }, { it.id })
        return games.indices.groupBy { find(it) }.values
            .map { idxs ->
                val group = idxs.map { games[it] }
                val winner = group.sortedWith(comparator).first()
                if (group.size == 1) winner else winner.copy(
                    isFavorite = group.any { it.isFavorite },
                    lastLaunchedEpochMs = group.mapNotNull { it.lastLaunchedEpochMs }.maxOrNull(),
                    alsoIds = group.map { it.id }.filter { it != winner.id }.sorted(),
                )
            }
            .sortedWith(compareBy({ it.title.lowercase() }, { it.id }))
    }

    private fun isUnderAny(path: String?, roots: List<String>): Boolean {
        if (path == null || roots.isEmpty()) return false
        val p = normalizePath(path)
        return roots.any { r -> normalizePath(r).let { it.isNotEmpty() && (p == it || p.startsWith("$it/")) } }
    }

    internal fun normalizePath(path: String): String = path.replace('\\', '/').trimEnd('/').lowercase()

}
