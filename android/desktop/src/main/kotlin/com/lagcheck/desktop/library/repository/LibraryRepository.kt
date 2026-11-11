package com.lagcheck.desktop.library.repository

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.scanner.EpicScanner
import com.lagcheck.desktop.library.scanner.SteamScanner
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

enum class LibraryFilter(val label: String) {
    ALL("Todos"),
    INSTALLED("Instalados"),
    FAVORITES("Favoritos"),
    STEAM("Steam"),
    EPIC("Epic Games")
}

class LibraryRepository(private val scope: CoroutineScope) {
    private val steamScanner = SteamScanner()
    private val epicScanner = EpicScanner()

    val games = mutableStateListOf<PcGame>()
    var selectedGame by mutableStateOf<PcGame?>(null)
    var filter by mutableStateOf(LibraryFilter.ALL)
    var searchQuery by mutableStateOf("")
    var isScanning by mutableStateOf(false)
    var launchMessage by mutableStateOf<String?>(null)

    private val prefsFile: File by lazy {
        val baseDir = File(System.getProperty("user.home"), ".lagcheck")
        if (!baseDir.exists()) baseDir.mkdirs()
        File(baseDir, "orbit_prefs.properties")
    }

    init {
        // 1. Iniciar com os jogos de referência canônicos
        games.addAll(ReferenceGames.list)
        selectedGame = ReferenceGames.CALL_OF_DUTY
        loadPreferences()

        // 2. Realizar varredura assíncrona de launchers instalados
        rescan()
    }

    fun rescan() {
        if (isScanning) return
        isScanning = true
        scope.launch {
            val scanned = withContext(Dispatchers.IO) {
                val steamGames = runCatching { steamScanner.scan() }.getOrDefault(emptyList())
                val epicGames = runCatching { epicScanner.scan() }.getOrDefault(emptyList())
                steamGames + epicGames
            }

            // Preservar jogos de referência e mesclar novos jogos encontrados sem duplicar IDs
            val existingIds = games.map { it.id }.toSet()
            for (g in scanned) {
                if (g.id !in existingIds) {
                    games.add(g)
                }
            }
            isScanning = false
        }
    }

    fun toggleFavorite(game: PcGame) {
        val index = games.indexOfFirst { it.id == game.id }
        if (index != -1) {
            val updated = game.copy(isFavorite = !game.isFavorite)
            games[index] = updated
            if (selectedGame?.id == game.id) {
                selectedGame = updated
            }
            savePreferences()
        }
    }

    fun selectGame(game: PcGame) {
        selectedGame = game
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

    private fun loadPreferences() {
        if (!prefsFile.exists()) return
        try {
            val lines = prefsFile.readLines()
            val favoriteIds = lines.filter { it.startsWith("fav:") }.map { it.removePrefix("fav:").trim() }.toSet()
            for (i in games.indices) {
                if (games[i].id in favoriteIds) {
                    games[i] = games[i].copy(isFavorite = true)
                }
            }
            if (selectedGame != null && selectedGame!!.id in favoriteIds) {
                selectedGame = selectedGame!!.copy(isFavorite = true)
            }
        } catch (_: Exception) {
            // Em caso de falha de leitura, mantém o estado padrão
        }
    }

    private fun savePreferences() {
        try {
            val favorites = games.filter { it.isFavorite }.map { "fav:${it.id}" }
            prefsFile.writeText(favorites.joinToString("\n"))
        } catch (_: Exception) {
            // Falha silenciosa sem travar a interface
        }
    }
}
