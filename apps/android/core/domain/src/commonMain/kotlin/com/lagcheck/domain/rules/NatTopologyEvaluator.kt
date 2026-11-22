package com.lagcheck.domain.rules

import com.lagcheck.domain.model.NatTopologySnapshot

object NatTopologyEvaluator {
    @Suppress("UNUSED_PARAMETER")
    fun evaluate(
        localIp: String?,
        publicIp: String?,
        externalPort: Int?,
        isPortMappingConsistent: Boolean = true,
        detectedDoubleHop: Boolean = false
    ): NatTopologySnapshot {
        // Uma ou duas respostas STUN não comprovam tipo de NAT, CGNAT ou NAT duplo:
        // portas podem mudar porque o transporte abriu sockets diferentes e o IP observado pelo
        // servidor não prova a topologia antes dele. Sem uma sonda capaz de isolar essas hipóteses,
        // o contrato preserva a incerteza em vez de declarar "não detectado" ou uma NAT favorável.
        return NatTopologySnapshot.INCONCLUSIVE
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
