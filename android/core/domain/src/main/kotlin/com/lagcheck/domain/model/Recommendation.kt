package com.lagcheck.domain.model

/** Recomendação sempre ligada a uma evidência medida. Sem evidência, nenhuma recomendação. */
enum class RecommendationKey(val titleKey: String, val instructionKey: String, val badgeKey: String) {
    APPROACH_ROUTER("rec.approach_router.title", "rec.approach_router.instruction", "rec.approach_router.badge"),
    SWITCH_TO_5GHZ("rec.switch_5ghz.title", "rec.switch_5ghz.instruction", "rec.switch_5ghz.badge"),
    AVOID_RANKED("rec.avoid_ranked.title", "rec.avoid_ranked.instruction", "rec.avoid_ranked.badge"),
    PAUSE_DOWNLOADS("rec.pause_downloads.title", "rec.pause_downloads.instruction", "rec.pause_downloads.badge"),
    CHECK_LOCAL_INTERFERENCE("rec.local_interference.title", "rec.local_interference.instruction", "rec.local_interference.badge"),
    ENABLE_UPNP("rec.upnp.title", "rec.upnp.instruction", "rec.upnp.badge"),
    ROUTE_INSTABILITY("rec.route_instability.title", "rec.route_instability.instruction", "rec.route_instability.badge")
}

data class ActionableRecommendation(val priority: Int, val key: RecommendationKey)
