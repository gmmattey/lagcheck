package com.lagcheck.network.transport

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.ProbeOutcome
import org.junit.Test

class ProbeLedgerTest {
    private val ms = 1_000_000L
    private fun payload(i: Int) = byteArrayOf(i.toByte(), 9, 9)

    private fun ledger(count: Int = 3) =
        ProbeLedger(List(count) { it to payload(it) }) { req, resp -> req.contentEquals(resp) }

    @Test fun matchesEchoToItsProbeAndComputesRtt() {
        val l = ledger()
        l.register(0, payload(0), 0)
        l.register(1, payload(1), 500 * ms)
        val s = l.accept(payload(1), 530 * ms)!!
        assertThat(s.sequence).isEqualTo(1)
        assertThat(s.roundTripMilliseconds).isWithin(1e-9).of(30.0)
        assertThat(s.outcome).isEqualTo(ProbeOutcome.RECEIVED)
        assertThat(s.arrivalIndex).isEqualTo(0)
    }

    @Test fun arrivalIndexFollowsReceptionOrderEvenWhenReordered() {
        val l = ledger()
        l.register(0, payload(0), 0); l.register(1, payload(1), 100 * ms)
        val second = l.accept(payload(1), 150 * ms)!!
        val first = l.accept(payload(0), 160 * ms)!!
        assertThat(second.arrivalIndex).isEqualTo(0)
        assertThat(first.arrivalIndex).isEqualTo(1)
        assertThat(first.sequence).isLessThan(second.sequence)
    }

    @Test fun responseAfterTwoSecondsIsNotAcceptedAndBecomesTimeout() {
        val l = ledger(1)
        l.register(0, payload(0), 0)
        assertThat(l.accept(payload(0), 2_000 * ms)).isNull()
        val out = l.finish()
        assertThat(out.first().outcome).isEqualTo(ProbeOutcome.TIMEOUT)
        assertThat(out.count { it.outcome == ProbeOutcome.INVALID_RESPONSE }).isEqualTo(1)
    }

    @Test fun responseJustInsideTimeoutIsAccepted() {
        val l = ledger(1)
        l.register(0, payload(0), 0)
        assertThat(l.accept(payload(0), 1_999 * ms)).isNotNull()
    }

    @Test fun uncorrelatedPayloadIsInvalidAndDoesNotReplaceTheTimeout() {
        val l = ledger(1)
        l.register(0, payload(0), 0)
        assertThat(l.accept(byteArrayOf(1, 2, 3), 10 * ms)).isNull()
        val out = l.finish()
        assertThat(out[0].outcome).isEqualTo(ProbeOutcome.TIMEOUT)
        assertThat(out[1].outcome).isEqualTo(ProbeOutcome.INVALID_RESPONSE)
    }

    @Test fun duplicateEchoDoesNotCreateASecondSample() {
        val l = ledger(1)
        l.register(0, payload(0), 0)
        assertThat(l.accept(payload(0), 10 * ms)).isNotNull()
        assertThat(l.accept(payload(0), 20 * ms)).isNull()
    }

    @Test fun unregisteredProbeCannotBeMatched() {
        val l = ledger(1)
        assertThat(l.accept(payload(0), 10 * ms)).isNull()
    }

    @Test fun transportErrorOnlyAppliesToSentProbes() {
        val l = ledger(2)
        l.register(0, payload(0), 0)
        l.markTransportError(0)
        l.markTransportError(1) // nunca enviado
        val out = l.finish()
        assertThat(out[0].outcome).isEqualTo(ProbeOutcome.TRANSPORT_ERROR)
        assertThat(out[1].outcome).isEqualTo(ProbeOutcome.TIMEOUT)
    }

    @Test fun snapshotOnlyCountsExpiredTimeouts() {
        val l = ledger(3)
        l.register(0, payload(0), 0); l.register(1, payload(1), 500 * ms)
        assertThat(l.snapshot(1_000 * ms)).isEmpty()
        assertThat(l.snapshot(2_000 * ms).map { it.sequence }).containsExactly(0)
        assertThat(l.snapshot(2_600 * ms).map { it.sequence }).containsExactly(0, 1).inOrder()
    }

    @Test fun finishIsSortedBySequence() {
        val l = ledger(3)
        l.register(2, payload(2), 0)
        assertThat(l.finish().map { it.sequence }).containsExactly(0, 1, 2).inOrder()
    }
}
