package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.repository.LibraryFilter
import com.lagcheck.desktop.library.repository.LibraryRepository
import com.lagcheck.desktop.library.repository.ReferenceGames
import com.lagcheck.desktop.library.scanner.EpicScanner
import com.lagcheck.desktop.library.scanner.SteamScanner
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import java.io.File
import kotlin.test.*

class LibraryCoreTest {

    @Test
    fun testReferenceGamesIntegrity() {
        assertEquals(3, ReferenceGames.list.size)

        val cod = ReferenceGames.CALL_OF_DUTY
        assertEquals("Call of Duty: Warzone", cod.title)
        assertEquals(GamePlatform.STEAM, cod.platform)
        assertTrue(cod.networkSupport is GameNetworkSupport.LagcheckSupported)
        assertEquals("warzone", (cod.networkSupport as GameNetworkSupport.LagcheckSupported).catalogId)

        val fallGuys = ReferenceGames.FALL_GUYS
        assertEquals("Fall Guys", fallGuys.title)
        assertEquals(GamePlatform.EPIC_GAMES, fallGuys.platform)
        assertTrue(fallGuys.networkSupport is GameNetworkSupport.GeneralConnectionOnly)

        val cities = ReferenceGames.CITIES_SKYLINES_2
        assertEquals("Cities: Skylines II", cities.title)
        assertTrue(cities.networkSupport is GameNetworkSupport.OfflineSingleplayer)
    }

    @Test
    fun testSteamManifestParsing() {
        val tempDir = File.createTempFile("steam_test", "")
        tempDir.delete()
        tempDir.mkdirs()

        try {
            val acf = File(tempDir, "appmanifest_730.acf")
            acf.writeText(
                """"AppState"
{
    "appid" "730"
    "Universe" "1"
    "name" "Counter-Strike 2"
    "StateFlags" "4"
    "installdir" "Counter-Strike Global Offensive"
}"""
            )

            val scanner = SteamScanner(tempDir)
            val game = scanner.parseManifest(acf, tempDir)

            assertNotNull(game)
            assertEquals("steam_730", game.id)
            assertEquals("Counter-Strike 2", game.title)
            assertEquals("steam://rungameid/730", game.launchUri)
            assertTrue(game.isInstalled)
            assertTrue(game.networkSupport is GameNetworkSupport.LagcheckSupported)
            assertEquals("cs2", (game.networkSupport as GameNetworkSupport.LagcheckSupported).catalogId)
        } finally {
            tempDir.deleteRecursively()
        }
    }

    @Test
    fun testSteamLibraryFoldersParsing() {
        val tempDir = File.createTempFile("steam_lib_test", "")
        tempDir.delete()
        val steamApps = File(tempDir, "steamapps")
        steamApps.mkdirs()

        try {
            val vdf = File(steamApps, "libraryfolders.vdf")
            vdf.writeText(
                """"libraryfolders"
{
    "0"
    {
        "path" "${tempDir.absolutePath.replace("\\", "\\\\")}"
        "label" ""
    }
}"""
            )

            val scanner = SteamScanner(tempDir)
            val folders = scanner.findLibraryFolders(tempDir)
            assertTrue(folders.isNotEmpty())
            assertTrue(folders.any { it.absolutePath == tempDir.absolutePath })
        } finally {
            tempDir.deleteRecursively()
        }
    }

    @Test
    fun testEpicManifestParsing() {
        val tempDir = File.createTempFile("epic_test", "")
        tempDir.delete()
        tempDir.mkdirs()

        try {
            val item = File(tempDir, "Sugar.item")
            item.writeText(
                """{
    "FormatVersion": 0,
    "AppVersionString": "1.0.0",
    "LaunchExecutable": "FallGuys_client.exe",
    "DisplayName": "Fall Guys",
    "InstallationGuid": "guid-123",
    "InstallLocation": "C:\\Games\\FallGuys",
    "AppName": "Sugar"
}"""
            )

            val scanner = EpicScanner(tempDir)
            val game = scanner.parseItem(item)

            assertNotNull(game)
            assertEquals("epic_Sugar", game.id)
            assertEquals("Fall Guys", game.title)
            assertEquals(GamePlatform.EPIC_GAMES, game.platform)
            assertEquals("com.epicgames.launcher://apps/Sugar?action=launch", game.launchUri)
            assertTrue(game.isInstalled)
            assertTrue(game.networkSupport is GameNetworkSupport.GeneralConnectionOnly)
        } finally {
            tempDir.deleteRecursively()
        }
    }

    @Test
    fun testLibraryRepositoryFilteringAndSearch() = runBlocking {
        val repo = LibraryRepository(this)
        assertTrue(repo.games.size >= 3)

        // Teste de Busca
        repo.searchQuery = "Warzone"
        val searchResult = repo.filteredGames
        assertEquals(1, searchResult.size)
        assertEquals("Call of Duty: Warzone", searchResult.first().title)

        // Limpar busca
        repo.searchQuery = ""

        // Teste de Filtro Steam
        repo.filter = LibraryFilter.STEAM
        val steamOnly = repo.filteredGames
        assertTrue(steamOnly.all { it.platform == GamePlatform.STEAM })

        // Teste de Filtro Epic
        repo.filter = LibraryFilter.EPIC
        val epicOnly = repo.filteredGames
        assertTrue(epicOnly.all { it.platform == GamePlatform.EPIC_GAMES })

        // Teste de Favoritar
        val cities = repo.games.first { it.id == ReferenceGames.CITIES_SKYLINES_2.id }
        assertFalse(cities.isFavorite)
        repo.toggleFavorite(cities)

        val updatedCities = repo.games.first { it.id == ReferenceGames.CITIES_SKYLINES_2.id }
        assertTrue(updatedCities.isFavorite)

        // Limpar filtro
        repo.filter = LibraryFilter.ALL
        repo.selectGame(updatedCities)
        assertEquals(updatedCities.id, repo.selectedGame?.id)
    }
}
