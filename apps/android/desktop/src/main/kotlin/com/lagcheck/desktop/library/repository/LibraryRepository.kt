package com.lagcheck.desktop.library.repository

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.Snapshot
import com.lagcheck.desktop.DesktopStoreCatalog
import com.lagcheck.desktop.library.launcher.GameLaunchResult
import com.lagcheck.desktop.library.launcher.GameRunner
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.network.NetworkSupportResolver
import com.lagcheck.desktop.library.scanner.EpicScanner
import com.lagcheck.desktop.library.scanner.LibraryScanner
import com.lagcheck.desktop.library.scanner.ScanResult
import com.lagcheck.desktop.library.scanner.SteamScanner
import com.lagcheck.desktop.library.scanner.XboxScanner
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.sync.withPermit

enum class LibraryFilter(val label: String) {
    ALL("Todos"),
    INSTALLED("Instalados"),
    RECENT("Recentes"),
    FAVORITES("Favoritos"),
    STEAM("Steam"),
    EPIC("Epic Games")
}

/**
 * Biblioteca de jogos realmente encontrados no computador. Não existe jogo de demonstração:
 * sem scanner que encontre algo, a lista fica vazia e a interface mostra o estado vazio.
 *
 * Guarda dois níveis: [known] (tudo que já foi visto, persistido, sem deduplicar) e [games]
 * (o que a interface mostra: sem duplicatas entre plataformas e com as preferências aplicadas).
 */
private const val CLASSIFY_TIMEOUT_MS = 12_000L

class LibraryRepository(
    private val scope: CoroutineScope,
    private val scanners: List<LibraryScanner> = listOf(SteamScanner(), EpicScanner(), XboxScanner(store = DesktopStoreCatalog.catalog)),
    private val store: LibraryStore = LibraryStore.default(),
    private val networkResolver: NetworkSupportResolver = NetworkSupportResolver.NONE,
    private val kindSource: com.lagcheck.desktop.library.model.GameKindSource = com.lagcheck.desktop.library.model.GameKindSource.NONE,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
    private val launcher: (PcGame) -> GameLaunchResult = { GameRunner.launch(it) },
    private val clock: () -> Long = { System.currentTimeMillis() },
    autoScan: Boolean = true,
) {
    val games = mutableStateListOf<PcGame>()
    var filter by mutableStateOf(LibraryFilter.INSTALLED)
    var searchQuery by mutableStateOf("")
    var isScanning by mutableStateOf(false)
    var hasScanned by mutableStateOf(false)
    var launchMessage by mutableStateOf<String?>(null)

    private var selectedId by mutableStateOf<String?>(null)
    private var prefs: LibraryStore.Snapshot = store.load()
    private var known: List<PcGame> = prefs.knownGames

    /** Jogo escolhido pelo usuário; sem escolha, o destaque segue a regra do [HeroSelector]. */
    val selectedGame: PcGame?
        get() = games.firstOrNull { it.id == selectedId || selectedId in it.alsoIds } ?: HeroSelector.pick(games)

    val installedCount: Int get() = games.count { it.isInstalled }

    init {
        publish()
        if (autoScan) rescan()
    }

    fun rescan(): Job {
        if (isScanning) return Job().also { it.complete() }
        isScanning = true
        return scope.launch {
            try {
                val results = withContext(ioDispatcher) {
                    scanners.map { s ->
                        s.platform to runCatching { s.scan() }.getOrElse { ScanResult.Unavailable(it.message ?: "erro") }
                    }
                }
                known = LibraryReconciler.reconcile(known, results)
                prefs = prefs.copy(knownGames = known)
                store.save(prefs)
                classifyUnknown()
                publish()
            } finally {
                hasScanned = true
                isScanning = false
            }
        }
    }

    /**
     * Pergunta às lojas o que ainda não se sabe se é jogo (software como OBS não deve entrar na biblioteca).
     * Limitado em paralelismo e em tempo: se a loja demorar, o item fica e é classificado numa próxima varredura.
     */
    private suspend fun classifyUnknown() {
        val unknown = known.filter { it.platform != GamePlatform.MANUAL && kindSource.cached(it) == null }
        if (unknown.isEmpty()) return
        withTimeoutOrNull(CLASSIFY_TIMEOUT_MS) {
            val gate = kotlinx.coroutines.sync.Semaphore(4)
            coroutineScope {
                unknown.forEach { game -> launch(ioDispatcher) { gate.withPermit { runCatching { kindSource.classify(game) } } } }
            }
        }
    }

    /** Recalcula a lista visível: sem software, rede, preferências, depois deduplicação entre plataformas. */
    private fun publish() {
        val view = LibraryReconciler.dedupe(known.filter { kindSource.cached(it) != false }.map(::withPrefsAndNetwork))
        Snapshot.withMutableSnapshot {
            games.clear()
            games.addAll(view)
        }
    }

    private fun withPrefsAndNetwork(game: PcGame): PcGame = game.copy(
        isFavorite = game.id in prefs.favorites,
        lastLaunchedEpochMs = prefs.lastLaunched[game.id],
        networkSupport = networkResolver.resolve(game),
    )

    fun toggleFavorite(game: PcGame) {
        val ids = listOf(game.id) + game.alsoIds
        val nowFavorite = !game.isFavorite
        prefs = prefs.copy(favorites = if (nowFavorite) prefs.favorites + game.id else prefs.favorites - ids.toSet())
        store.save(prefs)
        publish()
    }

    fun selectGame(game: PcGame) {
        selectedId = game.id
    }

    /** Inicia o jogo pelo launcher. Jogo não instalado não abre; só registra "último iniciado" se a abertura foi aceita. */
    fun launch(game: PcGame): GameLaunchResult {
        val result = if (game.isInstalled) launcher(game) else GameLaunchResult.Failure("${game.title} não está instalado")
        launchMessage = when (result) {
            is GameLaunchResult.Success -> result.message
            is GameLaunchResult.Failure -> result.reason
        }
        if (result is GameLaunchResult.Success) {
            prefs = prefs.copy(lastLaunched = prefs.lastLaunched + (game.id to clock()))
            store.save(prefs)
            publish()
        }
        return result
    }

    val filteredGames: List<PcGame>
        get() {
            val query = searchQuery.trim().lowercase()
            val filtered = games.filter { game ->
                val matchesFilter = when (filter) {
                    LibraryFilter.ALL -> true
                    LibraryFilter.INSTALLED -> game.isInstalled
                    LibraryFilter.RECENT -> game.isInstalled && game.recentActivityEpochMs != null
                    LibraryFilter.FAVORITES -> game.isFavorite
                    LibraryFilter.STEAM -> game.platform == GamePlatform.STEAM
                    LibraryFilter.EPIC -> game.platform == GamePlatform.EPIC_GAMES
                }
                val matchesQuery = query.isEmpty() || game.title.lowercase().contains(query) ||
                        game.tags.any { it.lowercase().contains(query) }
                matchesFilter && matchesQuery
            }
            return if (filter == LibraryFilter.RECENT) {
                filtered.sortedByDescending { it.recentActivityEpochMs }
            } else {
                filtered
            }
        }

    private val PcGame.recentActivityEpochMs: Long?
        get() = listOfNotNull(lastLaunchedEpochMs, lastPlayedEpochMs).maxOrNull()
}
