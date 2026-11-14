package com.lagcheck.domain.rules

import com.lagcheck.domain.model.ProbeOutcome
import org.junit.Assert.*
import org.junit.Test

class RegionalSelectionRuleTest {

    data class TestContext(val value: String)

    data class TestCandidate(
        override val regionId: String,
        override val priority: Int,
        override val catalogVersion: String,
        override val context: TestContext
    ) : RegionalSelectionCandidate<TestContext>

    private val defaultContext = TestContext("ctx")
    private val defaultCatalog = "v1"

    private fun candidate(id: String, priority: Int = 1) = TestCandidate(id, priority, defaultCatalog, defaultContext)

    private fun snapshot(vararg candidates: TestCandidate) = RegionalSelectionSnapshot(
        catalogVersion = defaultCatalog,
        context = defaultContext,
        candidates = candidates.toList()
    )

    private fun sample(rtt: Double) = RegionalPreReadSample(ProbeOutcome.RECEIVED, rtt)
    private fun errorSample() = RegionalPreReadSample(ProbeOutcome.TRANSPORT_ERROR, null)

    @Test
    fun `clear lead selects candidate with lowest p50`() {
        val snap = snapshot(candidate("us-east"), candidate("us-west"))
        val samples = mapOf(
            "us-east" to listOf(sample(10.0), sample(10.0), sample(10.0)),
            "us-west" to listOf(sample(30.0), sample(30.0), sample(30.0))
        )
        val decision = RegionalSelectionRule.select(snap, samples)
        assertTrue(decision is RegionalSelectionDecision.Selected)
        val selected = (decision as RegionalSelectionDecision.Selected).result
        assertEquals("us-east", selected.selected.regionId)
        assertEquals(10.0, selected.p50Milliseconds, 0.01)
    }

    @Test
    fun `near tie by count`() {
        val snap = snapshot(candidate("us-east"), candidate("us-west"))
        // Both within tie window (5ms)
        // us-east p50=10, 2 valid responses
        // us-west p50=12, 3 valid responses
        val samples = mapOf(
            "us-east" to listOf(sample(10.0), sample(10.0), errorSample()),
            "us-west" to listOf(sample(12.0), sample(12.0), sample(12.0))
        )
        val decision = RegionalSelectionRule.select(snap, samples)
        assertTrue(decision is RegionalSelectionDecision.Selected)
        val selected = (decision as RegionalSelectionDecision.Selected).result
        assertEquals("us-west", selected.selected.regionId)
    }

    @Test
    fun `tie by priority and id`() {
        val snap = snapshot(candidate("b-region", 2), candidate("a-region", 1))
        // Both p50=10, valid=3
        val samples = mapOf(
            "b-region" to listOf(sample(10.0), sample(10.0), sample(10.0)),
            "a-region" to listOf(sample(10.0), sample(10.0), sample(10.0))
        )
        val decision = RegionalSelectionRule.select(snap, samples)
        assertTrue(decision is RegionalSelectionDecision.Selected)
        val selected = (decision as RegionalSelectionDecision.Selected).result
        assertEquals("a-region", selected.selected.regionId) // priority 1 is better? Wait, sort is ascending?
        // Let's check rule: `.thenBy { it.candidate.priority }` -> lower value first.
    }

    @Test
    fun `manual override selects specific region`() {
        val snap = snapshot(candidate("us-east"), candidate("us-west"))
        val samples = mapOf(
            "us-east" to listOf(sample(10.0), sample(10.0)),
            "us-west" to listOf(sample(30.0), sample(30.0))
        )
        val decision = RegionalSelectionRule.select(snap, samples, manualRegionId = "us-west")
        assertTrue(decision is RegionalSelectionDecision.Selected)
        val selected = (decision as RegionalSelectionDecision.Selected).result
        assertEquals("us-west", selected.selected.regionId)
        assertEquals(RegionalSelectionMode.MANUAL, selected.mode)
    }

    @Test
    fun `less than 2 valid UDPs is inconclusive`() {
        val snap = snapshot(candidate("us-east"))
        val samples = mapOf(
            "us-east" to listOf(sample(10.0), errorSample())
        )
        val decision = RegionalSelectionRule.select(snap, samples)
        assertTrue(decision is RegionalSelectionDecision.Inconclusive)
        assertEquals(RegionalSelectionInconclusiveReason.NO_VIABLE_REGIONAL_CANDIDATE, (decision as RegionalSelectionDecision.Inconclusive).reason)
    }

    @Test
    fun `snapshot validation fails on invalid priority`() {
        assertThrows(RegionalSelectionError::class.java) {
            snapshot(candidate("us-east", -1))
        }
    }

    @Test
    fun `snapshot validation fails when empty`() {
        assertThrows(RegionalSelectionError::class.java) {
            RegionalSelectionSnapshot<TestContext, TestCandidate>(defaultCatalog, defaultContext, emptyList())
        }
    }

    @Test
    fun `snapshot validation fails on duplicate region`() {
        assertThrows(RegionalSelectionError::class.java) {
            snapshot(candidate("us-east"), candidate("us-east"))
        }
    }

    @Test
    fun `snapshot validation fails outside snapshot`() {
        assertThrows(RegionalSelectionError::class.java) {
            val c = TestCandidate("us-east", 1, "v2", defaultContext) // wrong catalog
            RegionalSelectionSnapshot(defaultCatalog, defaultContext, listOf(c))
        }
    }
}
