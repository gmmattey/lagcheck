package com.lagcheck.domain.vectors

/**
 * Entradas e expectativas normativas das Decisões 135 e 136.
 *
 * Este arquivo não conhece o motor: o runner de cada alvo converte estes tipos
 * para os contratos de domínio e compara o resultado. Todas as séries APP_UDP
 * têm os 60 probes planejados, nas sequências 0..59.
 */
enum class VProfile { BATTLE_ROYALE_COMPETITIVE, MOBILE_REALTIME, CASUAL_REALTIME }

enum class VSource { APP_UDP, WEB_HTTPS }

enum class VOutcome { RECEIVED, TIMEOUT, TRANSPORT_ERROR }

data class VSample(val sequence: Int, val outcome: VOutcome, val rttMs: Double? = null)

enum class VGateway { STABLE, DEGRADED, UNOBSERVABLE }

enum class VLoadTransfer { MEASURED, FAILED_NO_BYTES, NOT_RUN }

enum class VVerdict { READY, CAUTION, NOT_READY, INCONCLUSIVE }

enum class VTier { NONE, LIGHT, MATERIAL, SEVERE }

data class VExpected(
    val verdict: VVerdict,
    val score: Int? = null,
    val assertNoScore: Boolean = false,
    val loadTier: VTier? = null,
    val primaryCause: String? = null,
    val spikePattern: String? = null,
    val packetLossPercentage: Double? = null,
    val mustNotHaveRecommendations: List<String> = emptyList(),
    val mustHaveRecommendations: List<String> = emptyList(),
    /** Também cobre causas secundárias; necessário para TAIL-01. */
    val mustNotHaveCauses: List<String> = emptyList(),
)

data class Vector(
    val id: String,
    val description: String,
    val profile: VProfile = VProfile.BATTLE_ROYALE_COMPETITIVE,
    val source: VSource = VSource.APP_UDP,
    val rest: List<VSample>,
    val load: List<VSample>? = null,
    val loadTransfer: VLoadTransfer = VLoadTransfer.NOT_RUN,
    val gateway: VGateway = VGateway.UNOBSERVABLE,
    val expected: VExpected,
)

private const val plannedProbeCount = 60

private fun received(count: Int, rttMs: Double, from: Int = 0): List<VSample> =
    (from until from + count).map { VSample(it, VOutcome.RECEIVED, rttMs) }

private fun timeouts(count: Int, from: Int = 0): List<VSample> =
    (from until from + count).map { VSample(it, VOutcome.TIMEOUT) }

/** Produz a série completa; sequências ausentes do mapa usam [defaultRttMs]. */
private fun withRtt(
    rttBySequence: Map<Int, Double>,
    defaultRttMs: Double = 30.0,
    timeoutSequences: Set<Int> = emptySet(),
): List<VSample> =
    (0 until plannedProbeCount).map { sequence ->
        if (sequence in timeoutSequences) VSample(sequence, VOutcome.TIMEOUT)
        else VSample(sequence, VOutcome.RECEIVED, rttBySequence[sequence] ?: defaultRttMs)
    }

private fun receivedAt(sequences: Set<Int>, rttMs: Double): List<VSample> =
    (0 until plannedProbeCount).map { sequence ->
        if (sequence in sequences) VSample(sequence, VOutcome.RECEIVED, rttMs)
        else VSample(sequence, VOutcome.TIMEOUT)
    }

private fun alternating(firstRttMs: Double, secondRttMs: Double): List<VSample> =
    withRtt(
        (0 until plannedProbeCount).associateWith { sequence ->
            if (sequence % 2 == 0) firstRttMs else secondRttMs
        },
    )

object NormativeVectors {
    val all: List<Vector> = listOf(
        // Score = round(0.35×100 + 0.30×100 + 0.20×100 + 0.15×100) = 100.
        Vector(
            id = "V135-01",
            description = "60 respostas UDP de 30 ms.",
            rest = received(60, 30.0),
            expected = VExpected(VVerdict.READY, score = 100, primaryCause = "STABLE_CONNECTION"),
        ),
        // Perda = 1/60×100 = 1,6667%; perdaC = 73,333; consistência = 97,333;
        // score = round(35 + 22 + 20 + 14,6) = 92. Não cruza o guardrail de 3%.
        Vector(
            id = "V135-02",
            description = "59 respostas de 30 ms e um timeout: perda de 1,6667% sem guardrail.",
            rest = received(59, 30.0) + timeouts(1, 59),
            expected = VExpected(
                verdict = VVerdict.READY,
                score = 92,
                packetLossPercentage = 1.6666666666666667,
                // Decisão 136: veredito "pronto" não pode vir com "evite ranked".
                mustNotHaveRecommendations = listOf("AVOID_RANKED"),
            ),
        ),
        Vector(
            id = "REC-01",
            description = "Mobile: um timeout em 60 fica abaixo do guardrail de 5% e não recomenda evitar ranked.",
            profile = VProfile.MOBILE_REALTIME,
            rest = received(59, 30.0) + timeouts(1, 59),
            expected = VExpected(VVerdict.READY, mustNotHaveRecommendations = listOf("AVOID_RANKED")),
        ),
        Vector(
            id = "REC-02",
            description = "Casual: um timeout em 60 fica abaixo do guardrail de 3% e não recomenda evitar ranked.",
            profile = VProfile.CASUAL_REALTIME,
            rest = received(59, 30.0) + timeouts(1, 59),
            expected = VExpected(VVerdict.READY, mustNotHaveRecommendations = listOf("AVOID_RANKED")),
        ),
        Vector(
            id = "REC-03",
            description = "BR: dois timeouts cruzam o guardrail; veredito e recomendação concordam.",
            rest = received(58, 30.0) + timeouts(2, 58),
            expected = VExpected(VVerdict.NOT_READY, mustHaveRecommendations = listOf("AVOID_RANKED")),
        ),
        // Perda = 2/60×100 = 3,3333%; perdaC = 50; score bruto = round(84,25) = 84;
        // o guardrail de perda limita a nota unificada de NOT_READY a 59.
        Vector(
            id = "V135-03",
            description = "Dois timeouts cruzam o guardrail de perda de Battle Royale.",
            rest = received(58, 30.0) + timeouts(2, 58),
            expected = VExpected(
                verdict = VVerdict.NOT_READY,
                score = 59,
                primaryCause = "PACKET_LOSS",
                packetLossPercentage = 3.3333333333333335,
            ),
        ),
        Vector(
            id = "V135-04",
            description = "19 respostas e 41 timeouts: abaixo do mínimo de 20 respostas válidas.",
            rest = received(19, 30.0) + timeouts(41, 19),
            expected = VExpected(VVerdict.INCONCLUSIVE, assertNoScore = true),
        ),
        // Perda = 40/60×100 = 66,6667%; perdaC = 0; consistência = 90;
        // score bruto = round(35 + 0 + 20 + 13,5) = 69; guardrail de perda → 59.
        // Avaliação pura da série final: o watchdog de transporte não entra neste vetor.
        Vector(
            id = "V135-05",
            description = "20 respostas é o mínimo válido; 40 timeouts ainda tornam a perda determinante.",
            rest = received(20, 30.0) + timeouts(40, 20),
            expected = VExpected(
                verdict = VVerdict.NOT_READY,
                score = 59,
                primaryCause = "PACKET_LOSS",
                packetLossPercentage = 66.66666666666667,
            ),
        ),
        // Jitter = 680/59 = 11,525 ms; spikes = 2/60 = 3,333%; score bruto = 95.
        // Dois severos isolados sofrem o teto 74, mas spike-pattern-v2 impede NOT_READY.
        Vector(
            id = "V135-06",
            description = "Dois picos severos isolados, nas sequências 5 e 40.",
            rest = withRtt(mapOf(5 to 200.0, 40 to 200.0)),
            expected = VExpected(
                verdict = VVerdict.CAUTION,
                score = 74,
                spikePattern = "ISOLATED",
            ),
        ),
        // Jitter = 1.140/59 = 19,322 ms; spikes = 3/60 = 5%; score bruto = 90.
        // O teto por severos é 74; padrão recorrente com >= 2 severos torna a nota unificada 59.
        Vector(
            id = "V135-07",
            description = "Três picos severos recorrentes, nas sequências 10, 12 e 14.",
            rest = withRtt(mapOf(10 to 220.0, 12 to 220.0, 14 to 220.0)),
            expected = VExpected(
                verdict = VVerdict.NOT_READY,
                score = 59,
                primaryCause = "SEVERE_SPIKES",
                spikePattern = "RECURRING",
            ),
        ),
        // LatênciaC = 30 (P50 95 ms); demais componentes = 100; score = round(75,5) = 76.
        // readiness-v3 não aplica margem de confiança ao veredito.
        Vector(
            id = "V135-08",
            description = "P50 de 95 ms sem perda continua READY sem margem de confiança.",
            rest = received(60, 95.0),
            expected = VExpected(VVerdict.READY, score = 76),
        ),
        Vector(
            id = "V135-09",
            description = "Repouso perfeito; carga transferiu bytes, mas só 19 respostas válidas espalhadas.",
            rest = received(60, 30.0),
            load = receivedAt((0..54 step 3).toSet(), 30.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.INCONCLUSIVE, assertNoScore = true),
        ),
        // Repouso perfeito: score = 100. Carga sem bytes não produz tier nem rebaixa o repouso.
        Vector(
            id = "V135-10",
            description = "Falha de carga sem bytes: o resultado do repouso vale sem conclusão sobre carga.",
            rest = received(60, 30.0),
            loadTransfer = VLoadTransfer.FAILED_NO_BYTES,
            expected = VExpected(VVerdict.READY, score = 100, loadTier = null),
        ),

        // Repouso perfeito: score = 100; ΔP50 = 12 ms, abaixo de 15 ms no perfil BR.
        Vector(
            id = "DLI3-01",
            description = "BR: 28 → 40 ms, ΔP50 12 ms, impacto leve.",
            rest = received(60, 28.0),
            load = received(60, 40.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.READY, score = 100, loadTier = VTier.LIGHT),
        ),
        // Repouso perfeito: score = 100; ΔP50 = 17 ms, material; CAUTION limita a nota unificada a 74.
        Vector(
            id = "DLI3-02",
            description = "BR: 28 → 45 ms, ΔP50 17 ms, impacto material.",
            rest = received(60, 28.0),
            load = received(60, 45.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.CAUTION, score = 74, loadTier = VTier.MATERIAL),
        ),
        // Repouso perfeito: score = 100; ΔP50 = 37 ms, severo; NOT_READY limita a nota unificada a 59.
        Vector(
            id = "DLI3-03",
            description = "BR: 28 → 65 ms, ΔP50 37 ms, impacto severo.",
            rest = received(60, 28.0),
            load = received(60, 65.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.NOT_READY, score = 59, loadTier = VTier.SEVERE),
        ),
        // Repouso perfeito: score = 100. A carga alterna 32/44 ms: P50 = 38 e jitter = 12;
        // Δjitter = 12 ms (>= 10), portanto material e CAUTION com nota unificada 74.
        Vector(
            id = "DLI3-04",
            description = "BR: 30 → P50 38 ms; jitter da carga alternado em 12 ms gera impacto material.",
            rest = received(60, 30.0),
            load = alternating(32.0, 44.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.CAUTION, score = 74, loadTier = VTier.MATERIAL),
        ),
        // Repouso perfeito no perfil mobile: score = 100; ΔP50 = 20 ms, abaixo de 25 ms, leve.
        Vector(
            id = "DLI3-05",
            description = "Mobile realtime: 35 → 55 ms, impacto leve pela tolerância do perfil.",
            profile = VProfile.MOBILE_REALTIME,
            rest = received(60, 35.0),
            load = received(60, 55.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.READY, score = 100, loadTier = VTier.LIGHT),
        ),
        // Repouso perfeito no perfil casual: score = 100; ΔP50 = 35 ms, abaixo de 40 ms, leve.
        Vector(
            id = "DLI3-06",
            description = "Casual realtime: 50 → 85 ms, impacto leve pela tolerância do perfil.",
            profile = VProfile.CASUAL_REALTIME,
            rest = received(60, 50.0),
            load = received(60, 85.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.READY, score = 100, loadTier = VTier.LIGHT),
        ),
        // Decisão 136 (deep-load-impact-v4): 1 pacote a mais sob carga é ruído estatístico e não muda o tier.
        Vector(
            id = "DLI3-07",
            description = "BR: um timeout adicional só na carga não é degradação.",
            rest = received(60, 30.0),
            load = received(59, 30.0) + timeouts(1, 59),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.READY, score = 100, loadTier = VTier.NONE),
        ),
        // 2 pacotes a mais (3,33%): material em todos os perfis → CAUTION 74.
        Vector(
            id = "DLI4-01",
            description = "BR: dois timeouts adicionais sob carga são material.",
            rest = received(60, 30.0),
            load = received(58, 30.0) + timeouts(2, 58),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.CAUTION, score = 74, loadTier = VTier.MATERIAL),
        ),
        // 3 pacotes a mais (5%): severo no BR → NOT_READY 59.
        Vector(
            id = "DLI4-02",
            description = "BR: três timeouts adicionais sob carga são severos.",
            rest = received(60, 30.0),
            load = received(57, 30.0) + timeouts(3, 57),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.NOT_READY, score = 59, loadTier = VTier.SEVERE),
        ),
        Vector(
            id = "DLI4-03",
            description = "Mobile: três timeouts adicionais sob carga ainda são material.",
            profile = VProfile.MOBILE_REALTIME,
            rest = received(60, 30.0),
            load = received(57, 30.0) + timeouts(3, 57),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.CAUTION, score = 74, loadTier = VTier.MATERIAL),
        ),
        Vector(
            id = "DLI4-04",
            description = "Mobile: quatro timeouts adicionais sob carga são severos.",
            profile = VProfile.MOBILE_REALTIME,
            rest = received(60, 30.0),
            load = received(56, 30.0) + timeouts(4, 56),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.NOT_READY, score = 59, loadTier = VTier.SEVERE),
        ),
        // Casual: 6 spikes de 200 ms (offset 60 sobre P50 50) sob carga, não adjacentes.
        // Δjitter = 12×150/59 = 30,5 ms (material, < 35); Δspikes = 6 → severo.
        Vector(
            id = "DLI4-05",
            description = "Casual: seis spikes a mais sob carga são severos.",
            profile = VProfile.CASUAL_REALTIME,
            rest = received(60, 50.0),
            load = withRtt(listOf(5, 15, 25, 35, 45, 55).associateWith { 200.0 }, defaultRttMs = 50.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.NOT_READY, score = 59, loadTier = VTier.SEVERE),
        ),
        // Mesmo cenário com 5 spikes: Δjitter = 25,4 ms (material), Δspikes 5 < 6 → material.
        Vector(
            id = "DLI4-06",
            description = "Casual: cinco spikes a mais sob carga ficam no material.",
            profile = VProfile.CASUAL_REALTIME,
            rest = received(60, 50.0),
            load = withRtt(listOf(5, 15, 25, 35, 45).associateWith { 200.0 }, defaultRttMs = 50.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.CAUTION, score = 74, loadTier = VTier.MATERIAL),
        ),
        // Repouso perfeito: score = 100; ΔP50 = 15,0 ms usa comparação >= e é material → 74.
        Vector(
            id = "DLI3-08",
            description = "BR: ΔP50 exatamente 15,0 ms é material.",
            rest = received(60, 30.0),
            load = received(60, 45.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.CAUTION, score = 74, loadTier = VTier.MATERIAL),
        ),
        // Repouso perfeito: score = 100; ΔP50 = 14,9 ms fica abaixo de 15 ms, leve.
        Vector(
            id = "DLI3-09",
            description = "BR: ΔP50 de 14,9 ms continua leve.",
            rest = received(60, 30.0),
            load = received(60, 44.9),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.READY, score = 100, loadTier = VTier.LIGHT),
        ),
        // Repouso perfeito: score = 100; ΔP50 = 35,0 ms usa comparação >= e é severo → 59.
        Vector(
            id = "DLI3-10",
            description = "BR: ΔP50 exatamente 35,0 ms é severo.",
            rest = received(60, 30.0),
            load = received(60, 65.0),
            loadTransfer = VLoadTransfer.MEASURED,
            expected = VExpected(VVerdict.NOT_READY, score = 59, loadTier = VTier.SEVERE),
        ),

        // P50 = 13; P95 = 24; razão = 1,846, mas ΔP95 = 11 (< 20) e P95 <= 45.
        // Score = round(35 + 30 + 20 + 0,15×85,692) = 98; cauda não pode aparecer como causa.
        Vector(
            id = "TAIL-01",
            description = "Razão P95/P50 alta em RTT baixo não é latência de cauda pela regra v3.",
            rest = withRtt(
                (56 until 60).associateWith { 24.0 },
                defaultRttMs = 13.0,
            ),
            expected = VExpected(
                verdict = VVerdict.READY,
                score = 98,
                primaryCause = "STABLE_CONNECTION",
                mustNotHaveCauses = listOf("TAIL_LATENCY"),
            ),
        ),
        // Perda = 2/60×100 = 3,3333%; score bruto = 84, guardrail de perda → nota unificada 59.
        Vector(
            id = "GW-01",
            description = "Perda externa com gateway não observável não atribui instabilidade à rota local.",
            rest = received(58, 30.0) + timeouts(2, 58),
            expected = VExpected(
                verdict = VVerdict.NOT_READY,
                score = 59,
                primaryCause = "PACKET_LOSS",
                mustNotHaveRecommendations = listOf("ROUTE_INSTABILITY"),
            ),
        ),
        // Perda = 2/60×100 = 3,3333%; score bruto = 84, guardrail de perda → nota unificada 59.
        Vector(
            id = "GW-02",
            description = "A mesma perda com gateway degradado oferece a recomendação de se aproximar do roteador.",
            rest = received(58, 30.0) + timeouts(2, 58),
            gateway = VGateway.DEGRADED,
            expected = VExpected(
                verdict = VVerdict.NOT_READY,
                score = 59,
                primaryCause = "PACKET_LOSS",
                mustHaveRecommendations = listOf("APPROACH_ROUTER"),
            ),
        ),
        Vector(
            id = "WEB-01",
            description = "Medição HTTPS do site usa latência, mas não recebe LagCheck Score.",
            source = VSource.WEB_HTTPS,
            rest = received(60, 30.0),
            expected = VExpected(
                verdict = VVerdict.READY,
                assertNoScore = true,
                primaryCause = "STABLE_CONNECTION",
            ),
        ),
        Vector(
            id = "WEB-02",
            description = "Timeouts HTTPS não são perda UDP: o site permanece READY, sem score.",
            source = VSource.WEB_HTTPS,
            rest = received(50, 30.0) + timeouts(10, 50),
            expected = VExpected(
                verdict = VVerdict.READY,
                assertNoScore = true,
                primaryCause = "STABLE_CONNECTION",
            ),
        ),
    )
}
