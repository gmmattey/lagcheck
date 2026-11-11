package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.scanner.EpicScanner
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
}
