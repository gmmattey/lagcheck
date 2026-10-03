package com.lagcheck.domain.model

/**
 * Snapshot de telemetria física de rádio e enlace (Decisão 67).
 * Dados de hardware expostos pelo Android que o iOS mantém inacessíveis.
 */
data class RadioTelemetrySnapshot(
    val transportType: TransportType,
    val wifiDetails: WifiDetails? = null,
    val cellularDetails: CellularDetails? = null,
    val gatewayAddress: String? = null
) {
    enum class TransportType {
        WIFI,
        CELLULAR,
        ETHERNET,
        OTHER
    }

    enum class WifiBand {
        BAND_2_4_GHZ,
        BAND_5_GHZ,
        BAND_6_GHZ,
        UNKNOWN
    }

    data class WifiDetails(
        val frequencyMhz: Int,
        val rssiDbm: Int,
        val txLinkSpeedMbps: Int,
        val rxLinkSpeedMbps: Int,
        val standard: String,
        val lostPackets: Long? = null,
        val successfulPackets: Long? = null
    ) {
        val band: WifiBand
            get() = when {
                frequencyMhz in 2400..2500 -> WifiBand.BAND_2_4_GHZ
                frequencyMhz in 4900..5900 -> WifiBand.BAND_5_GHZ
                frequencyMhz in 5925..7125 -> WifiBand.BAND_6_GHZ
                else -> WifiBand.UNKNOWN
            }

        val isSignalCritical: Boolean
            get() = rssiDbm < -78

        val isOptimal5GhzOrHigher: Boolean
            get() = (band == WifiBand.BAND_5_GHZ || band == WifiBand.BAND_6_GHZ) && rssiDbm >= -70
    }

    data class CellularDetails(
        val networkType: String,
        val signalDbm: Int? = null,
        val is5GStandalone: Boolean = false
    )
}
