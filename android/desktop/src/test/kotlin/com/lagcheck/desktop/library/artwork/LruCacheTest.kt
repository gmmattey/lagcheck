package com.lagcheck.desktop.library.artwork

import kotlin.test.*

class LruCacheTest {
    @Test
    fun expulsaOMenosUsadoQuandoPassaDoPeso() {
        val c = LruCache<String, ByteArray>(100) { it.size.toLong() }
        c.put("a", ByteArray(40)); c.put("b", ByteArray(40))
        assertNotNull(c.get("a")) // "a" fica mais recente que "b"
        c.put("c", ByteArray(40))
        assertNull(c.get("b"))
        assertNotNull(c.get("a")); assertNotNull(c.get("c"))
        assertTrue(c.currentWeight() <= 100)
    }

    @Test
    fun itemMaiorQueOCacheNaoEntraENaoExpulsaOsOutros() {
        val c = LruCache<String, ByteArray>(100) { it.size.toLong() }
        c.put("a", ByteArray(50))
        c.put("gigante", ByteArray(500))
        assertNull(c.get("gigante"))
        assertNotNull(c.get("a"))
    }

    @Test
    fun substituirChaveAtualizaOPeso() {
        val c = LruCache<String, ByteArray>(100) { it.size.toLong() }
        c.put("a", ByteArray(60)); c.put("a", ByteArray(10))
        assertEquals(10L, c.currentWeight())
        assertEquals(1, c.size())
    }
}
