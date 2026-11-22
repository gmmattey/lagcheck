package com.lagcheck.engine

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Fachada de roteador, causa raiz e bufferbloat: as plataformas chamam o motor e não repetem regra. */
class EngineDiagnosticsFacadeTest {
    private fun kind(json: String) = Regex("\"kind\":\"(\\w+)\"").find(json)?.groupValues?.get(1)
    private fun culprit(json: String) = Regex("\"culprit\":\"(\\w+)\"").find(json)?.groupValues?.get(1)

    @Test fun gatewayNeedsThreeValidResponsesOutOfFive() {
        // Decisão 135, item 8: com menos de 3 respostas em 5 o roteador não é observável.
        assertEquals("UNOBSERVABLE", kind(LagCheckEngine.gatewayOutcome("""{"rttMs":3.0,"jitterMs":0.5,"validResponses":2,"plannedResponses":5}""")))
        assertEquals("DEGRADED", kind(LagCheckEngine.gatewayOutcome("""{"rttMs":3.0,"jitterMs":0.5,"validResponses":3,"plannedResponses":5}""")))
        assertEquals("STABLE", kind(LagCheckEngine.gatewayOutcome("""{"rttMs":3.0,"jitterMs":0.5,"validResponses":5,"plannedResponses":5}""")))
        assertEquals("DEGRADED", kind(LagCheckEngine.gatewayOutcome("""{"rttMs":16.0,"jitterMs":0.5,"validResponses":5,"plannedResponses":5}""")))
        assertEquals("DEGRADED", kind(LagCheckEngine.gatewayOutcome("""{"rttMs":3.0,"jitterMs":10.5,"validResponses":5,"plannedResponses":5}""")))
        assertEquals("UNOBSERVABLE", kind(LagCheckEngine.gatewayOutcome("""{"rttMs":3.0,"validResponses":5,"plannedResponses":5,"isWifi":false}""")))
    }

    @Test fun rootCauseNeverBlamesTheProviderWithoutAPristineGateway() {
        val unstableWan = """"wanP50Ms":40.0,"wanJitterMs":20.0,"wanLossPercentage":3.0"""
        assertEquals("unobservable", culprit(LagCheckEngine.rootCause("""{"gateway":{"kind":"UNOBSERVABLE"},$unstableWan}""")))
        assertEquals("unobservable", culprit(LagCheckEngine.rootCause("""{"gateway":{"kind":"STABLE","rttMs":12.0},$unstableWan}""")))
        assertEquals("internetProvider", culprit(LagCheckEngine.rootCause("""{"gateway":{"kind":"STABLE","rttMs":2.0},$unstableWan}""")))
        assertEquals("localWiFi", culprit(LagCheckEngine.rootCause("""{"gateway":{"kind":"DEGRADED","rttMs":30.0,"lossPercentage":0.0},$unstableWan}""")))
        assertEquals("allClear", culprit(LagCheckEngine.rootCause("""{"gateway":{"kind":"STABLE","rttMs":2.0},"wanP50Ms":30.0,"wanJitterMs":2.0,"wanLossPercentage":0.0}""")))
        assertTrue(LagCheckEngine.rootCause("""{"gateway":{"kind":"STABLE","rttMs":2.0},"wanLossPercentage":0.0}""").contains("root-cause-v2"))
    }

    @Test fun bufferbloatGradeComesFromTheEngine() {
        assertEquals("A+", LagCheckEngine.bufferbloatGrade(-3.0))
        assertEquals("A+", LagCheckEngine.bufferbloatGrade(2.0))
        assertEquals("A", LagCheckEngine.bufferbloatGrade(5.0))
        assertEquals("B", LagCheckEngine.bufferbloatGrade(15.0))
        assertEquals("C", LagCheckEngine.bufferbloatGrade(35.0))
        assertEquals("D", LagCheckEngine.bufferbloatGrade(60.0))
        assertEquals("F", LagCheckEngine.bufferbloatGrade(60.001))
    }

    @Test fun requestAcceptsAnAlreadyClassifiedGateway() {
        val rest = (0 until 60).joinToString(",") { """{"sequence":$it,"outcome":"RECEIVED","rttMs":30.0}""" }
        val out = LagCheckEngine.evaluate("""{"source":"APP_UDP","profile":"BATTLE_ROYALE_COMPETITIVE","rest":[$rest],"gatewayOutcome":{"kind":"DEGRADED","rttMs":25.0,"lossPercentage":20.0}}""")
        assertTrue(out.contains("\"verdict\":\"CAUTION\""), out)
        assertTrue(out.contains("APPROACH_ROUTER"), out)
    }

    @Test fun insufficientTransferIsPreservedWithoutInventingLoadImpact() {
        val rest = (0 until 60).joinToString(",") { """{"sequence":$it,"outcome":"RECEIVED","rttMs":30.0}""" }
        val out = LagCheckEngine.evaluate("""{"source":"WEB_HTTPS","profile":"BATTLE_ROYALE_COMPETITIVE","rest":[$rest],"loadTransfer":"INSUFFICIENT_TRANSFER"}""")

        assertTrue(out.contains("\"verdict\":\"READY\""), out)
        assertTrue(out.contains("\"loadTransfer\":\"INSUFFICIENT_TRANSFER\""), out)
        assertFalse(out.contains("\"loadImpact\":{\"tier\""), out)
    }

    @Test fun measuredLoadWithoutProbesIsInconclusiveInsteadOfACompleteRestResult() {
        val rest = (0 until 60).joinToString(",") { """{"sequence":$it,"outcome":"RECEIVED","rttMs":30.0}""" }
        val out = LagCheckEngine.evaluate("""{"source":"APP_UDP","profile":"BATTLE_ROYALE_COMPETITIVE","rest":[$rest],"loadTransfer":"MEASURED"}""")

        assertTrue(out.contains("\"verdict\":\"INCONCLUSIVE\""), out)
        assertTrue(out.contains("\"inconclusiveReason\":\"POOR_SAMPLE_QUALITY\""), out)
    }
}
