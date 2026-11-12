package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.scanner.EpicScanner
import com.lagcheck.desktop.library.scanner.ScanResult
import com.lagcheck.desktop.library.scanner.SteamScanner
import java.io.File
import kotlin.test.*

class LibraryCoreTest {

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
        } finally {
            tempDir.deleteRecursively()
        }
    }

    private fun tmp(): File = File.createTempFile("lc_scan", "").also { it.delete(); it.mkdirs() }

    @Test
    fun steamSemInstalacaoEhIndisponivelNaoVazio() {
        val dir = tmp()
        try {
            // Pasta existe mas não há como saber nada além disso: sem steamapps a varredura é "Found" vazia,
            // enquanto raiz inexistente é "Unavailable" e nunca pode marcar jogos como removidos.
            assertTrue(SteamScanner(File(dir, "nao-existe")).scan() is ScanResult.Unavailable)
            val r = SteamScanner(dir).scan()
            assertTrue(r is ScanResult.Found && r.games.isEmpty())
        } finally { dir.deleteRecursively() }
    }

    @Test
    fun steamRelataBibliotecaInacessivelEManifestoIlegivel() {
        val dir = tmp()
        try {
            val apps = File(dir, "steamapps").also { it.mkdirs() }
            File(apps, "libraryfolders.vdf").writeText(
                """"libraryfolders"
{
    "0" { "path" "${dir.absolutePath.replace("\\", "\\\\")}" "apps" { "730" "123456789" } }
    "1" { "path" "/disco/externo/desconectado" }
}"""
            )
            File(apps, "appmanifest_730.acf").writeText(""""AppState" { "appid" "730" "name" "Counter-Strike 2" "StateFlags" "4" "installdir" "cs2" }""")
            File(apps, "appmanifest_999.acf").writeText("conteúdo corrompido")
            File(apps, "appmanifest_228980.acf").writeText(""""AppState" { "appid" "228980" "name" "Steamworks Common Redistributables" "StateFlags" "4" "installdir" "x" }""")

            val r = SteamScanner(dir).scan() as ScanResult.Found
            assertEquals(listOf("steam_730"), r.games.map { it.id })
            assertEquals(listOf(File("/disco/externo/desconectado").path), r.unreachableRoots) // "730 123456789" não vira pasta
            assertEquals(setOf("steam_999"), r.unreadableIds) // ferramenta filtrada de propósito não conta
        } finally { dir.deleteRecursively() }
    }

    @Test
    fun epicDiferenciaIndisponivelDeVazioEIncompleto() {
        val dir = tmp()
        try {
            assertTrue(EpicScanner(File(dir, "nao-existe")).scan() is ScanResult.Unavailable)
            val empty = EpicScanner(dir).scan() as ScanResult.Found
            assertTrue(empty.games.isEmpty() && !empty.incomplete)

            File(dir, "ok.item").writeText("""{ "DisplayName": "Fortnite", "AppName": "Fortnite", "InstallLocation": "C:\\Games\\F", "LaunchExecutable": "f.exe" }""")
            File(dir, "ruim.item").writeText("sem json")
            File(dir, "ue.item").writeText("""{ "DisplayName": "Unreal Engine 5", "AppName": "UE_5" }""")
            val r = EpicScanner(dir).scan() as ScanResult.Found
            assertEquals(listOf("epic_Fortnite"), r.games.map { it.id })
            assertTrue(r.incomplete) // "sem json" é ilegível; a ferramenta filtrada não conta
        } finally { dir.deleteRecursively() }
    }
}
