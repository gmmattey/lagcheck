package com.lagcheck.network.worker

/**
 * Endpoints do único Cloudflare Worker autorizado (`nolaggy-deep-check`). Espelham as constantes do iOS
 * (`DeepCheckLoadEndpoint`, catálogo e `CloudflareWorkerAnalyticsTracker`). Nenhum endpoint novo (Decisão 68).
 */
data class WorkerEndpoints(
    val loadUrl: String = "https://nolaggy-deep-check.buildealabs.workers.dev/v1/load",
    val catalogUrl: String = "https://nolaggy-deep-check.buildealabs.workers.dev/v1/catalog.json",
    val telemetryUrl: String = "https://nolaggy-deep-check.giammattey.workers.dev/v1/telemetry"
)
