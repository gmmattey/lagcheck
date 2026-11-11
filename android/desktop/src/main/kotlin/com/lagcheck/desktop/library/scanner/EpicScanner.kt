package com.lagcheck.desktop.library.scanner

import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import java.io.File

/**
 * Scanner de bibliotecas da Epic Games Store.
 * Lê os arquivos .item em %ProgramData%\Epic\EpicGamesLauncher\Data\Manifests\
 */
class EpicScanner(private val customManifestsPath: File? = null) : LibraryScanner {
    override val name: String = "Epic Games"

    override fun scan(): List<PcGame> {
        val manifestsDir = customManifestsPath ?: detectManifestsDir() ?: return emptyList()
        if (!manifestsDir.exists() || !manifestsDir.isDirectory) return emptyList()

        val items = manifestsDir.listFiles { f -> f.isFile && f.name.endsWith(".item") } ?: return emptyList()
        val games = mutableListOf<PcGame>()

        for (item in items) {
            parseItem(item)?.let { games.add(it) }
        }

        return games
    }

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
            if (displayName.contains("Unreal Engine") || displayName.contains("Prerequisites")) {
                return null
            }

            val fullExecutable = if (installLocation != null && launchExe != null) {
                File(installLocation, launchExe).absolutePath
            } else null

            val network = resolveNetworkSupport(displayName, appName)

            PcGame(
                id = "epic_$appName",
                title = displayName,
                platform = GamePlatform.EPIC_GAMES,
                installDirectory = installLocation,
                executablePath = fullExecutable,
                launchUri = "com.epicgames.launcher://apps/$appName?action=launch",
                isInstalled = true,
                networkSupport = network,
                tags = listOf("Epic Games", "PC")
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun resolveNetworkSupport(name: String, appName: String): GameNetworkSupport {
        val lower = name.lowercase()
        return when {
            lower.contains("fortnite") || appName.lowercase() == "fortnite" ->
                GameNetworkSupport.LagcheckSupported("fortnite", "São Paulo, BR")
            lower.contains("rocket league") ->
                GameNetworkSupport.LagcheckSupported("rocket-league", "São Paulo, BR")
            lower.contains("fall guys") || appName == "Sugar" ->
                GameNetworkSupport.GeneralConnectionOnly("Party game via Epic Online Services")
            else ->
                GameNetworkSupport.GeneralConnectionOnly("Testar conexão geral")
        }
    }
}
