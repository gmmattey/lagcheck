package com.lagcheck.android.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import com.lagcheck.android.MainActivity
import com.lagcheck.android.R
import com.lagcheck.domain.model.GameReadinessVerdict

/**
 * Superfície passiva do último Check válido. Não baixa arte, não lê rede e não
 * mede: só recebe o snapshot que o fluxo principal acabou de validar.
 */
class LagCheckWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { id -> manager.updateAppWidget(id, buildViews(context)) }
    }

    companion object {
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, LagCheckWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach { manager.updateAppWidget(it, buildViews(context)) }
        }

        private fun buildViews(context: Context): RemoteViews {
            val state = WidgetSnapshotStore(context).loadFresh()
            val views = RemoteViews(context.packageName, R.layout.widget_lagcheck)
            if (state == null) {
                views.setImageViewResource(R.id.widget_artwork, R.drawable.ic_launcher_mascot_bg)
                views.setTextViewText(R.id.widget_game, context.getString(R.string.widget_no_recent_check))
                views.setTextViewText(R.id.widget_region, context.getString(R.string.widget_tap_to_measure))
                views.setTextViewText(R.id.widget_ping, "—")
                views.setTextViewText(R.id.widget_verdict, "LAGCHECK")
                views.setTextColor(R.id.widget_verdict, Color.rgb(167, 139, 250))
                views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context, null))
                return views
            }

            val artwork = context.resources.getIdentifier(state.artworkDrawableName, "drawable", context.packageName)
            if (artwork == 0) return neutralizedForMissingArtwork(context, views)
            views.setImageViewResource(R.id.widget_artwork, artwork)
            views.setTextViewText(R.id.widget_game, state.gameName.uppercase())
            views.setTextViewText(R.id.widget_region, state.regionLabel)
            views.setTextViewText(R.id.widget_ping, context.getString(R.string.widget_ping_format, state.pingMs.toInt()))
            views.setTextViewText(R.id.widget_verdict, verdictLabel(context, state.verdict))
            views.setTextColor(R.id.widget_verdict, verdictColor(state.verdict))
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context, state))
            return views
        }

        private fun neutralizedForMissingArtwork(context: Context, views: RemoteViews): RemoteViews {
            views.setImageViewResource(R.id.widget_artwork, R.drawable.ic_launcher_mascot_bg)
            views.setTextViewText(R.id.widget_game, context.getString(R.string.widget_no_recent_check))
            views.setTextViewText(R.id.widget_region, context.getString(R.string.widget_tap_to_measure))
            views.setTextViewText(R.id.widget_ping, "—")
            views.setTextViewText(R.id.widget_verdict, "LAGCHECK")
            views.setTextColor(R.id.widget_verdict, Color.rgb(167, 139, 250))
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context, null))
            return views
        }

        private fun launchIntent(context: Context, state: WidgetSnapshotState?): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "com.lagcheck.app.WIDGET_CHECK"
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                state?.let {
                    putExtra(MainActivity.EXTRA_WIDGET_GAME_ID, it.gameId)
                    putExtra(MainActivity.EXTRA_WIDGET_PLATFORM, it.platform)
                    putExtra(MainActivity.EXTRA_WIDGET_EXTERNAL_LINK, it.declaredExternalLink)
                }
            }
            return PendingIntent.getActivity(context, state?.gameId?.hashCode() ?: 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        private fun verdictLabel(context: Context, verdict: String) = when (verdict) {
            GameReadinessVerdict.READY.name -> context.getString(R.string.widget_ready)
            GameReadinessVerdict.CAUTION.name -> context.getString(R.string.widget_caution)
            GameReadinessVerdict.NOT_READY.name -> context.getString(R.string.widget_not_ready)
            else -> context.getString(R.string.widget_inconclusive)
        }

        private fun verdictColor(verdict: String) = when (verdict) {
            GameReadinessVerdict.READY.name -> Color.rgb(52, 211, 153)
            GameReadinessVerdict.CAUTION.name -> Color.rgb(251, 191, 36)
            GameReadinessVerdict.NOT_READY.name -> Color.rgb(255, 90, 54)
            else -> Color.LTGRAY
        }
    }
}
