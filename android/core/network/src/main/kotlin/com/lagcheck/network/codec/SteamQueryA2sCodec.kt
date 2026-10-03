package com.lagcheck.network.codec

/** Valve A2S_INFO (Steam Query): query inicial (25 B), challenge (S2C 'A'), query autenticada (29 B) e resposta 'I'. */
object SteamQueryA2sCodec {
    private val HEADER = byteArrayOf(-1, -1, -1, -1)
    private const val REQUEST_TYPE_INFO: Byte = 0x54 // 'T'
    private const val RESPONSE_CHALLENGE: Byte = 0x41 // 'A'
    private const val RESPONSE_INFO: Byte = 0x49 // 'I'
    private val QUERY_STRING = "Source Engine Query".toByteArray(Charsets.US_ASCII) + 0

    fun encodeInitialRequest(): ByteArray = HEADER + REQUEST_TYPE_INFO + QUERY_STRING

    fun encodeAuthenticatedRequest(challengeToken: Long): ByteArray {
        val t = challengeToken.toInt()
        return encodeInitialRequest() + byteArrayOf(t.toByte(), (t shr 8).toByte(), (t shr 16).toByte(), (t shr 24).toByte())
    }

    private fun hasHeader(d: ByteArray) = d.size >= 5 && d[0] == (-1).toByte() && d[1] == (-1).toByte() && d[2] == (-1).toByte() && d[3] == (-1).toByte()

    fun isChallengeResponse(d: ByteArray) = d.size >= 9 && hasHeader(d) && d[4] == RESPONSE_CHALLENGE

    /** Token de 4 bytes little-endian como valor sem sinal. */
    fun decodeChallenge(d: ByteArray): Long? {
        if (!isChallengeResponse(d)) return null
        return (d[5].toLong() and 0xFF) or ((d[6].toLong() and 0xFF) shl 8) or
            ((d[7].toLong() and 0xFF) shl 16) or ((d[8].toLong() and 0xFF) shl 24)
    }

    fun isValidInfoResponse(d: ByteArray) = hasHeader(d) && d[4] == RESPONSE_INFO

    class Info(val name: String, val gameDirectory: String, val appId: Int)

    /** Lê só os campos que confirmam a identidade do servidor esperado. Nada daqui vira sinal de qualidade de rede. */
    fun decodeInfo(d: ByteArray): Info? {
        if (!isValidInfoResponse(d) || d.size < 6) return null
        var i = 6
        fun cstr(): String? {
            val start = i
            while (i < d.size && d[i] != 0.toByte()) i++
            if (i >= d.size) return null
            val s = String(d, start, i - start, Charsets.UTF_8)
            i++
            return s
        }
        val name = cstr() ?: return null
        cstr() ?: return null // mapa
        val dir = cstr() ?: return null
        cstr() ?: return null // nome do jogo
        if (i + 2 > d.size) return null
        return Info(name, dir, (d[i].toInt() and 0xFF) or ((d[i + 1].toInt() and 0xFF) shl 8))
    }
}
