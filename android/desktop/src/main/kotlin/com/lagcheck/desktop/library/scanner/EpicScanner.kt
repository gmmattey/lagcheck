package com.lagcheck.desktop.library.scanner

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import java.io.File

/**
 * Scanner de bibliotecas da Epic Games Store.
 * Lê os arquivos .item em %ProgramData%\Epic\EpicGamesLauncher\Data\Manifests\
 */
class EpicScanner(private val customManifestsPath: File? = null) : LibraryScanner {
    override val name: String = "Epic Games"

    override val platform: GamePlatform = GamePlatform.EPIC_GAMES

    override fun scan(): ScanResult {
        val manifestsDir = customManifestsPath ?: detectManifestsDir() ?: return ScanResult.Unavailable("Epic Games não encontrada")
        if (!manifestsDir.exists() || !manifestsDir.isDirectory) return ScanResult.Unavailable("Pasta da Epic inacessível")

        val items = manifestsDir.listFiles { f -> f.isFile && f.name.endsWith(".item") }
            ?: return ScanResult.Unavailable("Não foi possível listar os jogos da Epic")
        val games = mutableListOf<PcGame>()
        var unreadable = false

        for (item in items) {
            val game = parseItem(item)
            if (game != null) games.add(game) else if (!isIntentionallySkipped(item)) unreadable = true
        }

        // O nome do arquivo .item é um hash: não dá para saber a qual jogo a entrada ilegível pertencia.
        return ScanResult.Found(games = games, incomplete = unreadable)
    }

    private fun isIntentionallySkipped(item: File): Boolean = runCatching {
        val name = Regex(""""DisplayName"\s*:\s*"([^"]+)"""").find(item.readText())?.groupValues?.get(1) ?: return@runCatching false
        isTool(name)
    }.getOrDefault(false)

    private fun isTool(displayName: String) = displayName.contains("Unreal Engine") || displayName.contains("Prerequisites")

    private fun detectManifestsDir(): File? {
        val os = System.getProperty("os.name").lowercase()
        if (os.contains("win")) {
            val programData = System.getenv("ProgramData") ?: "C:\\ProgramData"
            val dir = File(programData, "Epic\\EpicGamesLauncher\\Data\\Manifests")
            if (dir.exists()) return dir
        } else if (os.contains("mac")) {
            val macDir = File(System.getProperty("user.home"), "Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests")
            if (macDir.exists()) return macDir
        }
        return null
    }

    internal fun parseItem(itemFile: File): PcGame? {
        return try {
            val content = itemFile.readText()
            val displayName = Regex(""""DisplayName"\s*:\s*"([^"]+)"""").find(content)?.groupValues?.get(1) ?: return null
            val appName = Regex(""""AppName"\s*:\s*"([^"]+)"""").find(content)?.groupValues?.get(1) ?: return null
            val installLocation = Regex(""""InstallLocation"\s*:\s*"([^"]+)"""").find(content)?.groupValues?.get(1)?.replace("\\\\", "\\")
            val launchExe = Regex(""""LaunchExecutable"\s*:\s*"([^"]+)"""").find(content)?.groupValues?.get(1)

            // Filtrar itens de sistema ou ferramentas
            if (isTool(displayName)) return null

            val fullExecutable = if (installLocation != null && launchExe != null) {
                File(installLocation, launchExe).absolutePath
            } else null

            PcGame(
                id = "epic_$appName",
                title = displayName,
                platform = GamePlatform.EPIC_GAMES,
                installDirectory = installLocation,
                executablePath = fullExecutable,
                launchUri = "com.epicgames.launcher://apps/$appName?action=launch",
                isInstalled = true,
                tags = listOf("Epic Games", "PC")
            )
        } catch (_: Exception) {
            null
        }
    }
}
