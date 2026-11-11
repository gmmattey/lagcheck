package com.lagcheck.desktop.library.artwork

/** Cache em memória com teto de peso (ex.: bytes decodificados). Remove o menos usado recentemente. */
class LruCache<K : Any, V : Any>(private val maxWeight: Long, private val weigher: (V) -> Long) {
    private val map = LinkedHashMap<K, V>(16, 0.75f, true)
    private var weight = 0L

    @Synchronized fun get(key: K): V? = map[key]

    @Synchronized fun put(key: K, value: V) {
        map.remove(key)?.let { weight -= weigher(it) }
        val w = weigher(value)
        if (w > maxWeight) return // maior que o cache inteiro: não guarda, nem expulsa os outros
        map[key] = value
        weight += w
        val it = map.entries.iterator()
        while (weight > maxWeight && it.hasNext()) {
            val eldest = it.next()
            weight -= weigher(eldest.value)
            it.remove()
        }
    }

    @Synchronized fun remove(key: K) { map.remove(key)?.let { weight -= weigher(it) } }
    @Synchronized fun clear() { map.clear(); weight = 0 }
    @Synchronized fun currentWeight(): Long = weight
    @Synchronized fun size(): Int = map.size
}
