package com.lagcheck.desktop.library.artwork

import java.io.IOException
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Duration

/**
 * Baixa uma imagem de um host da lista. Só HTTPS, sem seguir redirecionamento, sem cookie, sem identificação
 * do usuário (o User-Agent é genérico), com tempo e tamanho máximos. Resposta que não seja imagem é descartada.
 */
class HttpArtworkFetcher(
    private val allowedHosts: Set<String> = DEFAULT_HOSTS,
    private val requireHttps: Boolean = true,
    private val maxBytes: Int = 5 * 1024 * 1024,
    private val timeout: Duration = Duration.ofSeconds(8),
    private val client: HttpClient = HttpClient.newBuilder()
        .followRedirects(HttpClient.Redirect.NEVER)
        .connectTimeout(timeout)
        .build(),
) : ArtworkFetcher {

    override fun fetch(url: String): FetchResult {
        val uri = runCatching { URI(url) }.getOrNull() ?: return FetchResult.Failed("endereço inválido")
        if (requireHttps && uri.scheme != "https") return FetchResult.Failed("só HTTPS")
        if (uri.host?.lowercase() !in allowedHosts) return FetchResult.Failed("host fora da lista")
        return try {
            val request = HttpRequest.newBuilder(uri).timeout(timeout)
                .header("User-Agent", "LagCheck").header("Accept", "image/*").GET().build()
            val response = client.send(request, HttpResponse.BodyHandlers.ofInputStream())
            response.body().use { body ->
                when (response.statusCode()) {
                    404, 410 -> FetchResult.NotFound
                    200 -> readImage(response, body)
                    else -> FetchResult.Failed("HTTP ${response.statusCode()}")
                }
            }
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
            FetchResult.Failed("interrompido")
        } catch (e: IOException) {
            FetchResult.Failed("sem rede ou tempo esgotado")
        } catch (e: IllegalArgumentException) {
            FetchResult.Failed("requisição inválida")
        }
    }

    private fun readImage(response: HttpResponse<*>, body: java.io.InputStream): FetchResult {
        val type = response.headers().firstValue("Content-Type").orElse("").lowercase()
        if (!type.startsWith("image/")) return FetchResult.Failed("resposta não é imagem")
        val declared = response.headers().firstValueAsLong("Content-Length").orElse(-1)
        if (declared > maxBytes) return FetchResult.Failed("imagem grande demais")
        val data = body.readNBytes(maxBytes + 1)
        if (data.size > maxBytes) return FetchResult.Failed("imagem grande demais")
        return FetchResult.Bytes(data)
    }

    companion object {
        /** CDNs oficiais da Steam. */
        val DEFAULT_HOSTS = setOf("cdn.cloudflare.steamstatic.com", "shared.fastly.steamstatic.com")
    }
}
