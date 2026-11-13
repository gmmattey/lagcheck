package com.lagcheck.desktop.library.scanner

import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import org.w3c.dom.Document
import org.w3c.dom.Element
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import javax.xml.parsers.DocumentBuilderFactory

/** Pacote instalado do Windows (UWP/GDK) como o `Get-AppxPackage` o descreve. */
data class InstalledPackage(val packageFamilyName: String, val installLocation: String, val signatureKind: String? = null)

/**
 * Jogos do Xbox / PC Game Pass / Microsoft Store que estão instalados neste PC.
 *
 * O Windows não tem uma pasta de manifestos como a Steam ou a Epic: os jogos são pacotes. A varredura lista os
 * pacotes instalados do usuário e só aceita os que trazem `MicrosoftGame.config`, o arquivo que todo jogo GDK
 * carrega (aplicativos comuns não o têm). Tudo é lido localmente; nada é consultado na internet.
 * Jogos UWP antigos, sem esse arquivo, não são identificáveis como jogo sem a conta Xbox e ficam de fora.
 */
class XboxScanner(
    private val packages: () -> List<InstalledPackage>? = ::queryInstalledPackages,
    private val store: StoreProductLookup? = null,
    private val maxStoreLookups: Int = 80,
) : LibraryScanner {
    override val name: String = "Xbox"
    override val platform: GamePlatform = GamePlatform.XBOX

    override fun scan(): ScanResult {
        val installed = packages() ?: return ScanResult.Unavailable("Não foi possível listar os pacotes do Windows")
        val games = mutableListOf<PcGame>()
        val candidates = mutableListOf<Pair<InstalledPackage, String>>()
        for (pkg in installed) {
            val game = runCatching { parsePackage(pkg) }.getOrNull()
            if (game != null) {
                games += game
            } else if (store != null) {
                storeCandidateAppId(pkg)?.let { candidates += pkg to it }
            }
        }

        // Jogos da Microsoft Store sem MicrosoftGame.config: só o catálogo da loja diz se o pacote é jogo.
        var incomplete = false
        if (store != null && candidates.isNotEmpty()) {
            val pool = Executors.newFixedThreadPool(6)
            try {
                val lookups = candidates.take(maxStoreLookups).map { (pkg, appId) ->
                    Triple(pkg, appId, pool.submit<StoreProduct?> { store.lookup(pkg.packageFamilyName) })
                }
                for ((pkg, appId, future) in lookups) {
                    val product = runCatching { future.get(40, TimeUnit.SECONDS) }.getOrNull()
                    if (product == null) incomplete = true
                    else if (product.isGame) games += storeGame(pkg, appId, product)
                }
                if (candidates.size > maxStoreLookups) incomplete = true
            } finally {
                pool.shutdownNow()
            }
        }
        return ScanResult.Found(games = games.distinctBy { it.id }, incomplete = incomplete)
    }

    private fun storeGame(pkg: InstalledPackage, appId: String, product: StoreProduct) = PcGame(
        id = "xbox_${pkg.packageFamilyName}",
        title = product.title,
        platform = GamePlatform.XBOX,
        installDirectory = pkg.installLocation,
        launchUri = "shell:AppsFolder\\${pkg.packageFamilyName}!$appId",
        isInstalled = true,
        tags = listOf("Xbox / PC", "PC"),
    )

    /**
     * Id do aplicativo se o pacote puder ser um jogo da loja: assinado pela Microsoft Store, com aplicativo visível
     * no menu Iniciar e que não seja componente do sistema. Qualquer outro pacote nem é consultado.
     */
    internal fun storeCandidateAppId(pkg: InstalledPackage): String? {
        if (!pkg.signatureKind.equals("Store", ignoreCase = true)) return null
        val name = pkg.packageFamilyName.substringBefore('_')
        if (SYSTEM_PREFIXES.any { name.startsWith(it, ignoreCase = true) }) return null
        val manifest = XboxPackageFiles.parse(File(pkg.installLocation, "AppxManifest.xml")) ?: return null
        val applications = manifest.getElementsByTagName("Application")
        for (i in 0 until applications.length) {
            val app = applications.item(i) as? Element ?: continue
            val id = app.getAttribute("Id").takeIf { it.isNotBlank() } ?: continue
            val nodes = app.getElementsByTagName("*")
            val visuals = (0 until nodes.length).mapNotNull { nodes.item(it) as? Element }.firstOrNull { it.tagName.endsWith("VisualElements") }
            if (visuals != null && visuals.getAttribute("AppListEntry").equals("none", ignoreCase = true)) continue
            return id
        }
        return null
    }

    internal fun parsePackage(pkg: InstalledPackage): PcGame? {
        val root = File(pkg.installLocation)
        val configFile = XboxPackageFiles.configFile(root) ?: return null
        val config = XboxPackageFiles.parse(configFile) ?: return null
        val manifest = XboxPackageFiles.parse(File(configFile.parentFile, "appxmanifest.xml"))
        val visuals = config.documentElement.firstChild("ShellVisuals")

        val title = listOf(
            visuals?.getAttribute("DefaultDisplayName"),
            manifest?.getElementsByTagName("DisplayName")?.item(0)?.textContent,
        ).firstNotNullOfOrNull { it?.trim()?.takeIf { text -> text.isNotEmpty() && !text.startsWith("ms-resource", ignoreCase = true) } }
            ?: fallbackTitle(pkg.packageFamilyName)

        val executable = config.documentElement.firstChild("ExecutableList")?.firstChild("Executable")
        val appId = manifest?.getElementsByTagName("Application")?.item(0)?.let { (it as? Element)?.getAttribute("Id") }
            ?.takeIf { it.isNotBlank() }
            ?: executable?.getAttribute("Id")?.takeIf { it.isNotBlank() }
            ?: "Game"
        val exePath = executable?.getAttribute("Name")?.takeIf { it.isNotBlank() }
            ?.let { File(configFile.parentFile, it).takeIf(File::isFile)?.absolutePath }

        return PcGame(
            id = "xbox_${pkg.packageFamilyName}",
            title = title,
            platform = GamePlatform.XBOX,
            installDirectory = configFile.parentFile.absolutePath,
            executablePath = exePath,
            launchUri = "shell:AppsFolder\\${pkg.packageFamilyName}!$appId",
            isInstalled = true,
            tags = listOf("Xbox / PC", "PC"),
        )
    }

    private fun fallbackTitle(familyName: String): String =
        familyName.substringBefore('_').substringAfter('.').replace(Regex("([a-z])([A-Z])"), "$1 $2")
            .ifBlank { familyName }
}

/** Leitura dos arquivos de um pacote de jogo, compartilhada com a busca de imagens. */
internal object XboxPackageFiles {
    fun configFile(root: File): File? =
        listOf(File(root, "MicrosoftGame.config"), File(root, "Content/MicrosoftGame.config")).firstOrNull(File::isFile)

    fun parse(file: File): Document? = runCatching {
        if (!file.isFile) return@runCatching null
        val factory = DocumentBuilderFactory.newInstance()
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)
        factory.newDocumentBuilder().parse(file)
    }.getOrNull()

    /** Caminhos das imagens declaradas em `ShellVisuals`, na ordem pedida, que existem no disco. */
    fun visuals(installDirectory: String?, vararg attributes: String): List<File> {
        val configFile = installDirectory?.let { configFile(File(it)) ?: configFile(File(it).parentFile ?: return emptyList()) } ?: return emptyList()
        val visuals = parse(configFile)?.documentElement?.firstChild("ShellVisuals") ?: return emptyList()
        return attributes.mapNotNull { attribute ->
            visuals.getAttribute(attribute).takeIf { it.isNotBlank() }
                ?.let { File(configFile.parentFile, it.replace('\\', File.separatorChar)) }?.takeIf(File::isFile)
        }
    }
}

internal fun Element.firstChild(tag: String): Element? {
    val nodes = childNodes
    for (i in 0 until nodes.length) {
        val node = nodes.item(i)
        if (node is Element && node.tagName.equals(tag, ignoreCase = true)) return node
    }
    return null
}

private val SYSTEM_PREFIXES = listOf(
    "Microsoft.Windows", "MicrosoftWindows.", "Microsoft.Xbox", "Microsoft.Gaming", "Microsoft.Store", "Microsoft.Bing",
    "Microsoft.Ink", "Microsoft.Language", "Microsoft.Win", "Microsoft.Desktop", "Microsoft.Secure", "Microsoft.Sec",
    "Windows.", "MicrosoftCorporationII.WinApp", "NVIDIA", "Realtek", "Dolby", "Microsoft.UI", "Microsoft.NET", "Microsoft.VCLibs",
)

private const val LIST_PACKAGES_SCRIPT =
    "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" +
        "Get-AppxPackage | Where-Object { -not \$_.IsFramework -and \$_.InstallLocation } | " +
        "ForEach-Object { \$_.PackageFamilyName + '|' + \$_.InstallLocation + '|' + \$_.SignatureKind }"

/** Lista os pacotes instalados do usuário atual. Devolve `null` se o PowerShell não responder a tempo. */
internal fun queryInstalledPackages(): List<InstalledPackage>? {
    if (!System.getProperty("os.name").lowercase().contains("win")) return null
    return try {
        val process = ProcessBuilder("powershell.exe", "-NoProfile", "-NonInteractive", "-Command", LIST_PACKAGES_SCRIPT)
            .redirectErrorStream(false)
            .start()
        process.outputStream.close()
        val output = process.inputStream.readBytes().toString(Charsets.UTF_8)
        if (!process.waitFor(30, TimeUnit.SECONDS)) {
            process.destroyForcibly()
            return null
        }
        parsePackageLines(output)
    } catch (_: Exception) {
        null
    }
}

internal fun parsePackageLines(output: String): List<InstalledPackage> =
    output.lineSequence().mapNotNull { line ->
        val parts = line.trim().trimStart('﻿').split('|')
        if (parts.size >= 2 && parts[0].isNotBlank() && parts[1].isNotBlank()) InstalledPackage(parts[0], parts[1], parts.getOrNull(2)?.takeIf { it.isNotBlank() }) else null
    }.toList()
