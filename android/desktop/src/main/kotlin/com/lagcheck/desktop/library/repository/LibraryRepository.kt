package com.lagcheck.desktop.library.repository

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.lagcheck.desktop.library.launcher.GameLaunchResult
import com.lagcheck.desktop.library.launcher.GameRunner
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.scanner.EpicScanner
import com.lagcheck.desktop.library.scanner.LibraryScanner
import com.lagcheck.desktop.library.scanner.SteamScanner
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

enum class LibraryFilter(val label: String) {
    ALL("Todos"),
    INSTALLED("Instalados"),
    FAVORITES("Favoritos"),
    STEAM("Steam"),
    EPIC("Epic Games")
}

/**
 * Biblioteca de jogos realmente encontrados no computador. Não existe jogo de demonstração:
 * sem scanner que encontre algo, a lista fica vazia e a interface mostra o estado vazio.
 */
class LibraryRepository(
    private val scope: CoroutineScope,
    private val scanners: List<LibraryScanner> = listOf(SteamScanner(), EpicScanner()),
    private val store: LibraryStore = LibraryStore.default(),
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
    private val launcher: (PcGame) -> GameLaunchResult = { GameRunner.launch(it) },
    private val clock: () -> Long = { System.currentTimeMillis() },
    autoScan: Boolean = true,
) {
    val games = mutableStateListOf<PcGame>()
    var filter by mutableStateOf(LibraryFilter.ALL)
    var searchQuery by mutableStateOf("")
    var isScanning by mutableStateOf(false)
    var hasScanned by mutableStateOf(false)
    var launchMessage by mutableStateOf<String?>(null)

    private var selectedId by mutableStateOf<String?>(null)
    private var prefs: LibraryStore.Snapshot = store.load()

    /** Jogo escolhido pelo usuário; sem escolha, o destaque segue a regra do [HeroSelector]. */
    val selectedGame: PcGame?
        get() = games.firstOrNull { it.id == selectedId } ?: HeroSelector.pick(games)

    init {
        if (autoScan) rescan()
    }

    fun rescan(): Job {
        if (isScanning) return Job().also { it.complete() }
        isScanning = true
        return scope.launch {
            try {
                val scanned = withContext(ioDispatcher) {
                    scanners.flatMap { runCatching { it.scan() }.getOrDefault(emptyList()) }
                }
                merge(scanned)
            } finally {
                hasScanned = true
                isScanning = false
            }
        }
    }

    /** Acrescenta novos jogos e atualiza os já conhecidos, preservando as preferências. */
    private fun merge(scanned: List<PcGame>) {
        for (found in scanned) {
            val withPrefs = applyPrefs(found)
            val index = games.indexOfFirst { it.id == found.id }
            if (index == -1) games.add(withPrefs) else games[index] = withPrefs
        }
    }

    private fun applyPrefs(game: PcGame): PcGame = game.copy(
        isFavorite = game.id in prefs.favorites,
        lastLaunchedEpochMs = prefs.lastLaunched[game.id],
    )

    fun toggleFavorite(game: PcGame) {
        val index = games.indexOfFirst { it.id == game.id }
        if (index == -1) return
        val nowFavorite = !games[index].isFavorite
        games[index] = games[index].copy(isFavorite = nowFavorite)
        prefs = prefs.copy(favorites = if (nowFavorite) prefs.favorites + game.id else prefs.favorites - game.id)
        store.save(prefs)
    }

    fun selectGame(game: PcGame) {
        selectedId = game.id
    }

    /** Inicia o jogo pelo launcher. Só registra "último iniciado" quando a abertura foi aceita. */
    fun launch(game: PcGame): GameLaunchResult {
        val result = launcher(game)
        launchMessage = when (result) {
            is GameLaunchResult.Success -> result.message
            is GameLaunchResult.Failure -> result.reason
        }
        if (result is GameLaunchResult.Success) {
            val at = clock()
            val index = games.indexOfFirst { it.id == game.id }
            if (index != -1) games[index] = games[index].copy(lastLaunchedEpochMs = at)
            prefs = prefs.copy(lastLaunched = prefs.lastLaunched + (game.id to at))
            store.save(prefs)
        }
        return result
    }

    val filteredGames: List<PcGame>
        get() {
            val query = searchQuery.trim().lowercase()
            return games.filter { game ->
                val matchesFilter = when (filter) {
                    LibraryFilter.ALL -> true
                    LibraryFilter.INSTALLED -> game.isInstalled
                    LibraryFilter.FAVORITES -> game.isFavorite
                    LibraryFilter.STEAM -> game.platform == GamePlatform.STEAM
                    LibraryFilter.EPIC -> game.platform == GamePlatform.EPIC_GAMES
                }
                val matchesQuery = query.isEmpty() || game.title.lowercase().contains(query) ||
                        game.tags.any { it.lowercase().contains(query) }
                matchesFilter && matchesQuery
            }
        }
}
