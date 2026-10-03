package com.lagcheck.android.data

import android.content.Context
import com.lagcheck.domain.model.FavoriteGames
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Repositório de preferências do usuário (Idioma, jogo ativo, plataforma, conexão).
 */
class PreferencesRepository(context: Context) {

    private val prefs = context.getSharedPreferences("lagcheck_prefs", Context.MODE_PRIVATE)

    private val _language = MutableStateFlow(
        prefs.getString("pref_language", "Português (Brasil)") ?: "Português (Brasil)"
    )
    val language: StateFlow<String> = _language.asStateFlow()

    private val _selectedGameId = MutableStateFlow(
        prefs.getString("pref_game_id", "fortnite") ?: "fortnite"
    )
    val selectedGameId: StateFlow<String> = _selectedGameId.asStateFlow()

    private val _selectedPlatform = MutableStateFlow(
        prefs.getString("pref_platform", "PlayStation") ?: "PlayStation"
    )
    val selectedPlatform: StateFlow<String> = _selectedPlatform.asStateFlow()

    private val _selectedConnectionType = MutableStateFlow(
        prefs.getString("pref_conn_type", "Wi-Fi") ?: "Wi-Fi"
    )
    val selectedConnectionType: StateFlow<String> = _selectedConnectionType.asStateFlow()

    private val _favorites = MutableStateFlow(FavoriteGames.parse(prefs.getString("pref_favorites", null)))
    val favorites: StateFlow<FavoriteGames> = _favorites.asStateFlow()

    fun toggleFavorite(gameId: String) {
        val next = _favorites.value.toggle(gameId)
        _favorites.value = next
        prefs.edit().putString("pref_favorites", next.serialize()).apply()
    }

    fun setLanguage(lang: String) {
        _language.value = lang
        prefs.edit().putString("pref_language", lang).apply()
    }

    fun setSelectedGame(gameId: String) {
        _selectedGameId.value = gameId
        prefs.edit().putString("pref_game_id", gameId).apply()
    }

    fun setSelectedPlatform(platform: String) {
        _selectedPlatform.value = platform
        prefs.edit().putString("pref_platform", platform).apply()
    }

    fun setSelectedConnectionType(type: String) {
        _selectedConnectionType.value = type
        prefs.edit().putString("pref_conn_type", type).apply()
    }
}
