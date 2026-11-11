package com.lagcheck.desktop.library.artwork

import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import kotlin.test.*

class HttpArtworkFetcherTest {
    private lateinit var server: HttpServer
    private val base get() = "http://127.0.0.1:${server.address.port}"

    @BeforeTest fun up() {
        server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
        fun reply(path: String, status: Int, type: String?, body: ByteArray, extra: Map<String, String> = emptyMap()) =
            server.createContext(path) { ex ->
                type?.let { ex.responseHeaders.add("Content-Type", it) }
                extra.forEach { (k, v) -> ex.responseHeaders.add(k, v) }
                if (body.isEmpty()) ex.sendResponseHeaders(status, -1) else { ex.sendResponseHeaders(status, body.size.toLong()); ex.responseBody.use { it.write(body) } }
                ex.close()
            }
        reply("/ok.jpg", 200, "image/jpeg", jpegBytes(300))
        reply("/gone.jpg", 404, null, ByteArray(0))
        reply("/err.jpg", 503, null, ByteArray(0))
        reply("/page", 200, "text/html", "<html>".toByteArray())
        reply("/big.jpg", 200, "image/jpeg", ByteArray(20_000))
        reply("/redirect.jpg", 302, null, ByteArray(0), mapOf("Location" to "http://evil.example/x.jpg"))
        server.start()
    }

    @AfterTest fun down() = server.stop(0)

    private fun fetcher(maxBytes: Int = 10_000, https: Boolean = false, hosts: Set<String> = setOf("127.0.0.1")) =
        HttpArtworkFetcher(allowedHosts = hosts, requireHttps = https, maxBytes = maxBytes)

    @Test
    fun baixaImagemValida() {
        val r = fetcher().fetch("$base/ok.jpg")
        assertTrue(r is FetchResult.Bytes)
        assertTrue(ImageBytes.looksLikeImage(r.data))
    }

    @Test fun naoEncontradoEEstavel() = assertEquals(FetchResult.NotFound, fetcher().fetch("$base/gone.jpg"))

    @Test fun erroDoServidorEPassageiro() = assertTrue(fetcher().fetch("$base/err.jpg") is FetchResult.Failed)

    @Test fun respostaQueNaoEImagemEDescartada() = assertTrue(fetcher().fetch("$base/page") is FetchResult.Failed)

    @Test fun imagemMaiorQueOLimiteEDescartada() = assertTrue(fetcher().fetch("$base/big.jpg") is FetchResult.Failed)

    @Test fun redirecionamentoNaoESeguido() = assertTrue(fetcher().fetch("$base/redirect.jpg") is FetchResult.Failed)

    @Test fun hostForaDaListaNemEContatado() = assertTrue(fetcher(hosts = setOf("cdn.cloudflare.steamstatic.com")).fetch("$base/ok.jpg") is FetchResult.Failed)

    @Test fun httpSemTlsERecusadoPorPadrao() = assertTrue(fetcher(https = true).fetch("$base/ok.jpg") is FetchResult.Failed)

    @Test fun enderecoInvalidoNaoLanca() = assertTrue(fetcher().fetch("isto não é url") is FetchResult.Failed)

    @Test fun servidorForaDoArNaoLanca() {
        val port = server.address.port
        server.stop(0)
        assertTrue(fetcher().fetch("http://127.0.0.1:$port/ok.jpg") is FetchResult.Failed)
        server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0).also { it.start() } // para o @AfterTest
    }
}
