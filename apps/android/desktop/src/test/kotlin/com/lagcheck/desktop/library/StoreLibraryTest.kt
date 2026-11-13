package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.artwork.ArtworkCandidate
import com.lagcheck.desktop.library.artwork.ArtworkType
import com.lagcheck.desktop.library.artwork.EpicCatalogSource
import com.lagcheck.desktop.library.artwork.XboxPackageArtSource
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.scanner.InstalledPackage
import com.lagcheck.desktop.library.scanner.ScanResult
import com.lagcheck.desktop.library.scanner.XboxScanner
import com.lagcheck.desktop.library.scanner.StoreCatalog
import com.lagcheck.desktop.library.scanner.StoreProduct
import com.lagcheck.desktop.library.scanner.StoreProductLookup
import com.lagcheck.desktop.library.scanner.parsePackageLines
import java.io.File
import java.nio.file.Files
import java.util.Base64
import kotlin.test.*

class StoreLibraryTest {
    private fun tempDir(): File = Files.createTempDirectory("store_test").toFile()

    private fun fakeXboxPackage(root: File): InstalledPackage {
        val content = File(root, "Content").apply { mkdirs() }
        File(content, "MicrosoftGame.config").writeText(
            """<?xml version="1.0" encoding="utf-8"?>
<Game configVersion="1">
  <Identity Name="Contoso.Racer" Publisher="CN=Contoso" Version="1.0.0.0"/>
  <ExecutableList><Executable Name="Racer.exe" Id="Game"/></ExecutableList>
  <ShellVisuals DefaultDisplayName="Racer Infinite" Square480x480Logo="Logo480.png" SplashScreenImage="Splash.png"/>
</Game>""",
        )
        File(content, "appxmanifest.xml").writeText("""<Package><Applications><Application Id="Game" Executable="Racer.exe"/></Applications></Package>""")
        File(content, "Racer.exe").writeText("x")
        val png = byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47) + ByteArray(32)
        File(content, "Logo480.png").writeBytes(png)
        File(content, "Splash.png").writeBytes(png)
        return InstalledPackage("Contoso.Racer_abc123", root.absolutePath + File.separator + "Content")
    }

    @Test
    fun xboxScannerFindsGdkGameAndSkipsPlainApps() {
        val dir = tempDir()
        try {
            val game = fakeXboxPackage(File(dir, "Racer"))
            val plainApp = File(dir, "Notepad").apply { mkdirs() }
            val result = XboxScanner(packages = { listOf(game, InstalledPackage("Microsoft.Notepad_x", plainApp.absolutePath)) }).scan()

            assertIs<ScanResult.Found>(result)
            assertEquals(1, result.games.size)
            val found = result.games.single()
            assertEquals("xbox_Contoso.Racer_abc123", found.id)
            assertEquals("Racer Infinite", found.title)
            assertEquals(GamePlatform.XBOX, found.platform)
            assertEquals("shell:AppsFolder\\Contoso.Racer_abc123!Game", found.launchUri)
            assertNotNull(found.executablePath)
        } finally {
            dir.deleteRecursively()
        }
    }

    @Test
    fun xboxScannerReportsUnavailableWhenPackagesCannotBeListed() {
        assertIs<ScanResult.Unavailable>(XboxScanner(packages = { null }).scan())
    }

    @Test
    fun xboxArtworkComesFromPackageFiles() {
        val dir = tempDir()
        try {
            val pkg = fakeXboxPackage(File(dir, "Racer"))
            val game = XboxScanner(packages = { listOf(pkg) }).scan().let { (it as ScanResult.Found).games.single() }
            val cover = XboxPackageArtSource().candidates(game, ArtworkType.COVER)
            val hero = XboxPackageArtSource().candidates(game, ArtworkType.HERO)
            assertTrue((cover.first() as ArtworkCandidate.LocalFile).path.fileName.toString() == "Logo480.png")
            assertTrue((hero.first() as ArtworkCandidate.LocalFile).path.fileName.toString() == "Splash.png")
        } finally {
            dir.deleteRecursively()
        }
    }

    @Test
    fun packageListingIsParsedLineByLine() {
        val parsed = parsePackageLines("\uFEFFA.B_x|C:\\Games\\A\r\n\r\nbad line\r\nC.D_y|D:\\XboxGames\\D\\Content\r\n")
        assertEquals(listOf(InstalledPackage("A.B_x", "C:\\Games\\A"), InstalledPackage("C.D_y", "D:\\XboxGames\\D\\Content")), parsed)
    }

    @Test
    fun epicArtworkComesFromLauncherCatalogByItemId() {
        val dir = tempDir()
        try {
            File(dir, "Manifests").mkdirs()
            File(dir, "Catalog").mkdirs()
            File(dir, "Manifests/A1.item").writeText("""{"AppName": "appX", "CatalogItemId": "item42", "DisplayName": "Fall Guys"}""")
            val catalog = """[{"id":"item42","title":"Fall Guys","keyImages":[{"type":"DieselGameBox","url":"https://cdn1.epicgames.com/wide"},{"type":"DieselGameBoxTall","url":"https://cdn1.epicgames.com/tall"}]}]"""
            File(dir, "Catalog/catcache.bin").writeText(Base64.getEncoder().encodeToString(catalog.toByteArray()))
            val game = PcGame("epic_appX", "Fall Guys (Edição)", GamePlatform.EPIC_GAMES)
            val source = EpicCatalogSource { dir }

            assertEquals("https://cdn1.epicgames.com/tall", (source.candidates(game, ArtworkType.COVER).first() as ArtworkCandidate.Remote).url)
            assertEquals("https://cdn1.epicgames.com/wide", (source.candidates(game, ArtworkType.HERO).first() as ArtworkCandidate.Remote).url)
            assertTrue(source.candidates(game.copy(platform = GamePlatform.STEAM), ArtworkType.COVER).isEmpty())
        } finally {
            dir.deleteRecursively()
        }
    }

    private fun fakeUwpPackage(root: File, appListEntry: String? = null): InstalledPackage {
        root.mkdirs()
        val entry = if (appListEntry != null) " AppListEntry=\"$appListEntry\"" else ""
        File(root, "AppxManifest.xml").writeText(
            """<Package xmlns:uap="x"><Applications><Application Id="App"><uap:VisualElements DisplayName="Injustice 2"$entry/></Application></Applications></Package>""",
        )
        return InstalledPackage("Warner.Injustice2_abc", root.absolutePath, "Store")
    }

    @Test
    fun storeGameIsFoundThroughCatalogAndNonGamesAreIgnored() {
        val dir = tempDir()
        try {
            val game = fakeUwpPackage(File(dir, "inj"))
            val hidden = fakeUwpPackage(File(dir, "hidden"), appListEntry = "none").copy(packageFamilyName = "Hidden.Theme_x")
            val calc = fakeUwpPackage(File(dir, "calc")).copy(packageFamilyName = "Contoso.Calc_x")
            val asked = mutableListOf<String>()
            val store = StoreProductLookup { pfn ->
                asked += pfn
                if (pfn.startsWith("Warner")) StoreProduct("Injustice 2", isGame = true) else StoreProduct(pfn, isGame = false)
            }
            val result = XboxScanner({ listOf(game, hidden, calc) }, store).scan() as ScanResult.Found

            assertEquals(listOf("xbox_Warner.Injustice2_abc"), result.games.map { it.id })
            assertEquals("shell:AppsFolder\\Warner.Injustice2_abc!App", result.games.single().launchUri)
            assertFalse("Hidden.Theme_x" in asked, "pacote sem entrada no menu Iniciar não deve ser consultado")
            assertFalse(result.incomplete)
        } finally {
            dir.deleteRecursively()
        }
    }

    @Test
    fun scanIsIncompleteWhenCatalogCannotAnswer() {
        val dir = tempDir()
        try {
            val result = XboxScanner({ listOf(fakeUwpPackage(File(dir, "inj"))) }, StoreProductLookup { null }).scan() as ScanResult.Found
            assertTrue(result.games.isEmpty())
            assertTrue(result.incomplete)
        } finally {
            dir.deleteRecursively()
        }
    }

    @Test
    fun catalogResponseGivesGameFlagTitleAndImages() {
        val body = """{"Products":[{"ProductType":"Game","LocalizedProperties":[{"ProductTitle":"Injustice 2","Images":[
            {"ImagePurpose":"Poster","Width":720,"Height":1080,"Uri":"//store-images.s-microsoft.com/image/p"},
            {"ImagePurpose":"SuperHeroArt","Width":1920,"Height":1080,"Uri":"//store-images.s-microsoft.com/image/h"}]}]}]}"""
        val product = StoreCatalog.parseProduct(body)!!
        assertTrue(product.isGame)
        assertEquals("Injustice 2", product.title)
        assertEquals("https://store-images.s-microsoft.com/image/p?q=90&w=600&h=900", product.posterUrl)
        assertEquals("https://store-images.s-microsoft.com/image/h?q=90&w=1920&h=1080", product.heroUrl)
        assertFalse(StoreCatalog.parseProduct("""{"Products":[{"ProductType":"Application","LocalizedProperties":[{"ProductTitle":"Calc"}]}]}""")!!.isGame)
    }
}
