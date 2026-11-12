package com.lagcheck.domain.rules

import com.lagcheck.domain.model.CgnatStatus
import com.lagcheck.domain.model.DoubleNatStatus
import com.lagcheck.domain.model.NatTopologySnapshot
import com.lagcheck.domain.model.NatType

object NatTopologyEvaluator {
    fun evaluate(
        localIp: String?,
        publicIp: String?,
        externalPort: Int?,
        isPortMappingConsistent: Boolean = true,
        detectedDoubleHop: Boolean = false
    ): NatTopologySnapshot {
        if (publicIp.isNullOrEmpty()) return NatTopologySnapshot.INCONCLUSIVE
        val cgnat = isRfc6598Cgnat(publicIp)
        val natType = when {
            localIp != null && localIp == publicIp -> NatType.TYPE_1_OPEN
            cgnat || !isPortMappingConsistent -> NatType.TYPE_3_STRICT
            detectedDoubleHop -> NatType.TYPE_3_STRICT
            else -> NatType.TYPE_2_MODERATE
        }
        return NatTopologySnapshot(
            natType = natType,
            cgnatStatus = if (cgnat) CgnatStatus.DETECTED else CgnatStatus.NOT_DETECTED,
            doubleNatStatus = if (detectedDoubleHop) DoubleNatStatus.SUSPECT_OR_DETECTED else DoubleNatStatus.NOT_DETECTED,
            publicIpMasked = maskIp(publicIp),
            localIpMasked = localIp?.let(::maskIp),
            externalPort = externalPort
        )
    }

    /** 100.64.0.0/10 (RFC 6598): 100.64.0.0 a 100.127.255.255. */
    fun isRfc6598Cgnat(ip: String): Boolean {
        val parts = ip.split('.').mapNotNull { it.toIntOrNull() }
        return parts.size == 4 && ip.split('.').size == 4 && parts[0] == 100 && parts[1] in 64..127
    }

    /** Preserva só os dois primeiros octetos. */
    fun maskIp(ip: String): String {
        val parts = ip.split('.')
        return if (parts.size == 4) "${parts[0]}.${parts[1]}.***.***" else "***.***.***.***"
    }
}
