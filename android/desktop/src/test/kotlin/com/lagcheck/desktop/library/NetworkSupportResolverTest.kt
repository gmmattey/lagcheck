package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.model.GameNetworkSupport
import com.lagcheck.desktop.library.model.GamePlatform
import com.lagcheck.desktop.library.model.PcGame
import com.lagcheck.desktop.library.network.CatalogGame
import com.lagcheck.desktop.library.network.NetworkSupportResolver
import kotlin.test.*

class NetworkSupportResolverTest {
    private val catalog = listOf(
        CatalogGame("cs2", "Counter-Strike 2"), CatalogGame("warzone", "Call of Duty: Warzone"),
        CatalogGame("rocket-league", "Rocket League"), CatalogGame("rust", "Rust"),
        CatalogGame("rainbow-six", "Rainbow Six Siege"),
    )
    private val resolver = NetworkSupportResolver({ catalog }, { "São Paulo" })
    private fun steam(id: String, title: String) = PcGame(id, title, GamePlatform.STEAM)

    @Test
    fun casaPorIdDeLojaConhecido() {
        val s = resolver.resolve(steam("steam_1938090", "Call of Duty"))
        assertEquals("warzone", (s as GameNetworkSupport.LagcheckSupported).catalogId)
        assertEquals("São Paulo", s.regionLabel)
        assertEquals("rainbow-six", (resolver.resolve(steam("steam_359550", "Tom Clancy's Rainbow Six Siege")) as GameNetworkSupport.LagcheckSupported).catalogId)
    }

    @Test
    fun casaPorNomeExatoNormalizado() {
        val epic = PcGame("epic_a1", "Rocket League®", GamePlatform.EPIC_GAMES)
        assertEquals("rocket-league", (resolver.resolve(epic) as GameNetworkSupport.LagcheckSupported).catalogId)
    }

    @Test
    fun naoCasaPorTrechoDeTitulo() {
        // O mapeamento antigo marcava qualquer título com "rust" ou "call of duty" como suportado.
        assertTrue(resolver.resolve(steam("steam_1", "Trust Fall Simulator")) is GameNetworkSupport.GeneralConnectionOnly)
        assertTrue(resolver.resolve(steam("steam_2", "Call of Duty: Modern Warfare II")) is GameNetworkSupport.GeneralConnectionOnly)
        assertTrue(resolver.resolve(steam("steam_3", "Counter-Strike")) is GameNetworkSupport.GeneralConnectionOnly)
    }

    @Test
    fun idConhecidoSemEntradaNoCatalogoVirouConexaoGeral() {
        val semCatalogo = NetworkSupportResolver({ emptyList() })
        assertTrue(semCatalogo.resolve(steam("steam_730", "Counter-Strike 2")) is GameNetworkSupport.GeneralConnectionOnly)
        assertTrue(NetworkSupportResolver.NONE.resolve(steam("steam_730", "Counter-Strike 2")) is GameNetworkSupport.GeneralConnectionOnly)
    }

    @Test
    fun jogoSoloVerificadoNaoRecebeDiagnostico() {
        assertTrue(resolver.resolve(steam("steam_949230", "Cities: Skylines II")) is GameNetworkSupport.OfflineSingleplayer)
    }

    @Test
    fun jogoDesconhecidoRecebeSoConexaoGeral() {
        assertTrue(resolver.resolve(steam("steam_5", "Qualquer Jogo")) is GameNetworkSupport.GeneralConnectionOnly)
    }

    @Test
    fun todosOsIdsDaTabelaExistemNoCatalogoEmbarcado() {
        val text = javaClass.getResourceAsStream("/catalog-base.json")!!.use { String(it.readBytes(), Charsets.UTF_8) }
        for ((storeId, catalogId) in NetworkSupportResolver.STEAM_APP_TO_CATALOG) {
            assertTrue("\"id\":\"$catalogId\"" in text, "$storeId aponta para '$catalogId', que não existe no catalog-base.json")
        }
    }
}
