package com.lagcheck.desktop.library.scanner

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.GameUpdateState
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
        val userStats = readUserAppStats(root)
        val games = mutableListOf<PcGame>()
        val unreadable = mutableSetOf<String>()

        for (folder in libraries.existing) {
            val steamApps = File(folder, "steamapps")
            if (!steamApps.exists() || !steamApps.isDirectory) continue

            val manifests = steamApps.listFiles { f ->
                f.isFile && f.name.startsWith("appmanifest_") && f.name.endsWith(".acf")
            } ?: continue

            for (manifest in manifests) {
                val game = parseManifest(manifest, folder, userStats)
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

    internal data class SteamUserAppStats(val playTimeMinutes: Long, val lastPlayedEpochMs: Long?)

    internal fun readUserAppStats(steamRoot: File): Map<String, SteamUserAppStats> {
        val userdata = File(steamRoot, "userdata")
        if (!userdata.isDirectory) return emptyMap()
        val accounts = userdata.listFiles { f -> f.isDirectory }.orEmpty()
        if (accounts.isEmpty()) return emptyMap()
        val merged = HashMap<String, SteamUserAppStats>()
        for (account in accounts) {
            val vdf = File(account, "config/localconfig.vdf")
            if (!vdf.isFile) continue
            val content = runCatching { vdf.readText() }.getOrNull() ?: continue
            for ((appId, stats) in parseLocalConfigApps(content)) {
                val prev = merged[appId]
                merged[appId] = if (prev == null) {
                    stats
                } else {
                    SteamUserAppStats(
                        playTimeMinutes = maxOf(prev.playTimeMinutes, stats.playTimeMinutes),
                        lastPlayedEpochMs = listOfNotNull(prev.lastPlayedEpochMs, stats.lastPlayedEpochMs).maxOrNull(),
                    )
                }
            }
        }
        return merged
    }

    private fun isIntentionallySkipped(acf: File): Boolean = runCatching {
        val name = Regex(""""name"\s+"([^"]+)"""").find(acf.readText())?.groupValues?.get(1) ?: return@runCatching false
        isTool(name)
    }.getOrDefault(false)

    private fun isTool(name: String) = name.startsWith("Steamworks") || name.startsWith("Proton") || name.startsWith("Steam Linux")

    /** Pasta de instalação da Steam neste PC, ou null. Usado também para achar o cache de imagens do cliente. */
    fun detectSteamRoot(): File? {
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

    internal fun parseManifest(
        acfFile: File,
        libraryRoot: File,
        userStats: Map<String, SteamUserAppStats> = emptyMap(),
    ): PcGame? {
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

            val sizeOnDiskBytes = Regex(""""SizeOnDisk"\s+"(\d+)"""").find(content)?.groupValues?.get(1)?.toLongOrNull()
                ?.takeIf { it > 0L }
            val bytesToDownload = Regex(""""BytesToDownload"\s+"(\d+)"""").find(content)?.groupValues?.get(1)?.toLongOrNull()
                ?.takeIf { it >= 0L }
            val bytesDownloaded = Regex(""""BytesDownloaded"\s+"(\d+)"""").find(content)?.groupValues?.get(1)?.toLongOrNull()
                ?.takeIf { it >= 0L }

            val hasIncompleteTransfer = bytesToDownload != null && bytesToDownload > 0L && (bytesDownloaded ?: 0L) < bytesToDownload
            val updateState = when {
                (stateFlags and (256 or 512 or 1024 or 2048)) != 0 -> GameUpdateState.DOWNLOADING
                (stateFlags and 2) != 0 || hasIncompleteTransfer -> GameUpdateState.UPDATE_REQUIRED
                else -> GameUpdateState.READY
            }

            val fullInstallPath = installDir?.let { File(File(libraryRoot, "steamapps/common"), it).absolutePath }

            // O próprio cliente Steam registra o último uso em segundos; 0 significa "nunca jogado" e não vira data.
            val acfLastPlayedMs = Regex(""""LastPlayed"\s+"(\d+)"""").find(content)?.groupValues?.get(1)?.toLongOrNull()
                ?.takeIf { it > 0 }?.let { it * 1000 }
            val stats = userStats[appId]
            val lastPlayedMs = acfLastPlayedMs ?: stats?.lastPlayedEpochMs

            PcGame(
                id = "steam_$appId",
                title = name,
                platform = GamePlatform.STEAM,
                installDirectory = fullInstallPath,
                launchUri = "steam://rungameid/$appId",
                isInstalled = isInstalled,
                playTimeMinutes = stats?.playTimeMinutes ?: 0L,
                lastPlayedEpochMs = lastPlayedMs,
                tags = listOf("Steam", "PC"),
                sizeOnDiskBytes = sizeOnDiskBytes,
                updateState = updateState,
                downloadBytesCompleted = if (updateState != GameUpdateState.READY && bytesToDownload != null && bytesToDownload > 0L) bytesDownloaded else null,
                downloadBytesTotal = if (updateState != GameUpdateState.READY && bytesToDownload != null && bytesToDownload > 0L) bytesToDownload else null,
            )
        } catch (_: Exception) {
            null
        }
    }

    internal companion object {
        private val PLAYTIME_REGEX = Regex(""""Playtime"\s+"(\d+)"""", RegexOption.IGNORE_CASE)
        private val LAST_PLAYED_REGEX = Regex(""""LastPlayed"\s+"(\d+)"""", RegexOption.IGNORE_CASE)
        private val APPS_HEADER_REGEX = Regex(""""apps"\s*\{""", RegexOption.IGNORE_CASE)

        /**
         * Extrai `Playtime` (em minutos) e `LastPlayed` por `appId` a partir de `localconfig.vdf`.
         * Varre apenas os blocos com chave numérica dentro de `"apps" { ... }`.
         */
        internal fun parseLocalConfigApps(content: String): Map<String, SteamUserAppStats> {
            val result = HashMap<String, SteamUserAppStats>()
            for (header in APPS_HEADER_REGEX.findAll(content)) {
                var pos = header.range.last + 1 // logo após '{' de "apps"
                var appsDepth = 1
                while (pos < content.length && appsDepth > 0) {
                    val c = content[pos]
                    when {
                        c == '"' -> {
                            val keyResult = readQuoted(content, pos) ?: break
                            val key = keyResult.first
                            pos = keyResult.second
                            val afterKey = skipWhitespace(content, pos)
                            if (appsDepth == 1 && afterKey < content.length && content[afterKey] == '{') {
                                val blockEnd = findMatchingBrace(content, afterKey + 1) ?: break
                                if (key.isNotEmpty() && key.all(Char::isDigit)) {
                                    val block = content.substring(afterKey + 1, blockEnd)
                                    val playtime = PLAYTIME_REGEX.find(block)?.groupValues?.get(1)?.toLongOrNull() ?: 0L
                                    val lastPlayed = LAST_PLAYED_REGEX.find(block)?.groupValues?.get(1)?.toLongOrNull()
                                        ?.takeIf { it > 0L }?.let { it * 1000L }
                                    if (playtime > 0L || lastPlayed != null) {
                                        val prev = result[key]
                                        result[key] = if (prev == null) {
                                            SteamUserAppStats(playtime, lastPlayed)
                                        } else {
                                            SteamUserAppStats(
                                                playTimeMinutes = maxOf(prev.playTimeMinutes, playtime),
                                                lastPlayedEpochMs = listOfNotNull(prev.lastPlayedEpochMs, lastPlayed).maxOrNull(),
                                            )
                                        }
                                    }
                                }
                                pos = blockEnd + 1
                            }
                        }
                        c == '{' -> { appsDepth++; pos++ }
                        c == '}' -> { appsDepth--; pos++ }
                        else -> pos++
                    }
                }
            }
            return result
        }

        private fun skipWhitespace(text: String, start: Int): Int {
            var i = start
            while (i < text.length && text[i].isWhitespace()) i++
            return i
        }

        private fun readQuoted(text: String, openQuote: Int): Pair<String, Int>? {
            val sb = StringBuilder()
            var i = openQuote + 1
            while (i < text.length) {
                val ch = text[i]
                if (ch == '\\' && i + 1 < text.length) {
                    sb.append(text[i + 1])
                    i += 2
                } else if (ch == '"') {
                    return sb.toString() to (i + 1)
                } else {
                    sb.append(ch)
                    i++
                }
            }
            return null
        }

        private fun findMatchingBrace(text: String, afterOpenBrace: Int): Int? {
            var depth = 1
            var i = afterOpenBrace
            while (i < text.length) {
                when (text[i]) {
                    '"' -> i = readQuoted(text, i)?.second ?: return null
                    '{' -> { depth++; i++ }
                    '}' -> {
                        depth--
                        if (depth == 0) return i
                        i++
                    }
                    else -> i++
                }
            }
            return null
        }
    }
}
