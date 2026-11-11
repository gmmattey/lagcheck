package com.lagcheck.desktop.library.scanner

import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import java.io.File

/**
 * Scanner de bibliotecas da Steam.
 * Lê libraryfolders.vdf e os manifestos appmanifest_*.acf em todas as pastas de biblioteca.
 */
class SteamScanner(private val customSteamPath: File? = null) : LibraryScanner {
    override val name: String = "Steam"

    override fun scan(): List<PcGame> {
        val root = customSteamPath ?: detectSteamRoot() ?: return emptyList()
        if (!root.exists() || !root.isDirectory) return emptyList()

        val libraryFolders = findLibraryFolders(root)
        val games = mutableListOf<PcGame>()

        for (folder in libraryFolders) {
            val steamApps = File(folder, "steamapps")
            if (!steamApps.exists() || !steamApps.isDirectory) continue

            val manifests = steamApps.listFiles { f ->
                f.isFile && f.name.startsWith("appmanifest_") && f.name.endsWith(".acf")
            } ?: continue

            for (manifest in manifests) {
                parseManifest(manifest, folder)?.let { games.add(it) }
            }
        }

        return games
    }

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

    internal fun findLibraryFolders(steamRoot: File): List<File> {
        val folders = mutableListOf(steamRoot)
        val vdfFile = File(File(steamRoot, "steamapps"), "libraryfolders.vdf")
        if (!vdfFile.exists()) return folders

        try {
            val content = vdfFile.readText()
            // Formato novo do VDF: "path" "D:\\SteamLibrary"
            val pathMatches = Regex(""""path"\s+"([^"]+)"""").findAll(content)
            for (m in pathMatches) {
                val p = m.groupValues[1].replace("\\\\", "\\")
                val f = File(p)
                if (f.exists() && f.isDirectory && !folders.contains(f)) {
                    folders.add(f)
                }
            }
            // Formato legado do VDF: "1" "D:\\SteamLibrary"
            val legacyMatches = Regex(""""\d+"\s+"([^"]+)"""").findAll(content)
            for (m in legacyMatches) {
                val p = m.groupValues[1].replace("\\\\", "\\")
                val f = File(p)
                if (f.exists() && f.isDirectory && !folders.contains(f)) {
                    folders.add(f)
                }
            }
        } catch (_: Exception) {
            // Em caso de erro, usa ao menos a pasta raiz
        }

        return folders
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
            if (name.startsWith("Steamworks") || name.startsWith("Proton") || name.startsWith("Steam Linux")) {
                return null
            }

            // Flag 4 = Fully Installed (ou flag 6 = update required but installed)
            val isInstalled = (stateFlags and 4) != 0 || stateFlags == 4

            val fullInstallPath = installDir?.let { File(File(libraryRoot, "steamapps/common"), it).absolutePath }
            val network = resolveNetworkSupport(appId, name)

            PcGame(
                id = "steam_$appId",
                title = name,
                platform = GamePlatform.STEAM,
                installDirectory = fullInstallPath,
                launchUri = "steam://rungameid/$appId",
                isInstalled = isInstalled,
                networkSupport = network,
                tags = listOf("Steam", "PC")
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun resolveNetworkSupport(appId: String, name: String): GameNetworkSupport {
        val lower = name.lowercase()
        return when {
            lower.contains("counter-strike") || appId == "730" ->
                GameNetworkSupport.LagcheckSupported("cs2", "São Paulo, BR")
            lower.contains("dota 2") || appId == "570" ->
                GameNetworkSupport.LagcheckSupported("dota2", "São Paulo, BR")
            lower.contains("apex legends") || appId == "1172470" ->
                GameNetworkSupport.LagcheckSupported("apex-legends", "São Paulo, BR")
            lower.contains("warzone") || lower.contains("call of duty") || appId == "1938090" ->
                GameNetworkSupport.LagcheckSupported("warzone", "São Paulo, BR")
            lower.contains("dead by daylight") || appId == "381210" ->
                GameNetworkSupport.LagcheckSupported("dead-by-daylight", "São Paulo, BR")
            lower.contains("for honor") || appId == "304390" ->
                GameNetworkSupport.LagcheckSupported("for-honor", "São Paulo, BR")
            lower.contains("rust") || appId == "252490" ->
                GameNetworkSupport.LagcheckSupported("rust", "São Paulo, BR")
            lower.contains("darktide") || appId == "1361210" ->
                GameNetworkSupport.LagcheckSupported("warhammer-darktide", "São Paulo, BR")
            lower.contains("palworld") || appId == "1623730" ->
                GameNetworkSupport.LagcheckSupported("palworld", "São Paulo, BR")
            lower.contains("cities: skylines") || lower.contains("cities skylines") ->
                GameNetworkSupport.OfflineSingleplayer("Simulação urbana solo")
            else ->
                GameNetworkSupport.GeneralConnectionOnly("Testar conexão geral")
        }
    }
}
