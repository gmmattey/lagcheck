package com.lagcheck.domain

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.FavoriteGames
import com.lagcheck.domain.model.OfficialGameCatalog
import org.junit.Test

class FavoriteGamesTest {
    @Test fun toggleAddsNewestFirstAndRemoves() {
        val f = FavoriteGames.EMPTY.toggle("fortnite").toggle("valorant")
        assertThat(f.ids).containsExactly("valorant", "fortnite").inOrder()
        assertThat(f.toggle("fortnite").ids).containsExactly("valorant")
        assertThat("valorant" in f).isTrue()
    }

    @Test fun keepsOnlyTheFourNewestFavorites() {
        val f = listOf("a", "b", "c", "d", "e").fold(FavoriteGames.EMPTY) { acc, id -> acc.toggle(id) }
        assertThat(f.ids).containsExactly("e", "d", "c", "b").inOrder()
        assertThat(FavoriteGames.parse("a,b,c,d,e").ids).containsExactly("a", "b", "c", "d").inOrder()
    }

    @Test fun roundTripsAndToleratesGarbage() {
        val f = FavoriteGames.EMPTY.toggle("a").toggle("b")
        assertThat(FavoriteGames.parse(f.serialize()).ids).containsExactly("b", "a").inOrder()
        assertThat(FavoriteGames.parse(null).ids).isEmpty()
        assertThat(FavoriteGames.parse(" , a,,a ,b").ids).containsExactly("a", "b").inOrder()
    }

    @Test fun removedGamesNeverBreakTheList() {
        val f = FavoriteGames.parse("jogo-que-saiu,fortnite")
        assertThat(f.resolve(OfficialGameCatalog.games).map { it.id }).containsExactly("fortnite")
    }
}
