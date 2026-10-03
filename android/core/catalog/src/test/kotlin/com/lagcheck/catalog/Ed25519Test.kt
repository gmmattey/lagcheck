package com.lagcheck.catalog

import com.google.common.truth.Truth.assertThat
import java.security.KeyPairGenerator
import java.security.Signature
import org.junit.Test

class Ed25519Test {
    private fun hex(s: String) = s.chunked(2).map { it.toInt(16).toByte() }.toByteArray()

    // Vetores do RFC 8032 §7.1
    @Test fun rfc8032Test1_emptyMessage() {
        val pk = hex("d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a")
        val sig = hex(
            "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e06522490155" +
                "5fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b"
        )
        assertThat(Ed25519.verify(pk, ByteArray(0), sig)).isTrue()
    }

    @Test fun rfc8032Test2_oneByte() {
        val pk = hex("3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c")
        val sig = hex(
            "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da" +
                "085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00"
        )
        assertThat(Ed25519.verify(pk, hex("72"), sig)).isTrue()
    }

    @Test fun tamperedMessageIsRejected() {
        val pk = hex("3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c")
        val sig = hex(
            "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da" +
                "085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00"
        )
        assertThat(Ed25519.verify(pk, hex("73"), sig)).isFalse()
    }

    @Test fun tamperedSignatureIsRejected() {
        val pk = hex("d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a")
        val sig = hex(
            "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e06522490155" +
                "5fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b"
        )
        sig[10] = (sig[10].toInt() xor 1).toByte()
        assertThat(Ed25519.verify(pk, ByteArray(0), sig)).isFalse()
    }

    @Test fun wrongSizesAreRejected() {
        assertThat(Ed25519.verify(ByteArray(31), ByteArray(0), ByteArray(64))).isFalse()
        assertThat(Ed25519.verify(ByteArray(32), ByteArray(0), ByteArray(63))).isFalse()
    }

    /** Validação cruzada: assinaturas geradas pelo provider Ed25519 do JDK precisam verificar na implementação própria. */
    @Test fun agreesWithJdkProvider() {
        val kpg = KeyPairGenerator.getInstance("Ed25519")
        repeat(25) { i ->
            val kp = kpg.generateKeyPair()
            val message = ByteArray(i * 7) { (it * 31 + i).toByte() }
            val signer = Signature.getInstance("Ed25519").apply { initSign(kp.private); update(message) }
            val sig = signer.sign()
            // X.509 SubjectPublicKeyInfo termina com os 32 bytes da chave pública crua.
            val raw = kp.public.encoded.takeLast(32).toByteArray()
            assertThat(Ed25519.verify(raw, message, sig)).isTrue()
            val bad = message + 1
            assertThat(Ed25519.verify(raw, bad, sig)).isFalse()
        }
    }
}
