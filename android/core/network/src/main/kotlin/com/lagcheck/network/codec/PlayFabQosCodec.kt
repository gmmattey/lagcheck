package com.lagcheck.network.codec

import java.nio.ByteBuffer
import java.util.UUID

class PlayFabQosPayload(val sessionId: UUID, val sequence: Long, val nonce: Long, val flags: Byte = 0)

/** Probe Azure PlayFab QoS (33 bytes). Requisição com cabeçalho 0xFFFF; a resposta devolve 0x0000 + os 31 bytes restantes idênticos. */
object PlayFabQosCodec {
    const val MAGIC: Byte = 0x50
    const val VERSION: Byte = 0x01
    const val BYTE_COUNT = 33

    fun encode(p: PlayFabQosPayload): ByteArray {
        val b = ByteBuffer.allocate(BYTE_COUNT)
        b.put(0xFF.toByte()).put(0xFF.toByte()).put(MAGIC).put(VERSION)
        b.putLong(p.sessionId.mostSignificantBits).putLong(p.sessionId.leastSignificantBits)
        b.putInt(p.sequence.toInt())
        b.putLong(p.nonce)
        b.put(p.flags)
        return b.array()
    }

    fun decode(data: ByteArray): PlayFabQosPayload? {
        if (data.size != BYTE_COUNT) return null
        if (data[0] != 0xFF.toByte() || data[1] != 0xFF.toByte() || data[2] != MAGIC || data[3] != VERSION) return null
        val b = ByteBuffer.wrap(data, 4, BYTE_COUNT - 4)
        val uuid = UUID(b.long, b.long)
        return PlayFabQosPayload(uuid, b.int.toLong() and 0xFFFFFFFFL, b.long, b.get())
    }

    fun isValidEcho(request: ByteArray, response: ByteArray): Boolean {
        if (request.size != BYTE_COUNT || response.size != BYTE_COUNT) return false
        if (response[0] != 0.toByte() || response[1] != 0.toByte()) return false
        for (i in 2 until BYTE_COUNT) if (request[i] != response[i]) return false
        return true
    }
}
