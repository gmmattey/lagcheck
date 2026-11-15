package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.artwork.ArtworkCandidate
import com.lagcheck.desktop.library.artwork.ArtworkDiskCache
import com.lagcheck.desktop.library.artwork.ArtworkFetcher
import com.lagcheck.desktop.library.artwork.ArtworkResult
import com.lagcheck.desktop.library.artwork.ArtworkSource
import com.lagcheck.desktop.library.artwork.ArtworkType
import com.lagcheck.desktop.library.artwork.EpicCatalogSource
import com.lagcheck.desktop.library.artwork.FetchResult
import com.lagcheck.desktop.library.artwork.GameArtworkResolver
import com.lagcheck.desktop.library.artwork.SteamCdnSource
import com.lagcheck.desktop.library.artwork.SteamLibraryCacheSource
import com.lagcheck.desktop.library.artwork.StoreCatalogArtSource
import com.lagcheck.desktop.library.info.GameInfoService
import com.lagcheck.desktop.library.info.InfoFetch
import com.lagcheck.desktop.library.info.InfoFetcher
import com.lagcheck.desktop.library.model.GameInfo
import com.lagcheck.desktop.library.model.GameModes
import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.GameUpdateState
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.network.CatalogGame
import com.lagcheck.desktop.library.network.NetworkSupportResolver
import com.lagcheck.desktop.library.scanner.EpicScanner
import com.lagcheck.desktop.library.scanner.SteamScanner
import com.lagcheck.desktop.library.scanner.StoreCatalog
import kotlinx.coroutines.runBlocking
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.io.File
import java.nio.file.Files
import java.util.Base64
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class StoreApiExtensionsTest {

    private fun tempDir(): File = Files.createTempDirectory("lagcheck-ext-test").toFile()

    private fun fakePng(width: Int, height: Int): ByteArray {
        val out = ByteArrayOutputStream()
        val data = DataOutputStream(out)
        data.write(byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A))
        data.writeInt(13)
        data.write("IHDR".toByteArray(Charsets.US_ASCII))
        data.writeInt(width)
        data.writeInt(height)
        data.writeByte(8)
        data.writeByte(6)
        data.writeByte(0)
        data.writeByte(0)
        data.writeByte(0)
        data.writeInt(0)
        return out.toByteArray()
    }

    @Test
    fun steamManifestDecodesUpdateStateSizeAndDownloadProgress() {
        val dir = tempDir()
        try {
            val scanner = SteamScanner(dir)
            val lib = File(dir, "steam")

            fun acf(appId: String, stateFlags: Int, extra: String = ""): File {
                val f = File(dir, "appmanifest_$appId.acf")
                f.writeText(
                    """
                    "AppState"
                    {
                        "appid" "$appId"
                        "name" "Counter-Strike 2"
                        "installdir" "Counter-Strike Global Offensive"
                        "StateFlags" "$stateFlags"
                        "SizeOnDisk" "45000000000"
                        $extra
                    }
                    """.trimIndent(),
                )
                return f
            }

            val ready = scanner.parseManifest(acf("730", 4), lib)!!
            assertEquals(GameUpdateState.READY, ready.updateState)
            assertEquals(45_000_000_000L, ready.sizeOnDiskBytes)

            val updateReq = scanner.parseManifest(acf("731", 2), lib)!!
            assertEquals(GameUpdateState.UPDATE_REQUIRED, updateReq.updateState)

            val downloading = scanner.parseManifest(
                acf(
                    "732",
                    1026,
                    """"BytesToDownload" "1000000"
                       "BytesDownloaded" "250000" """,
                ),
                lib,
            )!!
            assertEquals(GameUpdateState.DOWNLOADING, downloading.updateState)
            assertEquals(250_000L, downloading.downloadBytesCompleted)
            assertEquals(1_000_000L, downloading.downloadBytesTotal)
        } finally {
            dir.deleteRecursively()
        }
    }

    @Test
    fun steamLocalConfigParserReadsPlaytimeAndLastPlayed() {
        val vdf = """
            "UserLocalConfigStore"
            {
                "Software"
                {
                    "Valve"
                    {
                        "Steam"
                        {
                            "apps"
                            {
                                "730"
                                {
                                    "Playtime" "845"
                                    "LastPlayed" "1730000000"
                                }
                                "570"
                                {
                                    "Playtime" "0"
                                }
                            }
                        }
                    }
                }
            }
        """.trimIndent()

        val stats = SteamScanner.parseLocalConfigApps(vdf)
        assertEquals(845L, stats["730"]?.playTimeMinutes)
        assertEquals(1730000000L * 1000L, stats["730"]?.lastPlayedEpochMs)
        assertNull(stats["570"]?.lastPlayedEpochMs)
    }

    @Test
    fun epicItemParsesInstallSizeAndIncompleteFlag() {
        val dir = tempDir()
        try {
            val scanner = EpicScanner(dir)
            val readyItem = File(dir, "ready.item").apply {
                writeText(
                    """
                    {
                        "DisplayName": "Fortnite",
                        "AppName": "Fortnite",
                        "InstallLocation": "${dir.absolutePath.replace("\\", "\\\\")}",
                        "LaunchExecutable": "Fortnite.exe",
                        "InstallSize": 62000000000,
                        "bIsIncompleteInstall": false
                    }
                    """.trimIndent(),
                )
            }
            val incompleteItem = File(dir, "incomplete.item").apply {
                writeText(
                    """
                    {
                        "DisplayName": "Rocket League",
                        "AppName": "Sugar",
                        "InstallLocation": "${dir.absolutePath.replace("\\", "\\\\")}",
                        "LaunchExecutable": "RocketLeague.exe",
                        "InstallSize": 25000000000,
                        "bIsIncompleteInstall": true
                    }
                    """.trimIndent(),
                )
            }

            val ready = scanner.parseItem(readyItem)!!
            assertEquals(GameUpdateState.READY, ready.updateState)
            assertEquals(62_000_000_000L, ready.sizeOnDiskBytes)

            val incomplete = scanner.parseItem(incompleteItem)!!
            assertEquals(GameUpdateState.UPDATE_REQUIRED, incomplete.updateState)
            assertEquals(25_000_000_000L, incomplete.sizeOnDiskBytes)
        } finally {
            dir.deleteRecursively()
        }
    }

    @Test
    fun networkSupportResolverMarksStrictlySingleplayerFromStoreModesAsOffline() {
        val resolver = NetworkSupportResolver(catalog = { emptyList<CatalogGame>() })
        val uncataloguedGame = PcGame(
            id = "steam_999999",
            title = "Some Unknown Adventure Game",
            platform = GamePlatform.STEAM,
        )

        val offlineInfo = GameInfo(modes = listOf(GameModes.SINGLEPLAYER))
        assertIs<GameNetworkSupport.OfflineSingleplayer>(resolver.resolve(uncataloguedGame, offlineInfo))

        val onlineInfo = GameInfo(modes = listOf(GameModes.SINGLEPLAYER, GameModes.ONLINE_MULTIPLAYER))
        assertIs<GameNetworkSupport.GeneralConnectionOnly>(resolver.resolve(uncataloguedGame, onlineInfo))
    }

    @Test
    fun artworkSourcesExposeLogoCandidatesAndResolverChecksLogoAspect() = runBlocking {
        val dir = tempDir()
        try {
            val steamGame = PcGame(id = "steam_730", title = "CS2", platform = GamePlatform.STEAM)
            val cdnLogos = SteamCdnSource().candidates(steamGame, ArtworkType.LOGO)
                .filterIsInstance<ArtworkCandidate.Remote>()
                .map { it.url }
            assertTrue(cdnLogos.any { it.endsWith("/logo_2x.png") })
            assertTrue(cdnLogos.any { it.endsWith("/logo.png") })

            val steamRoot = File(dir, "Steam")
            val libraryCache = File(steamRoot, "appcache/librarycache/730/hash1").apply { mkdirs() }
            val localLogo = File(libraryCache, "logo_2x.png").apply { writeBytes(fakePng(600, 300)) }
            val localCandidates = SteamLibraryCacheSource { steamRoot }.candidates(steamGame, ArtworkType.LOGO)
                .filterIsInstance<ArtworkCandidate.LocalFile>()
            assertTrue(localCandidates.any { it.path.toFile() == localLogo })

            val epicDataDir = File(dir, "EpicData")
            File(epicDataDir, "Catalog").mkdirs()
            val epicCatalogJson = """[{"id":"item1","title":"Alan Wake","keyImages":[{"type":"DieselGameBoxLogo","url":"https://cdn.example/aw-logo.png"}]}]"""
            File(epicDataDir, "Catalog/catcache.bin").writeBytes(
                Base64.getEncoder().encode(epicCatalogJson.toByteArray(Charsets.UTF_8)),
            )
            val epicGame = PcGame(id = "epic_aw", title = "Alan Wake", platform = GamePlatform.EPIC_GAMES)
            val epicLogos = EpicCatalogSource { epicDataDir }.candidates(epicGame, ArtworkType.LOGO)
                .filterIsInstance<ArtworkCandidate.Remote>()
            assertEquals(listOf("https://cdn.example/aw-logo.png"), epicLogos.map { it.url })

            val catalogCache = File(dir, "store-catalog.json").apply {
                writeText(
                    """
                    {
                      "Warner.Injustice2_abc": {
                        "title": "Injustice 2",
                        "isGame": true,
                        "logoUrl": "https://store-images.s-microsoft.com/image/logo",
                        "v": 2
                      }
                    }
                    """.trimIndent(),
                )
            }
            val catalog = StoreCatalog(cacheFile = catalogCache, enabled = { false })
            val xboxGame = PcGame(id = "xbox_Warner.Injustice2_abc", title = "Injustice 2", platform = GamePlatform.XBOX)
            val xboxLogos = StoreCatalogArtSource(catalog).candidates(xboxGame, ArtworkType.LOGO)
                .filterIsInstance<ArtworkCandidate.Remote>()
            assertEquals(listOf("https://store-images.s-microsoft.com/image/logo"), xboxLogos.map { it.url })

            val cache = ArtworkDiskCache(File(dir, "art-cache").toPath())
            val resolver = GameArtworkResolver(
                localSources = emptyList(),
                remoteSources = listOf(
                    object : ArtworkSource {
                        override fun candidates(game: PcGame, type: ArtworkType) = listOf(
                            ArtworkCandidate.Remote("https://example.test/tall.png"),
                            ArtworkCandidate.Remote("https://example.test/logo.png"),
                        )
                    },
                ),
                cache = cache,
                fetcher = object : ArtworkFetcher {
                    override fun fetch(url: String): FetchResult =
                        if (url.endsWith("tall.png")) FetchResult.Bytes(fakePng(200, 600))
                        else FetchResult.Bytes(fakePng(600, 300))
                },
            )
            val resolved = resolver.resolve(steamGame, ArtworkType.LOGO)
            val available = assertIs<ArtworkResult.Available>(resolved)
            assertTrue(Files.isRegularFile(available.path))
        } finally {
            dir.deleteRecursively()
        }
    }

    @Test
    fun gameInfoServiceAndStoreCatalogParseExtendedMetadata() = runBlocking {
        val dir = tempDir()
        try {
            val steamBody = """
                {
                  "730": {
                    "success": true,
                    "data": {
                      "type": "game",
                      "short_description": "Tactical shooter.",
                      "developers": ["Valve"],
                      "publishers": ["Valve"],
                      "release_date": {"coming_soon": false, "date": "21 ago. 2012"},
                      "genres": [{"description": "Ação"}],
                      "categories": [{"id": 36}, {"id": 23}, {"id": 8}],
                      "controller_support": "full",
                      "metacritic": {"score": 83},
                      "recommendations": {"total": 4200000},
                      "supported_languages": "English<strong>*</strong>, Português (Brasil), Spanish",
                      "pc_requirements": {"minimum": "<strong>SO:</strong> Windows 10<br><strong>RAM:</strong> 8 GB"},
                      "screenshots": [
                        {"id": 0, "path_full": "https://cdn.example/s1.jpg"},
                        {"id": 1, "path_full": "https://cdn.example/s2.jpg"}
                      ]
                    }
                  }
                }
            """.trimIndent()

            val parsedSteam = GameInfoService.parseSteam(steamBody, "730")
            assertNotNull(parsedSteam)
            assertEquals("full", parsedSteam.controllerSupport)
            assertEquals(83, parsedSteam.metacriticScore)
            assertEquals(4_200_000, parsedSteam.recommendationsTotal)
            assertEquals(true, parsedSteam.hasCloudSaves)
            assertEquals("VAC", parsedSteam.antiCheat)
            assertEquals(true, parsedSteam.hasPtBr)
            assertTrue(parsedSteam.pcMinimumRequirements?.contains("Windows 10") == true)
            assertEquals(listOf("https://cdn.example/s1.jpg", "https://cdn.example/s2.jpg"), parsedSteam.storeScreenshots)

            val service = GameInfoService(
                cacheDir = File(dir, "info-cache"),
                enabled = { true },
                epic = EpicCatalogSource { null },
                store = StoreCatalog(File(dir, "store-empty.json"), enabled = { false }),
                fetcher = InfoFetcher { InfoFetch.Body(steamBody) },
            )
            val resolved = service.resolve(PcGame(id = "steam_730", title = "CS2", platform = GamePlatform.STEAM))
            assertEquals(parsedSteam, resolved)

            val xboxBody = """
                {
                  "Products": [{
                    "ProductType": "Game",
                    "Properties": {
                      "Attributes": [
                        {"Name": "SinglePlayer"},
                        {"Name": "XblCloudSaves"},
                        {"Name": "FullControllerSupport"},
                        {"Name": "CapabilityXboxLive"}
                      ]
                    },
                    "LocalizedProperties": [{
                      "ProductTitle": "Halo Infinite",
                      "DeveloperName": "343 Industries",
                      "PublisherName": "Xbox Game Studios",
                      "Images": [
                        {"ImagePurpose": "Poster", "Width": 720, "Height": 1080, "Uri": "//store-images.s-microsoft.com/poster"},
                        {"ImagePurpose": "Logo", "Width": 600, "Height": 200, "Uri": "//store-images.s-microsoft.com/logo"},
                        {"ImagePurpose": "Screenshot", "Width": 1920, "Height": 1080, "Uri": "//store-images.s-microsoft.com/shot1"}
                      ]
                    }]
                  }]
                }
            """.trimIndent()
            val product = StoreCatalog.parseProduct(xboxBody)
            assertNotNull(product)
            assertEquals("https://store-images.s-microsoft.com/logo", product.logoUrl)
            assertEquals(true, product.info?.hasCloudSaves)
            assertEquals(listOf("https://store-images.s-microsoft.com/shot1"), product.info?.storeScreenshots)
        } finally {
            dir.deleteRecursively()
        }
    }
}
