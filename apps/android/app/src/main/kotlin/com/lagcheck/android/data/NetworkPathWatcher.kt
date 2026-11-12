package com.lagcheck.android.data

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities

/**
 * Detecta troca de caminho de rede durante a medição (Wi-Fi ↔ celular, perda de rede). Mudança descarta o
 * resultado parcial: não se compara um repouso medido numa rede com uma carga medida em outra.
 */
class NetworkPathWatcher(context: Context) {
    private val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
    private var callback: ConnectivityManager.NetworkCallback? = null

    @Synchronized
    fun start(onChanged: () -> Unit) {
        stop()
        val manager = cm ?: return
        var baseline: Network? = null
        var baselineTransports: Set<Int>? = null
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                // O callback dispara de imediato para a rede atual: isso é a linha de base, não uma mudança.
                if (baseline == null) { baseline = network; return }
                if (network != baseline) onChanged()
            }

            override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
                val transports = TRANSPORTS.filter { caps.hasTransport(it) }.toSet()
                if (network == baseline) {
                    val before = baselineTransports
                    if (before == null) baselineTransports = transports else if (before != transports) onChanged()
                }
            }

            override fun onLost(network: Network) {
                if (network == baseline) onChanged()
            }
        }
        callback = cb
        runCatching { manager.registerDefaultNetworkCallback(cb) }
    }

    @Synchronized
    fun stop() {
        val cb = callback ?: return
        callback = null
        runCatching { cm?.unregisterNetworkCallback(cb) }
    }

    private companion object {
        val TRANSPORTS = listOf(
            NetworkCapabilities.TRANSPORT_WIFI,
            NetworkCapabilities.TRANSPORT_CELLULAR,
            NetworkCapabilities.TRANSPORT_ETHERNET,
            NetworkCapabilities.TRANSPORT_VPN
        )
    }
}
