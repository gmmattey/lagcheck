package com.lagcheck.android.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import com.lagcheck.android.data.CheckHistoryItem
import com.lagcheck.domain.model.CatalogGame

data class WidgetSnapshotState(
    val gameId: String,
    val gameName: String,
    val platform: String,
    val declaredExternalLink: String?,
    val regionLabel: String,
    val verdict: String,
    val pingMs: Double,
    val capturedAt: Long,
    val artworkDrawableName: String
)

/** Persistência privada do widget Android; imagens seguem sendo recursos do APK, nunca bytes iOS nem URL externa. */
class WidgetSnapshotStore(private val context: Context) {
    private val prefs = context.getSharedPreferences("lagcheck_widget_snapshot", Context.MODE_PRIVATE)

    fun save(game: CatalogGame, item: CheckHistoryItem, regionLabel: String) {
        val ping = item.pingMs ?: return clear()
        val artwork = game.drawableResName.takeIf { it.isNotBlank() } ?: return clear()
        prefs.edit()
            .putString("game_id", item.gameId)
            .putString("game_name", item.gameName)
            .putString("platform", item.platform)
            .putString("external_link", item.declaredExternalLink)
            .putString("region", regionLabel)
            .putString("verdict", item.verdict.name)
            .putFloat("ping", ping.toFloat())
            .putLong("captured_at", item.timestamp)
            .putString("artwork", artwork)
            .apply()
        LagCheckWidgetProvider.refresh(context)
    }

    fun clear() {
        prefs.edit().clear().apply()
        LagCheckWidgetProvider.refresh(context)
    }

    fun loadFresh(now: Long = System.currentTimeMillis()): WidgetSnapshotState? {
        val capturedAt = prefs.getLong("captured_at", 0)
        if (capturedAt <= 0 || now - capturedAt !in 0..FOUR_HOURS) return null
        val gameId = prefs.getString("game_id", null) ?: return null
        val gameName = prefs.getString("game_name", null) ?: return null
        val platform = prefs.getString("platform", null) ?: return null
        val verdict = prefs.getString("verdict", null) ?: return null
        val artwork = prefs.getString("artwork", null) ?: return null
        val ping = prefs.getFloat("ping", Float.NaN).toDouble()
        if (!ping.isFinite() || ping <= 0) return null
        return WidgetSnapshotState(
            gameId, gameName, platform, prefs.getString("external_link", null),
            prefs.getString("region", "—") ?: "—", verdict, ping, capturedAt, artwork
        )
    }

    private companion object { const val FOUR_HOURS = 4 * 60 * 60 * 1000L }
}
