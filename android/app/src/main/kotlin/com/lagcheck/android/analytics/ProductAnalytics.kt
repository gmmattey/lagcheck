package com.lagcheck.android.analytics

import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics

/** Eventos comerciais canônicos. Não carregam dado de rede identificável. */
sealed interface ProductAnalyticsEvent {
    data class GameSelected(val gameId: String) : ProductAnalyticsEvent
    data class LagcheckStarted(
        val gameId: String,
        val gamePlatform: String,
        val networkType: String,
        val regionId: String
    ) : ProductAnalyticsEvent
    data class LagcheckCompleted(
        val gameId: String,
        val gamePlatform: String,
        val networkType: String,
        val regionId: String,
        val resultClass: String,
        val durationSeconds: Long
    ) : ProductAnalyticsEvent
    data class LagcheckInconclusive(
        val gameId: String,
        val gamePlatform: String,
        val networkType: String,
        val regionId: String,
        val reason: String
    ) : ProductAnalyticsEvent
    data class LagcheckCancelled(
        val gameId: String,
        val gamePlatform: String,
        val networkType: String,
        val regionId: String,
        val reason: String
    ) : ProductAnalyticsEvent
    data class ResultViewed(val gameId: String, val gamePlatform: String, val resultClass: String) : ProductAnalyticsEvent
    data class RetestStarted(val gameId: String, val gamePlatform: String) : ProductAnalyticsEvent
}

fun interface ProductAnalyticsTracker {
    fun track(event: ProductAnalyticsEvent)
}

object NoopProductAnalyticsTracker : ProductAnalyticsTracker {
    override fun track(event: ProductAnalyticsEvent) = Unit
}

/** Exclusão persistente e local, sem conta, rede ou identificação da pessoa. */
class AnalyticsCollectionPreference(
    private val preferences: SharedPreferences,
    private val buildAllowsCollection: Boolean
) {
    val isCollectionEnabled: Boolean
        get() = effectiveAnalyticsCollectionEnabled(
            buildAllowsCollection,
            preferences.getBoolean(OWNER_EXCLUDED_KEY, false)
        )

    fun setOwnerExcluded(excluded: Boolean) {
        preferences.edit().putBoolean(OWNER_EXCLUDED_KEY, excluded).apply()
    }

    companion object {
        private const val OWNER_EXCLUDED_KEY = "firebase_analytics_owner_excluded"

        fun from(context: Context, buildAllowsCollection: Boolean) = AnalyticsCollectionPreference(
            context.getSharedPreferences("lagcheck_analytics", Context.MODE_PRIVATE),
            buildAllowsCollection
        )
    }
}

internal fun effectiveAnalyticsCollectionEnabled(
    buildAllowsCollection: Boolean,
    ownerExcluded: Boolean
): Boolean = buildAllowsCollection && !ownerExcluded

class CollectionGatedProductAnalyticsTracker(
    private val preference: AnalyticsCollectionPreference,
    private val delegate: ProductAnalyticsTracker
) : ProductAnalyticsTracker {
    override fun track(event: ProductAnalyticsEvent) {
        if (preference.isCollectionEnabled) delegate.track(event)
    }
}

class FirebaseProductAnalyticsTracker(
    private val firebase: FirebaseAnalytics
) : ProductAnalyticsTracker {
    override fun track(event: ProductAnalyticsEvent) {
        val payload = event.toFirebasePayload()
        firebase.logEvent(payload.name, Bundle().apply {
            payload.parameters.forEach { (key, value) ->
                when (value) {
                    is String -> putString(key, value)
                    is Long -> putLong(key, value)
                }
            }
        })
    }
}

data class FirebaseAnalyticsPayload(val name: String, val parameters: Map<String, Any>)

internal fun ProductAnalyticsEvent.toFirebasePayload(): FirebaseAnalyticsPayload {
    fun context(gameId: String, platform: String, network: String, region: String) = mapOf(
        "game_id" to gameId,
        "game_platform" to platform,
        "network_type" to network,
        "region_id" to region
    )

    return when (this) {
        is ProductAnalyticsEvent.GameSelected -> FirebaseAnalyticsPayload("game_selected", mapOf("game_id" to gameId))
        is ProductAnalyticsEvent.LagcheckStarted -> FirebaseAnalyticsPayload("lagcheck_started", context(gameId, gamePlatform, networkType, regionId))
        is ProductAnalyticsEvent.LagcheckCompleted -> FirebaseAnalyticsPayload("lagcheck_completed", context(gameId, gamePlatform, networkType, regionId) + mapOf(
            "result_class" to resultClass,
            "duration_seconds" to durationSeconds.coerceAtLeast(0)
        ))
        is ProductAnalyticsEvent.LagcheckInconclusive -> FirebaseAnalyticsPayload("lagcheck_inconclusive", context(gameId, gamePlatform, networkType, regionId) + mapOf(
            "inconclusive_reason" to reason
        ))
        is ProductAnalyticsEvent.LagcheckCancelled -> FirebaseAnalyticsPayload("lagcheck_cancelled", context(gameId, gamePlatform, networkType, regionId) + mapOf(
            "cancellation_reason" to reason
        ))
        is ProductAnalyticsEvent.ResultViewed -> FirebaseAnalyticsPayload("result_viewed", mapOf(
            "game_id" to gameId,
            "game_platform" to gamePlatform,
            "result_class" to resultClass
        ))
        is ProductAnalyticsEvent.RetestStarted -> FirebaseAnalyticsPayload("retest_started", mapOf(
            "game_id" to gameId,
            "game_platform" to gamePlatform
        ))
    }
}

object FirebaseAnalyticsRuntime {
    fun configure(context: Context, enabled: Boolean, environment: String): FirebaseAnalytics {
        return FirebaseAnalytics.getInstance(context).also {
            it.setAnalyticsCollectionEnabled(enabled)
            // O variant debug não inicializa este runtime. A origem é definida no
            // AAB (testing ou production), nunca inferida pelo Play ou pelo painel.
            it.setUserProperty("environment", environment)
        }
    }

    fun setCollectionEnabled(context: Context, enabled: Boolean) {
        FirebaseAnalytics.getInstance(context).setAnalyticsCollectionEnabled(enabled)
    }
}
