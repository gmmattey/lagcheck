package com.lagcheck.core.telemetry.radio

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import com.lagcheck.domain.model.RadioTelemetrySnapshot
import java.net.InetAddress

/**
 * Provedor de telemetria física de rádio e enlace para Android (Decisão 67).
 * Extrai dados empíricos de frequência, sinal em dBm e rotas sem suposições.
 */
class AndroidRadioTelemetryProvider(
    private val context: Context
) {
    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
    private val wifiManager =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

    fun captureCurrentSnapshot(): RadioTelemetrySnapshot {
        val activeNetwork = connectivityManager?.activeNetwork
        val capabilities = activeNetwork?.let { connectivityManager.getNetworkCapabilities(it) }

        val transportType = when {
            capabilities == null -> RadioTelemetrySnapshot.TransportType.OTHER
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> RadioTelemetrySnapshot.TransportType.WIFI
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> RadioTelemetrySnapshot.TransportType.CELLULAR
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> RadioTelemetrySnapshot.TransportType.ETHERNET
            else -> RadioTelemetrySnapshot.TransportType.OTHER
        }

        val gateway = resolveDefaultGateway()

        val wifiDetails = if (transportType == RadioTelemetrySnapshot.TransportType.WIFI) {
            extractWifiDetails()
        } else {
            null
        }

        return RadioTelemetrySnapshot(
            transportType = transportType,
            wifiDetails = wifiDetails,
            cellularDetails = null, // Celular avançado (RSRP/SINR) via TelephonyManager
            gatewayAddress = gateway,
            localAddress = resolveLocalIpv4()
        )
    }

    private fun extractWifiDetails(): RadioTelemetrySnapshot.WifiDetails? {
        val wifiInfo: WifiInfo = wifiManager?.connectionInfo ?: return null

        val frequency = wifiInfo.frequency
        val rssi = wifiInfo.rssi

        val txSpeed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            wifiInfo.txLinkSpeedMbps
        } else {
            wifiInfo.linkSpeed
        }

        val rxSpeed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            wifiInfo.rxLinkSpeedMbps
        } else {
            -1
        }

        val standard = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            when (wifiInfo.wifiStandard) {
                android.net.wifi.ScanResult.WIFI_STANDARD_11AX -> "Wi-Fi 6 (ax)"
                android.net.wifi.ScanResult.WIFI_STANDARD_11AC -> "Wi-Fi 5 (ac)"
                android.net.wifi.ScanResult.WIFI_STANDARD_11N -> "Wi-Fi 4 (n)"
                6 -> "Wi-Fi 6 (ax)"
                7, 8 -> "Wi-Fi 7 (be)"
                else -> "Wi-Fi"
            }
        } else {
            "Wi-Fi"
        }

        return RadioTelemetrySnapshot.WifiDetails(
            frequencyMhz = frequency,
            rssiDbm = rssi,
            txLinkSpeedMbps = txSpeed,
            rxLinkSpeedMbps = rxSpeed,
            standard = standard
        )
    }

    /**
     * Resolve o Gateway IP padrão a partir da tabela de rotas do SO (Decisão 50/55).
     * Não assume `.1`.
     */
    private fun resolveDefaultGateway(): String? {
        val activeNetwork = connectivityManager?.activeNetwork ?: return null
        val linkProperties = connectivityManager.getLinkProperties(activeNetwork) ?: return null

        for (route in linkProperties.routes) {
            if (route.isDefaultRoute && route.hasGateway()) {
                val gateway: InetAddress? = route.gateway
                // Só IPv4, como o probe do iOS: rota padrão IPv6 (::/0) tem gateway link-local com escopo e não serve ao probe.
                if (gateway is java.net.Inet4Address && !gateway.isAnyLocalAddress) {
                    return gateway.hostAddress
                }
            }
        }
        return null
    }

    /** IPv4 local da rede ativa, vindo do `LinkProperties`. Nulo se não houver. */
    private fun resolveLocalIpv4(): String? {
        val network = connectivityManager?.activeNetwork ?: return null
        val link = connectivityManager.getLinkProperties(network) ?: return null
        return link.linkAddresses
            .map { it.address }
            .firstOrNull { it is java.net.Inet4Address && !it.isLoopbackAddress && !it.isLinkLocalAddress }
            ?.hostAddress
    }
}
