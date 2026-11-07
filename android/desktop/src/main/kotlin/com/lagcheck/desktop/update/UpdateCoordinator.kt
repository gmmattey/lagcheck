package com.lagcheck.desktop.update

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import java.io.File
import java.time.Duration
import java.time.Instant
import java.util.Properties

sealed interface UpdateState {
    data object Nenhuma : UpdateState
    data class Disponivel(val release: Release) : UpdateState
    data class Baixando(val release: Release, val received: Long = 0, val total: Long? = null) : UpdateState
    data class Pronta(val release: Release, val installer: File) : UpdateState
    data object Falha : UpdateState
}

class UpdateCoordinator(
    private val source: UpdateSourceConfig = UpdateSourceConfig.current(),
    private val store: UpdateStore = UpdateStore(),
    private val transport: HttpTransport = CachedTransport(JdkTransport(source.allowedHosts, UpdateSource.installedVersion), store)
) {
    var state: UpdateState by mutableStateOf(UpdateState.Nenhuma)
        private set
    var automatic: Boolean by mutableStateOf(store.automatic)
        private set
    val lastChecked: Instant? get() = store.lastChecked

    fun check(force: Boolean = false) {
        if (!source.configured || (!force && !store.canCheck())) return
        val release = feed()?.latest()
        store.markChecked()
        if (release != null && VersionComparer.isNewer(release.version, UpdateSource.installedVersion)) state = UpdateState.Disponivel(release)
        else state = UpdateState.Nenhuma
    }

    fun download(requested: Release? = null) {
        val release = requested ?: (state as? UpdateState.Disponivel)?.release ?: return
        state = UpdateState.Baixando(release)
        val installer = UpdateDownloader(transport, source.allowedHosts).download(release, onProgress = { received, total -> state = UpdateState.Baixando(release, received, total) })
        state = if (installer == null) UpdateState.Falha else UpdateState.Pronta(release, installer)
    }

    fun changeAutomatic(enabled: Boolean) { automatic = enabled; store.automatic = enabled }
    fun dismiss() { state = UpdateState.Nenhuma }
    fun installReady(): Boolean {
        val ready = state as? UpdateState.Pronta ?: return false
        val installer = ready.installer
        if (!UpdateDownloader(transport, source.allowedHosts).matchesChecksum(installer, ready.release.sha256)) return false
        return runCatching { ProcessBuilder(installerCommand(installer)).start(); true }.getOrDefault(false)
    }

    internal fun installerCommand(installer: File): List<String> = if (installer.extension.equals("msi", ignoreCase = true)) {
        listOf("msiexec.exe", "/i", installer.absolutePath)
    } else {
        listOf(installer.absolutePath)
    }

    private fun feed(): ReleaseFeed? = when {
        source.manifestUrl.isNotBlank() -> ManifestReleaseFeed(source.manifestUrl, transport)
        source.githubRepository.isNotBlank() -> GitHubReleaseFeed(source.githubRepository, transport)
        else -> null
    }
}

private class CachedTransport(private val delegate: HttpTransport, private val store: UpdateStore) : HttpTransport {
    override fun execute(request: TransportRequest): TransportResponse {
        val headers = store.etag?.let { request.headers + ("If-None-Match" to it) } ?: request.headers
        return delegate.execute(request.copy(headers = headers)).also { response ->
            response.headers.entries.firstOrNull { it.key.equals("etag", true) }?.value?.let { store.etag = it }
        }
    }
}

data class UpdateSourceConfig(val manifestUrl: String, val githubRepository: String, val allowedHosts: Set<String>) {
    val configured: Boolean get() = manifestUrl.isNotBlank() || githubRepository.isNotBlank()
    companion object { fun current() = UpdateSourceConfig(UpdateSource.manifestUrl, UpdateSource.githubRepository, UpdateSource.allowedHosts) }
}

class UpdateStore(private val file: File = File(System.getProperty("user.home"), ".lagcheck-desktop/update.properties")) {
    private val properties = Properties().apply { if (file.isFile) file.inputStream().use(::load) }
    var automatic: Boolean
        get() = properties.getProperty("automatic", "false").toBoolean()
        set(value) { properties.setProperty("automatic", value.toString()); save() }
    var etag: String?
        get() = properties.getProperty("etag")
        set(value) { if (value == null) properties.remove("etag") else properties.setProperty("etag", value); save() }
    val lastChecked: Instant? get() = properties.getProperty("lastChecked")?.let { runCatching { Instant.ofEpochMilli(it.toLong()) }.getOrNull() }
    fun canCheck(now: Instant = Instant.now()): Boolean = lastChecked?.let { Duration.between(it, now) >= Duration.ofHours(6) } ?: true
    fun markChecked(now: Instant = Instant.now()) { properties.setProperty("lastChecked", now.toEpochMilli().toString()); save() }
    private fun save() { file.parentFile?.mkdirs(); file.outputStream().use { properties.store(it, "LagCheck desktop update") } }
}
