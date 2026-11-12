package com.lagcheck.network.stun

import com.google.common.truth.Truth.assertThat
import org.junit.Test
import java.nio.ByteBuffer

class StunPacketCodecTest {

    @Test
    fun buildBindingRequest_createsValid20BytePacket() {
        val request = StunPacketCodec.buildBindingRequest()

        assertThat(request.packetBytes).hasLength(20)
        assertThat(request.transactionId).hasLength(12)

        val buffer = ByteBuffer.wrap(request.packetBytes)
        assertThat(buffer.short).isEqualTo(StunPacketCodec.BINDING_REQUEST_TYPE)
        assertThat(buffer.short).isEqualTo(0.toShort())
        assertThat(buffer.int).isEqualTo(StunPacketCodec.MAGIC_COOKIE)

        val txId = ByteArray(12)
        buffer.get(txId)
        assertThat(txId).isEqualTo(request.transactionId)
    }

    @Test
    fun parseBindingResponse_withoutMappedAddress_returnsNull() {
        val request = StunPacketCodec.buildBindingRequest()
        val txId = request.transactionId

        // Simula resposta de Binding com 20 bytes de cabeçalho
        val buffer = ByteBuffer.allocate(20)
        buffer.putShort(StunPacketCodec.BINDING_RESPONSE_TYPE)
        buffer.putShort(0.toShort())
        buffer.putInt(StunPacketCodec.MAGIC_COOKIE)
        buffer.put(txId)

        val response = StunPacketCodec.parseBindingResponse(buffer.array(), expectedTxId = txId)

        // Cabeçalho válido, mas sem endereço mapeado: nada a concluir (nunca fabrica um IP).
        assertThat(response).isNull()
    }

    @Test
    fun parseBindingResponse_mismatchedTxId_returnsNull() {
        val request = StunPacketCodec.buildBindingRequest()
        val wrongTxId = ByteArray(12) { 0xFF.toByte() }

        val buffer = ByteBuffer.allocate(20)
        buffer.putShort(StunPacketCodec.BINDING_RESPONSE_TYPE)
        buffer.putShort(0.toShort())
        buffer.putInt(StunPacketCodec.MAGIC_COOKIE)
        buffer.put(wrongTxId)

        val response = StunPacketCodec.parseBindingResponse(buffer.array(), expectedTxId = request.transactionId)

        assertThat(response).isNull()
    }
}
