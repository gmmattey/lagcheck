package com.lagcheck.network.stun

import java.nio.ByteBuffer
import java.security.SecureRandom

/**
 * Codificador e decodificador binário de datagramas do protocolo STUN (RFC 5389 / RFC 8489).
 * Utilizado para probes determinísticos e teste de latência/jitter contra infraestruturas de jogos.
 */
object StunPacketCodec {
    const val MAGIC_COOKIE: Int = 0x2112A442
    const val BINDING_REQUEST_TYPE: Short = 0x0001
    const val BINDING_RESPONSE_TYPE: Short = 0x0101
    const val ATTR_MAPPED_ADDRESS: Short = 0x0001
    const val ATTR_XOR_MAPPED_ADDRESS: Short = 0x0020

    private val secureRandom = SecureRandom()

    data class StunRequest(
        val packetBytes: ByteArray,
        val transactionId: ByteArray
    ) {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false
            other as StunRequest
            return packetBytes.contentEquals(other.packetBytes) && transactionId.contentEquals(other.transactionId)
        }

        override fun hashCode(): Int {
            var result = packetBytes.contentHashCode()
            result = 31 * result + transactionId.contentHashCode()
            return result
        }
    }

    data class StunResponse(
        val publicIp: String,
        val port: Int
    )

    /**
     * Constrói um pacote de STUN Binding Request conforme RFC 5389 (20 bytes).
     */
    fun buildBindingRequest(customTransactionId: ByteArray? = null): StunRequest {
        val txId = customTransactionId ?: ByteArray(12).also { secureRandom.nextBytes(it) }
        val buffer = ByteBuffer.allocate(20)

        // 1. Message Type (Binding Request 0x0001)
        buffer.putShort(BINDING_REQUEST_TYPE)
        // 2. Message Length (0x0000, sem atributos de corpo)
        buffer.putShort(0.toShort())
        // 3. Magic Cookie (0x2112A442)
        buffer.putInt(MAGIC_COOKIE)
        // 4. Transaction ID (12 bytes)
        buffer.put(txId)

        return StunRequest(packetBytes = buffer.array(), transactionId = txId)
    }

    /**
     * Decodifica a resposta STUN (port fiel do Swift). Sem endereço mapeado IPv4 devolve `null`: um Binding Response
     * sem endereço não permite concluir nada, e inventar um IP aqui viraria um NAT falso.
     */
    fun parseBindingResponse(data: ByteArray, expectedTxId: ByteArray? = null): StunResponse? {
        if (data.size < 20) return null
        val buffer = ByteBuffer.wrap(data)
        if (buffer.short != BINDING_RESPONSE_TYPE) return null
        val msgLength = buffer.short.toInt() and 0xFFFF
        if (buffer.int != MAGIC_COOKIE) return null
        val txId = ByteArray(12)
        buffer.get(txId)
        if (expectedTxId != null && !txId.contentEquals(expectedTxId)) return null
        if (data.size < 20 + msgLength) return null

        var offset = 20
        while (offset + 4 <= 20 + msgLength) {
            val attrType = ((data[offset].toInt() and 0xFF) shl 8) or (data[offset + 1].toInt() and 0xFF)
            val attrLen = ((data[offset + 2].toInt() and 0xFF) shl 8) or (data[offset + 3].toInt() and 0xFF)
            offset += 4
            if (offset + attrLen > data.size) break

            if ((attrType == ATTR_XOR_MAPPED_ADDRESS.toInt() || attrType == ATTR_MAPPED_ADDRESS.toInt()) && attrLen >= 8 && data[offset + 1].toInt() == 0x01) {
                val rawPort = ((data[offset + 2].toInt() and 0xFF) shl 8) or (data[offset + 3].toInt() and 0xFF)
                val rawIp = ByteBuffer.wrap(data, offset + 4, 4).int
                val xor = attrType == ATTR_XOR_MAPPED_ADDRESS.toInt()
                val port = if (xor) rawPort xor (MAGIC_COOKIE ushr 16) else rawPort
                val ip = if (xor) rawIp xor MAGIC_COOKIE else rawIp
                return StunResponse(
                    publicIp = "${(ip ushr 24) and 0xFF}.${(ip ushr 16) and 0xFF}.${(ip ushr 8) and 0xFF}.${ip and 0xFF}",
                    port = port
                )
            }
            offset += attrLen + (4 - attrLen % 4) % 4 // alinhamento de 4 bytes (RFC 5389)
        }
        return null
    }
}
