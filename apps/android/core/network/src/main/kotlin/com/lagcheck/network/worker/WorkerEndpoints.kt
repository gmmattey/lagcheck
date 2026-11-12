package com.lagcheck.network.worker

/**
 * Endpoints do único Cloudflare Worker autorizado (`nolaggy-deep-check`). Espelham as constantes do iOS
 * (`DeepCheckLoadEndpoint` e `CloudflareWorkerAnalyticsTracker`). Nenhum endpoint novo (Decisão 94).
 */
data class WorkerEndpoints(
    val loadUrl: String = "https://nolaggy-deep-check.buildealabs.workers.dev/v1/load",
    val telemetryUrl: String = "https://nolaggy-deep-check.buildealabs.workers.dev/v1/telemetry"
)
