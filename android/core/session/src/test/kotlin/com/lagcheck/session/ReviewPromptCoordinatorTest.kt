package com.lagcheck.session

import com.lagcheck.domain.model.GameReadinessVerdict
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReviewPromptCoordinatorTest {
    private val baseEpochMillis = 1700000000000L

    @Test
    fun coordinatorAccumulatesReadyChecksAndTriggersOnThird() {
        val store = InMemoryReviewPromptStore()
        val coordinator = ReviewPromptCoordinator(
            store = store,
            appVersionProvider = { "1.0.0" }
        )

        // 1º check READY -> false
        val p1 = coordinator.recordMeasurementCompleted(GameReadinessVerdict.READY, baseEpochMillis)
        assertFalse(p1)
        assertEquals(1, coordinator.currentState().successfulReadyChecksCount)

        // Check CAUTION, NOT_READY ou INCONCLUSIVE -> não incrementa readyCount e retorna false
        assertFalse(coordinator.recordMeasurementCompleted(GameReadinessVerdict.CAUTION, baseEpochMillis))
        assertFalse(coordinator.recordMeasurementCompleted(GameReadinessVerdict.NOT_READY, baseEpochMillis))
        assertFalse(coordinator.recordMeasurementCompleted(GameReadinessVerdict.INCONCLUSIVE, baseEpochMillis))
        assertEquals(1, coordinator.currentState().successfulReadyChecksCount)

        // 2º check READY -> false
        val p2 = coordinator.recordMeasurementCompleted(GameReadinessVerdict.READY, baseEpochMillis)
        assertFalse(p2)
        assertEquals(2, coordinator.currentState().successfulReadyChecksCount)

        // 3º check READY -> TRUE!
        val p3 = coordinator.recordMeasurementCompleted(GameReadinessVerdict.READY, baseEpochMillis)
        assertTrue(p3)
        assertEquals(3, coordinator.currentState().successfulReadyChecksCount)
        // Antes da confirmação de exibição, versão e data continuam nulas (não queima cooldown prematuro)
        org.junit.Assert.assertNull(coordinator.currentState().lastPromptedVersion)

        // Exibição confirmada na UI:
        coordinator.recordPromptPresented(baseEpochMillis)
        assertEquals("1.0.0", coordinator.currentState().lastPromptedVersion)
        assertEquals(baseEpochMillis, coordinator.currentState().lastPromptedEpochMillis)

        // 4º check na mesma versão -> false (bloqueado por mesma versão)
        val p4 = coordinator.recordMeasurementCompleted(GameReadinessVerdict.READY, baseEpochMillis + 1000L)
        assertFalse(p4)
    }

    @Test
    fun coordinatorHandlesPersistentStoreRoundtrip() {
        val store = InMemoryReviewPromptStore()
        var version = "1.0.0"
        val coordinator1 = ReviewPromptCoordinator(store = store, appVersionProvider = { version })

        coordinator1.recordMeasurementCompleted(GameReadinessVerdict.READY, baseEpochMillis)
        coordinator1.recordMeasurementCompleted(GameReadinessVerdict.READY, baseEpochMillis)
        assertTrue(coordinator1.recordMeasurementCompleted(GameReadinessVerdict.READY, baseEpochMillis))
        coordinator1.recordPromptPresented(baseEpochMillis)

        // Nova instância com o mesmo store simulando relançamento
        val coordinator2 = ReviewPromptCoordinator(store = store, appVersionProvider = { version })
        assertFalse(coordinator2.recordMeasurementCompleted(GameReadinessVerdict.READY, baseEpochMillis))

        // Nova versão e 95 dias depois
        version = "1.1.0"
        val ninetyFiveDaysMillis = 95L * 24L * 3600L * 1000L
        val futureEpochMillis = baseEpochMillis + ninetyFiveDaysMillis
        assertTrue(coordinator2.recordMeasurementCompleted(GameReadinessVerdict.READY, futureEpochMillis))
    }
}
