package com.lagcheck.desktop.library.scanner

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import java.io.File

/**
 * Scanner de bibliotecas da Steam.
 * Lê libraryfolders.vdf e os manifestos appmanifest_*.acf em todas as pastas de biblioteca.
 */
class SteamScanner(private val customSteamPath: File? = null) : LibraryScanner {
    override val name: String = "Steam"

    override val platform: GamePlatform = GamePlatform.STEAM

    override fun scan(): ScanResult {
        val root = customSteamPath ?: detectSteamRoot() ?: return ScanResult.Unavailable("Steam não encontrada")
        if (!root.exists() || !root.isDirectory) return ScanResult.Unavailable("Pasta da Steam inacessível")

        val libraries = readLibraryFolders(root)
        val games = mutableListOf<PcGame>()
        val unreadable = mutableSetOf<String>()

        for (folder in libraries.existing) {
            val steamApps = File(folder, "steamapps")
            if (!steamApps.exists() || !steamApps.isDirectory) continue

            val manifests = steamApps.listFiles { f ->
                f.isFile && f.name.startsWith("appmanifest_") && f.name.endsWith(".acf")
            } ?: continue

            for (manifest in manifests) {
                val game = parseManifest(manifest, folder)
                if (game != null) {
                    games.add(game)
                } else {
                    // Ferramenta filtrada de propósito não conta; arquivo ilegível sim.
                    val id = manifest.name.removePrefix("appmanifest_").removeSuffix(".acf")
                    if (id.all { it.isDigit() } && !isIntentionallySkipped(manifest)) unreadable.add("steam_$id")
                }
            }
        }

        return ScanResult.Found(
            games = games,
            unreachableRoots = libraries.missing.map { it.path },
            unreadableIds = unreadable,
        )
    }

    private fun isIntentionallySkipped(acf: File): Boolean = runCatching {
        val name = Regex(""""name"\s+"([^"]+)"""").find(acf.readText())?.groupValues?.get(1) ?: return@runCatching false
        isTool(name)
    }.getOrDefault(false)

    private fun isTool(name: String) = name.startsWith("Steamworks") || name.startsWith("Proton") || name.startsWith("Steam Linux")

    private fun detectSteamRoot(): File? {
        val os = System.getProperty("os.name").lowercase()
        if (os.contains("win")) {
            // 1. Tentar ler do registro do Windows
            readWindowsRegistrySteamPath()?.let { path ->
                val f = File(path)
                if (f.exists()) return f
            }
            // 2. Caminhos padrão do Windows
            val defaultWinPaths = listOf(
                File("C:\\Program Files (x86)\\Steam"),
                File("C:\\Program Files\\Steam"),
                File("D:\\Steam"),
                File("D:\\SteamLibrary")
            )
            for (p in defaultWinPaths) {
                if (p.exists() && p.isDirectory) return p
            }
        } else if (os.contains("mac")) {
            val macPath = File(System.getProperty("user.home"), "Library/Application Support/Steam")
            if (macPath.exists()) return macPath
        } else {
            val linuxPath = File(System.getProperty("user.home"), ".steam/steam")
            if (linuxPath.exists()) return linuxPath
        }
        return null
    }

    private fun readWindowsRegistrySteamPath(): String? {
        return try {
            val process = ProcessBuilder("reg", "query", "HKCU\\Software\\Valve\\Steam", "/v", "SteamPath").start()
            val output = process.inputStream.bufferedReader().readText()
            process.waitFor()
            val match = Regex("""SteamPath\s+REG_SZ\s+(.+)""").find(output)
            match?.groupValues?.get(1)?.trim()?.replace('/', File.separatorChar)
        } catch (_: Exception) {
            null
        }
    }

    internal data class LibraryFolders(val existing: List<File>, val missing: List<File>)

    internal fun findLibraryFolders(steamRoot: File): List<File> = readLibraryFolders(steamRoot).existing

    /** Separa as bibliotecas acessíveis das listadas no VDF que não existem agora (ex.: disco externo). */
    internal fun readLibraryFolders(steamRoot: File): LibraryFolders {
        val existing = mutableListOf(steamRoot)
        val missing = mutableListOf<File>()
        val vdfFile = File(File(steamRoot, "steamapps"), "libraryfolders.vdf")
        if (!vdfFile.exists()) return LibraryFolders(existing, missing)

        try {
            val content = vdfFile.readText()
            // Formato novo do VDF: "path" "D:\\SteamLibrary"; formato legado: "1" "D:\\SteamLibrary"
            val listed = (Regex(""""path"\s+"([^"]+)"""").findAll(content) + Regex(""""\d+"\s+"([^"]+)"""").findAll(content))
                .map { it.groupValues[1] }
                // O formato legado também casa linhas "appid" "tamanho"; só valores com cara de caminho contam.
                .filter { it.length > 2 && (it[1] == ':' || it.startsWith("/") || it.startsWith("\\\\")) }
                .map { File(it.replace("\\\\", "\\")) }
            for (f in listed) {
                if (f.exists() && f.isDirectory) {
                    if (!existing.contains(f)) existing.add(f)
                } else if (!missing.contains(f)) {
                    missing.add(f)
                }
            }
        } catch (_: Exception) {
            // Em caso de erro, usa ao menos a pasta raiz
        }

        return LibraryFolders(existing, missing)
    }

    internal fun parseManifest(acfFile: File, libraryRoot: File): PcGame? {
        return try {
            val content = acfFile.readText()
            val appId = Regex(""""appid"\s+"(\d+)"""").find(content)?.groupValues?.get(1) ?: return null
            val name = Regex(""""name"\s+"([^"]+)"""").find(content)?.groupValues?.get(1) ?: return null
            val installDir = Regex(""""installdir"\s+"([^"]+)"""").find(content)?.groupValues?.get(1)
            val stateFlagsStr = Regex(""""StateFlags"\s+"(\d+)"""").find(content)?.groupValues?.get(1)
            val stateFlags = stateFlagsStr?.toIntOrNull() ?: 4

            // Filtrar ferramentas da Steam e runtimes
            if (isTool(name)) return null

            // Flag 4 = Fully Installed (ou flag 6 = update required but installed)
            val isInstalled = (stateFlags and 4) != 0 || stateFlags == 4

            val fullInstallPath = installDir?.let { File(File(libraryRoot, "steamapps/common"), it).absolutePath }

            PcGame(
                id = "steam_$appId",
                title = name,
                platform = GamePlatform.STEAM,
                installDirectory = fullInstallPath,
                launchUri = "steam://rungameid/$appId",
                isInstalled = isInstalled,
                tags = listOf("Steam", "PC")
            )
        } catch (_: Exception) {
            null
        }
    }
}
