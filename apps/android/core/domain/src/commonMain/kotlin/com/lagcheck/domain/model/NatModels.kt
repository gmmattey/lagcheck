package com.lagcheck.domain.model

/** Tipo de NAT para multiplayer (Decisão 32). */
enum class NatType(val rawValue: String, val titleKey: String, val shortLabel: String) {
    TYPE_1_OPEN("type_1_open", "nat.type1.open.title", "Type 1 (Open)"),
    TYPE_2_MODERATE("type_2_moderate", "nat.type2.moderate.title", "Type 2 (Moderate)"),
    TYPE_3_STRICT("type_3_strict", "nat.type3.strict.title", "Type 3 (Strict)"),
    INCONCLUSIVE("inconclusive", "nat.inconclusive.title", "Inconclusive");

    val isMultiplayerRestricted: Boolean get() = this == TYPE_3_STRICT
}

enum class CgnatStatus { NOT_DETECTED, DETECTED, INCONCLUSIVE; val isImpacted: Boolean get() = this == DETECTED }

enum class DoubleNatStatus { NOT_DETECTED, SUSPECT_OR_DETECTED, INCONCLUSIVE; val isImpacted: Boolean get() = this == SUSPECT_OR_DETECTED }

/** Topologia aferida via STUN (RFC 5389). IPs só mascarados; o IP completo não é persistido nem enviado. */
data class NatTopologySnapshot(
    val natType: NatType,
    val cgnatStatus: CgnatStatus,
    val doubleNatStatus: DoubleNatStatus,
    val publicIpMasked: String? = null,
    val localIpMasked: String? = null,
    val externalPort: Int? = null,
    val serverHost: String = "stun.l.google.com"
) {
    val hasAnyMultiplayerIssue: Boolean
        get() = natType.isMultiplayerRestricted || cgnatStatus.isImpacted || doubleNatStatus.isImpacted

    companion object {
        val INCONCLUSIVE = NatTopologySnapshot(NatType.INCONCLUSIVE, CgnatStatus.INCONCLUSIVE, DoubleNatStatus.INCONCLUSIVE)
    }
}

enum class GameServerArchitecture { DEDICATED_SERVER, PEER_TO_PEER, HYBRID }
