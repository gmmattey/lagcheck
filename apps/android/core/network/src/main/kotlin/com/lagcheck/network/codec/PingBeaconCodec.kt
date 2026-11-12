package com.lagcheck.network.codec

import java.nio.ByteBuffer
import java.util.UUID

class PingBeaconPayload(val sessionId: UUID, val sequence: Long, val nonce: Long)

/** Beacon GameLift do piloto: 33 bytes `NLPG` + versão + UUID + sequência (u32 BE) + nonce (u64 BE). Eco íntegro obrigatório. */
object PingBeaconCodec {
    val MAGIC = byteArrayOf(0x4E, 0x4C, 0x50, 0x47)
    const val VERSION: Byte = 0x01
    const val BYTE_COUNT = 33

    fun encode(p: PingBeaconPayload): ByteArray {
        val b = ByteBuffer.allocate(BYTE_COUNT)
        b.put(MAGIC).put(VERSION)
        b.putLong(p.sessionId.mostSignificantBits).putLong(p.sessionId.leastSignificantBits)
        b.putInt(p.sequence.toInt())
        b.putLong(p.nonce)
        return b.array()
    }

    fun decode(data: ByteArray): PingBeaconPayload? {
        if (data.size != BYTE_COUNT) return null
        if (!data.copyOfRange(0, 4).contentEquals(MAGIC) || data[4] != VERSION) return null
        val b = ByteBuffer.wrap(data, 5, BYTE_COUNT - 5)
        val uuid = UUID(b.long, b.long)
        return PingBeaconPayload(uuid, b.int.toLong() and 0xFFFFFFFFL, b.long)
    }

    fun isExactEcho(request: ByteArray, response: ByteArray): Boolean =
        request.size == BYTE_COUNT && request.contentEquals(response)
}
