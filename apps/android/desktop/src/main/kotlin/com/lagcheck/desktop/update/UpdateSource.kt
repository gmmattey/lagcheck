package com.lagcheck.desktop.update

import java.io.InputStream

/** Fonte: GitHub Releases do repositório público (Decisão 116). Sem release do Windows publicada, a consulta não encontra nada e o app segue normal. */
object UpdateSource {
    const val installedVersion = "0.2"
    const val manifestUrl: String = ""
    const val githubRepository: String = "gmmattey/lagcheck"
    val allowedHosts: Set<String> = setOf("api.github.com", "github.com", "objects.githubusercontent.com", "release-assets.githubusercontent.com")

    val isConfigured: Boolean get() = manifestUrl.isNotBlank() || githubRepository.isNotBlank()
}

data class Release(val version: String, val notes: String, val url: String, val sha256: String)

interface ReleaseFeed { fun latest(): Release? }

data class TransportRequest(val url: String, val headers: Map<String, String> = emptyMap())
data class TransportResponse(val status: Int, val headers: Map<String, String>, val body: InputStream)
fun interface HttpTransport { fun execute(request: TransportRequest): TransportResponse }
