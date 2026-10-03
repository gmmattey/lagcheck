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
     * Decodifica a resposta STUN e extrai o endereço IP e a porta mapeada.
     */
    fun parseBindingResponse(data: ByteArray, expectedTxId: ByteArray? = null): StunResponse? {
        if (data.size < 20) return null

        val buffer = ByteBuffer.wrap(data)
        val msgType = buffer.short
        if (msgType != BINDING_RESPONSE_TYPE) return null

        val msgLength = buffer.short.toInt() and 0xFFFF
        val magicCookie = buffer.int
        if (magicCookie != MAGIC_COOKIE) return null

        val txId = ByteArray(12)
        buffer.get(txId)

        if (expectedTxId != null && !txId.contentEquals(expectedTxId)) {
            return null
        }

        var publicIp: String? = null
        var port: Int? = null

        // Leitura dos atributos TLV (Type-Length-Value)
        while (buffer.remaining() >= 4) {
            val attrType = buffer.short
            val attrLength = buffer.short.toInt() and 0xFFFF

            if (buffer.remaining() < attrLength) break

            if (attrType == ATTR_XOR_MAPPED_ADDRESS && attrLength >= 8) {
                buffer.get() // Reserved
                val family = buffer.get().toInt()
                val rawPort = buffer.short.toInt() and 0xFFFF
                val xoredPort = rawPort xor (MAGIC_COOKIE ushr 16)

                if (family == 0x01 && attrLength >= 8) { // IPv4
                    val xoredIp = buffer.int
                    val realIp = xoredIp xor MAGIC_COOKIE
                    val ipStr = "${(realIp ushr 24) and 0xFF}.${(realIp ushr 16) and 0xFF}.${(realIp ushr 8) and 0xFF}.${realIp and 0xFF}"
                    publicIp = ipStr
                    port = xoredPort
                } else {
                    // Pula bytes não-IPv4
                    buffer.position(buffer.position() + (attrLength - 4))
                }
            } else {
                buffer.position(buffer.position() + attrLength)
            }

            // Alinhamento de padding para 4 bytes conforme RFC 5389
            val padding = (4 - (attrLength % 4)) % 4
            if (buffer.remaining() >= padding) {
                buffer.position(buffer.position() + padding)
            }
        }

        return if (publicIp != null && port != null) {
            StunResponse(publicIp = publicIp, port = port)
        } else {
            // Se for STUN válido mas sem XOR attribute decodificado, retorna sucesso com endpoint genérico
            StunResponse(publicIp = "0.0.0.0", port = 0)
        }
    }
}
