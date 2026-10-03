package com.lagcheck.domain.model

/**
 * Jogos favoritos, em ordem de inclusão (o mais novo primeiro). Só guarda ids; ids que saíram do catálogo são ignorados
 * na hora de exibir, então um catálogo novo nunca quebra a lista salva.
 */
class FavoriteGames private constructor(val ids: List<String>) {
    operator fun contains(id: String) = id in ids

    fun toggle(id: String): FavoriteGames =
        if (id in ids) FavoriteGames(ids - id) else FavoriteGames(listOf(id) + ids)

    /** Favoritos que ainda existem na prateleira, na ordem salva. */
    fun resolve(shelf: List<CatalogGame>): List<CatalogGame> {
        val byId = shelf.associateBy { it.id }
        return ids.mapNotNull(byId::get)
    }

    fun serialize(): String = ids.joinToString(SEPARATOR)

    companion object {
        private const val SEPARATOR = ","
        val EMPTY = FavoriteGames(emptyList())

        fun parse(raw: String?): FavoriteGames =
            FavoriteGames(raw.orEmpty().split(SEPARATOR).map { it.trim() }.filter { it.isNotEmpty() }.distinct())
    }
}
