package com.lagcheck.domain.rules

import com.lagcheck.domain.model.NatType

/** Regras do resultado geral do site, portadas sem alterar cortes (use-cases-v1). */
object UseCaseEvaluator {
    const val VERSION = "use-cases-v1"

    enum class Status { EXCELLENT, GOOD, CAUTION, POOR }
    enum class OverallTone { OK, WARN, BAD }
    enum class NatSource { STUN_APP, BROWSER_ESTIMATE }

    data class NatMeasurement(val type: NatType, val source: NatSource)

    data class Input(
        val p50Milliseconds: Double?,
        val jitterMilliseconds: Double?,
        val loadDeltaMilliseconds: Double?,
        val uploadMbps: Double? = null,
        val nat: NatMeasurement? = null
    )

    data class UseCase(
        val id: String,
        val status: Status,
        val titleKey: String,
        val detailKey: String,
        val origin: NatSource? = null
    )

    data class Evaluation(
        val overallTone: OverallTone,
        val overallHeadlineKey: String,
        val overallSubtitleKey: String,
        val cases: List<UseCase>
    )

    fun evaluate(input: Input): Evaluation {
        // Defaults mirror the site exactly: missing latency/jitter cannot be called usable;
        // missing load is neutral because the rest reading is still real.
        val lat = input.p50Milliseconds ?: 999.0
        val jit = input.jitterMilliseconds ?: 999.0
        val bloat = input.loadDeltaMilliseconds ?: 0.0

        val fps = classify(lat, jit, bloat, poor = { l, j, b -> l > 80 || j > 12 || b > 70 }, caution = { l, j, b -> l > 50 || j > 5 || b > 35 }, good = { l, j, b -> l > 30 || j > 2.5 || b > 15 })
        val br = classify(lat, jit, bloat, poor = { l, j, b -> l > 100 || j > 18 || b > 90 }, caution = { l, j, b -> l > 70 || j > 8 || b > 50 }, good = { l, j, b -> l > 45 || j > 4 || b > 25 })
        val moba = classify(lat, jit, bloat, poor = { l, j, _ -> l > 120 || j > 25 }, caution = { l, j, b -> l > 80 || j > 12 || b > 70 }, good = { l, j, b -> l > 50 || j > 5 || b > 35 })
        val fighting = classify(lat, jit, bloat, poor = { l, j, b -> l > 90 || j > 10 || b > 60 }, caution = { l, j, b -> l > 60 || j > 4.5 || b > 35 }, good = { l, j, b -> l > 38 || j > 2.5 || b > 18 })
        val casual = classify(lat, jit, bloat, poor = { l, j, _ -> l > 150 || j > 25 }, caution = { l, j, _ -> l > 90 || j > 12 }, good = { l, j, _ -> l > 50 || j > 6 })
        val voice = classify(lat, jit, bloat, poor = { _, j, b -> j > 20 || b > 95 }, caution = { _, j, b -> j > 9 || b > 55 }, good = { _, j, b -> j > 4 || b > 25 })
        val streamingStability = classify(lat, jit, bloat, poor = { _, j, b -> b > 85 || j > 18 }, caution = { l, j, b -> b > 45 || j > 8 || l > 90 }, good = { l, j, b -> b > 20 || j > 4 || l > 60 })
        val cloud = classify(lat, jit, bloat, poor = { l, j, b -> l > 80 || j > 14 || b > 50 }, caution = { l, j, b -> l > 50 || j > 6 || b > 30 }, good = { l, j, b -> l > 32 || j > 3 || b > 15 })

        val streaming = input.uploadMbps?.let { worse(streamingStability, uploadTier(it)) } ?: streamingStability
        val cases = mutableListOf(
            useCase("fps", fps), useCase("br", br), useCase("moba", moba), useCase("fighting", fighting),
            useCase("casual", casual), useCase("voice", voice), useCase("streaming", streaming), useCase("cloud", cloud)
        )
        input.nat?.let { nat ->
            val status = if (nat.type == NatType.TYPE_3_STRICT) Status.CAUTION else Status.GOOD
            cases += UseCase("nat", status, "use_case.nat.title", "use_case.nat.${nat.type.rawValue}", nat.source)
        }

        // Como em categories.ts: o resumo geral usa o streaming só pela estabilidade; o upload
        // entra apenas na linha de streaming exibida (media.ts). NAT não entra no resumo.
        val statuses = listOf(fps, br, moba, fighting, casual, voice, streamingStability, cloud)
        val poorCount = statuses.count { it == Status.POOR }
        val cautionCount = statuses.count { it == Status.CAUTION }
        val overall = when {
            poorCount >= 3 || (fps == Status.POOR && streamingStability == Status.POOR) -> OverallTone.BAD
            poorCount > 0 || cautionCount >= 2 -> OverallTone.WARN
            else -> OverallTone.OK
        }
        return Evaluation(
            overallTone = overall,
            overallHeadlineKey = "use_case.overall.${overall.name.lowercase()}.headline",
            overallSubtitleKey = "use_case.overall.${overall.name.lowercase()}.subtitle",
            cases = cases
        )
    }

    fun uploadTier(mbps: Double): Status = when {
        mbps >= 10.0 -> Status.EXCELLENT
        mbps >= 6.0 -> Status.GOOD
        mbps >= 3.0 -> Status.CAUTION
        else -> Status.POOR
    }

    private fun classify(
        latency: Double,
        jitter: Double,
        load: Double,
        poor: (Double, Double, Double) -> Boolean,
        caution: (Double, Double, Double) -> Boolean,
        good: (Double, Double, Double) -> Boolean
    ) = when {
        poor(latency, jitter, load) -> Status.POOR
        caution(latency, jitter, load) -> Status.CAUTION
        good(latency, jitter, load) -> Status.GOOD
        else -> Status.EXCELLENT
    }

    private fun worse(a: Status, b: Status): Status = if (a.ordinal >= b.ordinal) a else b
    private fun useCase(id: String, status: Status) = UseCase(
        id = id,
        status = status,
        titleKey = "use_case.$id.title",
        detailKey = "use_case.$id.${status.name.lowercase()}"
    )
}
