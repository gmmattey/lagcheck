package com.lagcheck.domain.rules

import kotlin.math.roundToInt

/**
 * Avalia a evolução histórica da conexão em janela de dias, separando contextos
 * incompatíveis (rede/região) e calculando os 4 anéis de resumo (Decisão 143).
 */
object StabilitySummaryEvaluator {
    const val VERSION = "stability-summary-v2"
    const val MINIMUM_COMPARABLE_CHECKS = 3
    private const val DAY_MILLIS = 86_400_000L
    private const val MAX_VALID_PING_MS = 10_000.0

    enum class VerdictKind {
        READY,
        CAUTION,
        NOT_READY,
        INCONCLUSIVE,
        UNKNOWN;

        companion object {
            fun parse(raw: String?): VerdictKind {
                val norm = raw?.trim()?.uppercase() ?: return UNKNOWN
                return when (norm) {
                    "READY", "OK" -> READY
                    "CAUTION", "WARN" -> CAUTION
                    "NOT_READY", "NOTREADY", "BAD" -> NOT_READY
                    "INCONCLUSIVE" -> INCONCLUSIVE
                    else -> UNKNOWN
                }
            }
        }
    }

    enum class MetricTone {
        OK,
        WARN,
        BAD,
        UNKNOWN
    }

    data class EntryInput(
        val capturedAtEpochMs: Long,
        val pingMs: Double? = null,
        val jitterMs: Double? = null,
        val packetLossPercentage: Double? = null,
        val loadDeltaMs: Double? = null,
        val verdict: String,
        val validResponseCount: Int? = null,
        val gameId: String? = null,
        val gameTitle: String? = null,
        val platform: String? = null,
        val declaredExternalLink: String? = null,
        val networkType: String? = null,
        val regionId: String? = null,
        val ruleVersion: String? = null
    )

    data class Request(
        val entries: List<EntryInput>,
        val windowDays: Int = 14,
        val nowEpochMs: Long,
        val gameIdFilter: String? = null,
        val networkFilter: String? = null,
        val maxPoints: Int = 30
    )

    data class Point(
        val capturedAtEpochMs: Long,
        val pingMs: Double,
        val jitterMs: Double?,
        val packetLossPercentage: Double?,
        val loadDeltaMs: Double?,
        val verdict: VerdictKind,
        val gameId: String?,
        val gameTitle: String?,
        val networkType: String?,
        val regionId: String?,
        val segmentIndex: Int,
        val connectToPrevious: Boolean
    )

    data class RingMetric(
        val value: Double?,
        val tone: MetricTone,
        val fillRatio: Double
    )

    data class Rings(
        val ping: RingMetric,
        val jitter: RingMetric,
        val loss: RingMetric,
        val load: RingMetric
    )

    data class Result(
        val ruleVersion: String = VERSION,
        val windowDays: Int,
        val points: List<Point>,
        val canDrawCurve: Boolean,
        val hasSummary: Boolean,
        val hasMixedContexts: Boolean,
        val availableNetworks: List<String>,
        val summaryNetworkType: String?,
        val summaryRegionId: String?,
        val totalComparableCount: Int,
        val readyCount: Int,
        val cautionCount: Int,
        val badCount: Int,
        val inconclusiveCount: Int,
        val stabilityPercentage: Int?,
        val stabilityTone: MetricTone,
        val headlineKey: String,
        val minPingMs: Double?,
        val avgPingMs: Double?,
        val maxPingMs: Double?,
        val rings: Rings?,
        val latest: Point?
    )

    private data class NormalizedEntry(
        val raw: EntryInput,
        val verdict: VerdictKind,
        val gameId: String?,
        val gameTitle: String?,
        val networkType: String?,
        val regionId: String?,
        val platform: String?,
        val externalLink: String?,
        val ruleVersion: String?
    ) {
        val isEligible: Boolean
            get() {
                if (verdict != VerdictKind.READY && verdict != VerdictKind.CAUTION && verdict != VerdictKind.NOT_READY) {
                    return false
                }
                val ping = raw.pingMs ?: return false
                if (!ping.isFinite() || ping < 0.0 || ping > MAX_VALID_PING_MS) return false
                val validCount = raw.validResponseCount
                return validCount == null || validCount >= 10
            }

        val isInconclusive: Boolean
            get() {
                if (verdict == VerdictKind.INCONCLUSIVE) return true
                val validCount = raw.validResponseCount
                return (verdict == VerdictKind.READY || verdict == VerdictKind.CAUTION || verdict == VerdictKind.NOT_READY) &&
                    validCount != null && validCount < 10
            }
    }

    fun evaluate(request: Request): Result {
        val windowDays = request.windowDays
        val cutoff = if (windowDays > 0) request.nowEpochMs - windowDays.toLong() * DAY_MILLIS else Long.MIN_VALUE
        val generalOnly = isGeneralFilter(request.gameIdFilter)
        val specificGame = request.gameIdFilter?.trim()?.takeIf { it.isNotEmpty() && !generalOnly }
        val normalizedNetworkFilter = normalizeNetworkFilter(request.networkFilter)

        val scopedEntries = request.entries
            .asSequence()
            .filter { it.capturedAtEpochMs > 0L && it.capturedAtEpochMs >= cutoff && it.capturedAtEpochMs <= request.nowEpochMs }
            .map(::normalize)
            .filter { entry ->
                when {
                    generalOnly -> entry.gameId == null
                    specificGame != null -> entry.gameId != null && entry.gameId.equals(specificGame, ignoreCase = true)
                    else -> true
                }
            }
            .sortedBy { it.raw.capturedAtEpochMs }
            .toList()

        val availableNetworks = scopedEntries
            .asSequence()
            .filter { it.isEligible }
            .mapNotNull { it.networkType }
            .distinct()
            .sortedBy { networkSortOrder(it) }
            .toList()

        val networkScoped = if (normalizedNetworkFilter == null) {
            scopedEntries
        } else {
            scopedEntries.filter { it.networkType == normalizedNetworkFilter }
        }

        val allEligible = networkScoped.filter { it.isEligible }
        val latestEntry = allEligible.lastOrNull()

        if (specificGame != null || generalOnly) {
            return evaluateStrictContext(
                windowDays = windowDays,
                networkScoped = networkScoped,
                allEligible = allEligible,
                latestEntry = latestEntry,
                availableNetworks = availableNetworks,
                maxPoints = request.maxPoints
            )
        }

        return evaluateOverview(
            windowDays = windowDays,
            networkScoped = networkScoped,
            allEligible = allEligible,
            latestEntry = latestEntry,
            availableNetworks = availableNetworks,
            maxPoints = request.maxPoints
        )
    }

    private fun evaluateStrictContext(
        windowDays: Int,
        networkScoped: List<NormalizedEntry>,
        allEligible: List<NormalizedEntry>,
        latestEntry: NormalizedEntry?,
        availableNetworks: List<String>,
        maxPoints: Int
    ): Result {
        if (latestEntry == null) {
            val inconclusiveOnly = networkScoped.count { it.isInconclusive }
            return emptyResult(windowDays, availableNetworks, inconclusiveOnly)
        }

        val comparable = allEligible.filter { sameStrictContext(it, latestEntry) }
        val inconclusiveCount = networkScoped.count { it.isInconclusive && sameScopeContext(it, latestEntry) }
        val sliced = sliceLatest(comparable, maxPoints)
        val hasEnough = comparable.size >= MINIMUM_COMPARABLE_CHECKS

        val points = sliced.mapIndexed { index, entry ->
            toPoint(
                entry = entry,
                segmentIndex = 0,
                connectToPrevious = hasEnough && index > 0
            )
        }

        return buildResult(
            windowDays = windowDays,
            points = points,
            canDrawCurve = hasEnough && points.size >= MINIMUM_COMPARABLE_CHECKS,
            hasMixedContexts = false,
            availableNetworks = availableNetworks,
            summaryEntries = comparable,
            inconclusiveCount = inconclusiveCount,
            latestPoint = points.lastOrNull()
        )
    }

    private fun evaluateOverview(
        windowDays: Int,
        networkScoped: List<NormalizedEntry>,
        allEligible: List<NormalizedEntry>,
        latestEntry: NormalizedEntry?,
        availableNetworks: List<String>,
        maxPoints: Int
    ): Result {
        if (latestEntry == null) {
            val inconclusiveOnly = networkScoped.count { it.isInconclusive }
            return emptyResult(windowDays, availableNetworks, inconclusiveOnly)
        }

        val sliced = sliceLatest(allEligible, maxPoints)
        val segments = ArrayList<Int>(sliced.size)
        val segmentSizes = HashMap<Int, Int>()
        var currentSegment = 0

        for (i in sliced.indices) {
            if (i > 0 && !sameTimelineContext(sliced[i - 1], sliced[i])) {
                currentSegment++
            }
            segments.add(currentSegment)
            segmentSizes[currentSegment] = (segmentSizes[currentSegment] ?: 0) + 1
        }

        val points = sliced.mapIndexed { index, entry ->
            val seg = segments[index]
            val segSize = segmentSizes[seg] ?: 0
            val connect = index > 0 && segments[index - 1] == seg && segSize >= MINIMUM_COMPARABLE_CHECKS
            toPoint(entry = entry, segmentIndex = seg, connectToPrevious = connect)
        }

        val canDrawCurve = points.any { it.connectToPrevious }
        val hasMixedContexts = sliced
            .map { it.networkType to it.regionId }
            .distinct()
            .size > 1

        // Resumo e 4 anéis sempre ancorados em checks comparáveis do mesmo contexto mais recente.
        val summaryEntries = allEligible.filter { sameTimelineContext(it, latestEntry) }
        val inconclusiveCount = networkScoped.count { it.isInconclusive && sameTimelineContext(it, latestEntry) }

        return buildResult(
            windowDays = windowDays,
            points = points,
            canDrawCurve = canDrawCurve,
            hasMixedContexts = hasMixedContexts,
            availableNetworks = availableNetworks,
            summaryEntries = summaryEntries,
            inconclusiveCount = inconclusiveCount,
            latestPoint = points.lastOrNull()
        )
    }

    private fun buildResult(
        windowDays: Int,
        points: List<Point>,
        canDrawCurve: Boolean,
        hasMixedContexts: Boolean,
        availableNetworks: List<String>,
        summaryEntries: List<NormalizedEntry>,
        inconclusiveCount: Int,
        latestPoint: Point?
    ): Result {
        val total = summaryEntries.size
        val hasSummary = total >= MINIMUM_COMPARABLE_CHECKS
        val latestSummaryEntry = summaryEntries.lastOrNull()

        var ready = 0
        var caution = 0
        var bad = 0
        var minPing = Double.POSITIVE_INFINITY
        var maxPing = Double.NEGATIVE_INFINITY
        var pingSum = 0.0
        var jitterSum = 0.0
        var jitterCount = 0
        var lossSum = 0.0
        var lossCount = 0
        var loadSum = 0.0
        var loadCount = 0

        for (entry in summaryEntries) {
            when (entry.verdict) {
                VerdictKind.READY -> ready++
                VerdictKind.CAUTION -> caution++
                VerdictKind.NOT_READY -> bad++
                else -> {}
            }
            val ping = entry.raw.pingMs!!
            if (ping < minPing) minPing = ping
            if (ping > maxPing) maxPing = ping
            pingSum += ping

            val jitter = entry.raw.jitterMs
            if (jitter != null && jitter.isFinite() && jitter >= 0.0) {
                jitterSum += jitter
                jitterCount++
            }

            val loss = entry.raw.packetLossPercentage
            if (loss != null && loss.isFinite() && loss >= 0.0) {
                lossSum += loss
                lossCount++
            }

            val load = entry.raw.loadDeltaMs
            if (load != null && load.isFinite()) {
                loadSum += load
                loadCount++
            }
        }

        if (!hasSummary) {
            return Result(
                windowDays = windowDays,
                points = points,
                canDrawCurve = canDrawCurve,
                hasSummary = false,
                hasMixedContexts = hasMixedContexts,
                availableNetworks = availableNetworks,
                summaryNetworkType = latestSummaryEntry?.networkType,
                summaryRegionId = latestSummaryEntry?.regionId,
                totalComparableCount = total,
                readyCount = ready,
                cautionCount = caution,
                badCount = bad,
                inconclusiveCount = inconclusiveCount,
                stabilityPercentage = null,
                stabilityTone = MetricTone.UNKNOWN,
                headlineKey = "stability.headline.insufficient",
                minPingMs = if (total > 0) minPing else null,
                avgPingMs = if (total > 0) pingSum / total else null,
                maxPingMs = if (total > 0) maxPing else null,
                rings = null,
                latest = latestPoint
            )
        }

        val pct = (ready * 100.0 / total).roundToInt()
        val latestVerdict = summaryEntries.last().verdict
        val lastTwoBad = summaryEntries.size >= 2 &&
            summaryEntries.last().verdict == VerdictKind.NOT_READY &&
            summaryEntries[summaryEntries.size - 2].verdict == VerdictKind.NOT_READY

        val stabilityTone: MetricTone
        val headlineKey: String
        when {
            pct >= 75 && latestVerdict != VerdictKind.NOT_READY -> {
                stabilityTone = MetricTone.OK
                headlineKey = "stability.headline.stable"
            }
            (pct < 40 && bad > 0) || lastTwoBad -> {
                stabilityTone = MetricTone.BAD
                headlineKey = "stability.headline.unstable"
            }
            ready == 0 && bad == 0 -> {
                stabilityTone = MetricTone.WARN
                headlineKey = "stability.headline.never_ready"
            }
            else -> {
                stabilityTone = MetricTone.WARN
                headlineKey = "stability.headline.moderate"
            }
        }

        val avgPing = pingSum / total
        val avgJitter = if (jitterCount > 0) jitterSum / jitterCount else null
        val avgLoss = if (lossCount > 0) lossSum / lossCount else null
        val avgLoad = if (loadCount > 0) loadSum / loadCount else null

        val rings = Rings(
            ping = buildRing(avgPing, okLimit = 45.0, warnLimit = 90.0, maxScale = 160.0),
            jitter = buildRing(avgJitter, okLimit = 12.0, warnLimit = 25.0, maxScale = 40.0),
            loss = buildRing(avgLoss, okLimit = 1.0, warnLimit = 3.0, maxScale = 10.0),
            load = buildRing(avgLoad, okLimit = 15.0, warnLimit = 40.0, maxScale = 80.0)
        )

        return Result(
            windowDays = windowDays,
            points = points,
            canDrawCurve = canDrawCurve,
            hasSummary = true,
            hasMixedContexts = hasMixedContexts,
            availableNetworks = availableNetworks,
            summaryNetworkType = latestSummaryEntry?.networkType,
            summaryRegionId = latestSummaryEntry?.regionId,
            totalComparableCount = total,
            readyCount = ready,
            cautionCount = caution,
            badCount = bad,
            inconclusiveCount = inconclusiveCount,
            stabilityPercentage = pct,
            stabilityTone = stabilityTone,
            headlineKey = headlineKey,
            minPingMs = minPing,
            avgPingMs = avgPing,
            maxPingMs = maxPing,
            rings = rings,
            latest = latestPoint
        )
    }

    private fun emptyResult(
        windowDays: Int,
        availableNetworks: List<String>,
        inconclusiveCount: Int
    ) = Result(
        windowDays = windowDays,
        points = emptyList(),
        canDrawCurve = false,
        hasSummary = false,
        hasMixedContexts = false,
        availableNetworks = availableNetworks,
        summaryNetworkType = null,
        summaryRegionId = null,
        totalComparableCount = 0,
        readyCount = 0,
        cautionCount = 0,
        badCount = 0,
        inconclusiveCount = inconclusiveCount,
        stabilityPercentage = null,
        stabilityTone = MetricTone.UNKNOWN,
        headlineKey = "stability.headline.empty",
        minPingMs = null,
        avgPingMs = null,
        maxPingMs = null,
        rings = null,
        latest = null
    )

    private fun buildRing(value: Double?, okLimit: Double, warnLimit: Double, maxScale: Double): RingMetric {
        if (value == null || !value.isFinite()) {
            return RingMetric(value = null, tone = MetricTone.UNKNOWN, fillRatio = 0.0)
        }
        val clamped = value.coerceAtLeast(0.0)
        val tone = when {
            clamped <= okLimit -> MetricTone.OK
            clamped <= warnLimit -> MetricTone.WARN
            else -> MetricTone.BAD
        }
        val ratio = when {
            clamped <= okLimit -> {
                val t = if (okLimit <= 0.0) 0.0 else (clamped / okLimit).coerceIn(0.0, 1.0)
                1.0 - (0.15 * t)
            }
            clamped <= warnLimit -> {
                val span = (warnLimit - okLimit).coerceAtLeast(0.0001)
                val t = ((clamped - okLimit) / span).coerceIn(0.0, 1.0)
                0.75 - (0.20 * t)
            }
            else -> {
                val badSpan = (maxScale - warnLimit).coerceAtLeast(0.0001)
                val badT = ((clamped - warnLimit) / badSpan).coerceIn(0.0, 1.0)
                maxOf(0.22, 0.45 - (0.23 * badT))
            }
        }
        return RingMetric(value = value, tone = tone, fillRatio = ratio)
    }

    private fun toPoint(entry: NormalizedEntry, segmentIndex: Int, connectToPrevious: Boolean) = Point(
        capturedAtEpochMs = entry.raw.capturedAtEpochMs,
        pingMs = entry.raw.pingMs!!,
        jitterMs = entry.raw.jitterMs?.takeIf { it.isFinite() && it >= 0.0 },
        packetLossPercentage = entry.raw.packetLossPercentage?.takeIf { it.isFinite() && it >= 0.0 },
        loadDeltaMs = entry.raw.loadDeltaMs?.takeIf { it.isFinite() },
        verdict = entry.verdict,
        gameId = entry.gameId,
        gameTitle = entry.gameTitle,
        networkType = entry.networkType,
        regionId = entry.regionId,
        segmentIndex = segmentIndex,
        connectToPrevious = connectToPrevious
    )

    private fun sliceLatest(entries: List<NormalizedEntry>, maxPoints: Int): List<NormalizedEntry> =
        if (maxPoints > 0 && entries.size > maxPoints) entries.subList(entries.size - maxPoints, entries.size) else entries

    private fun normalize(entry: EntryInput): NormalizedEntry {
        val rawGameId = entry.gameId?.trim()?.takeIf { it.isNotEmpty() }
        val normalizedGameId = if (rawGameId == null || isGeneralGameId(rawGameId)) null else rawGameId
        return NormalizedEntry(
            raw = entry,
            verdict = VerdictKind.parse(entry.verdict),
            gameId = normalizedGameId,
            gameTitle = entry.gameTitle?.trim()?.takeIf { it.isNotEmpty() },
            networkType = normalizeNetwork(entry.networkType),
            regionId = entry.regionId?.trim()?.lowercase()?.takeIf { it.isNotEmpty() },
            platform = entry.platform?.trim()?.uppercase()?.takeIf { it.isNotEmpty() },
            externalLink = entry.declaredExternalLink?.trim()?.uppercase()?.takeIf { it.isNotEmpty() },
            ruleVersion = entry.ruleVersion?.trim()?.takeIf { it.isNotEmpty() }
        )
    }

    private fun sameTimelineContext(a: NormalizedEntry, b: NormalizedEntry): Boolean =
        a.networkType == b.networkType && a.regionId == b.regionId

    private fun sameScopeContext(a: NormalizedEntry, b: NormalizedEntry): Boolean =
        a.networkType == b.networkType &&
            a.regionId == b.regionId &&
            a.platform == b.platform &&
            a.externalLink == b.externalLink

    private fun sameStrictContext(a: NormalizedEntry, b: NormalizedEntry): Boolean =
        sameScopeContext(a, b) && a.ruleVersion == b.ruleVersion

    private fun isGeneralFilter(filter: String?): Boolean {
        val trimmed = filter?.trim() ?: return false
        return trimmed.equals("__general__", ignoreCase = true) || trimmed.equals("general", ignoreCase = true)
    }

    private fun isGeneralGameId(gameId: String): Boolean =
        gameId.equals("general", ignoreCase = true) ||
            gameId.equals("generic-gaming", ignoreCase = true) ||
            gameId.equals("BATTLE_ROYALE_COMPETITIVE", ignoreCase = true) ||
            gameId.equals("MOBILE_REALTIME", ignoreCase = true) ||
            gameId.equals("CASUAL_REALTIME", ignoreCase = true)

    private fun normalizeNetworkFilter(raw: String?): String? {
        val trimmed = raw?.trim()?.uppercase() ?: return null
        if (trimmed.isEmpty() || trimmed == "ALL") return null
        return normalizeNetwork(trimmed)
    }

    private fun normalizeNetwork(raw: String?): String? {
        val norm = raw?.trim()?.uppercase() ?: return null
        return when (norm) {
            "WIFI", "WI-FI", "WLAN" -> "WIFI"
            "CELLULAR", "5G", "4G", "3G", "LTE", "MOBILE", "DADOS", "DADOS MÓVEIS" -> "CELLULAR"
            "ETHERNET", "LAN", "CABLE", "CABO", "WIRED" -> "ETHERNET"
            "OTHER" -> "OTHER"
            else -> null
        }
    }

    private fun networkSortOrder(network: String): Int = when (network) {
        "WIFI" -> 0
        "ETHERNET" -> 1
        "CELLULAR" -> 2
        else -> 3
    }
}
