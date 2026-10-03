package com.lagcheck.catalog

import java.io.File
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.Signature
import java.time.Instant
import java.util.Base64

internal object CatalogTestSupport {
    /** Instante dentro da janela de validade do catálogo v3 publicado (2026-09-19 → 2026-10-19). */
    val NOW: Instant = Instant.parse("2026-10-03T12:00:00Z")

    fun realEnvelopeBytes(): ByteArray {
        var dir: File? = File(System.getProperty("user.dir")).absoluteFile
        while (dir != null) {
            val f = File(dir, "worker/catalog/catalog-v3.envelope.json")
            if (f.exists()) return f.readBytes()
            dir = dir.parentFile
        }
        error("catalog-v3.envelope.json não encontrado")
    }

    fun newKeyPair(): KeyPair = KeyPairGenerator.getInstance("Ed25519").generateKeyPair()

    fun rawPublicKeyBase64(kp: KeyPair): String =
        Base64.getEncoder().encodeToString(kp.public.encoded.takeLast(32).toByteArray())

    /** Assina um payload com chave de teste e monta o envelope (a chave real nunca está no repositório). */
    fun envelope(
        payloadJson: String,
        kp: KeyPair,
        schemaVersion: Int = 3,
        catalogVersion: String = "test-catalog",
        issuedAt: String = "2026-09-19T15:30:00Z",
        expiresAt: String = "2026-10-19T15:30:00Z",
        algorithm: String = "Ed25519"
    ): ByteArray {
        val payload = payloadJson.toByteArray(Charsets.UTF_8)
        val sig = Signature.getInstance("Ed25519").apply { initSign(kp.private); update(payload) }.sign()
        val b64 = Base64.getEncoder()
        return """{"schemaVersion":$schemaVersion,"catalogVersion":"$catalogVersion","issuedAt":"$issuedAt","expiresAt":"$expiresAt","algorithm":"$algorithm","payloadBase64":"${b64.encodeToString(payload)}","signatureBase64":"${b64.encodeToString(sig)}"}""".toByteArray()
    }

    /** Payload mínimo válido para o schema 3, parametrizável para testar cada regra de negócio. */
    fun payload(
        games: String = defaultGame(),
        regions: String = defaultRegion(),
        profiles: String = defaultProfiles(),
        assetBase: String = "https://assets.example.com/",
        catalogVersion: String = "test-catalog"
    ) = """{"schemaVersion":3,"catalogVersion":"$catalogVersion","assetBaseURL":"$assetBase","profiles":[$profiles],"regions":[$regions],"games":[$games]}"""

    fun defaultProfiles() =
        """{"id":"BATTLE_ROYALE_COMPETITIVE","ruleVersion":"pilot-2026.09.08.1"},{"id":"MOBILE_REALTIME","ruleVersion":"mobile-realtime-2026.09.08.1"},{"id":"CASUAL_REALTIME","ruleVersion":"casual-realtime-2026.09.08.1"}"""

    fun defaultRegion(id: String = "sa-east-1", host: String = "gamelift-ping.$id.api.aws", port: Int = 7770) =
        """{"id":"$id","label":{"pt-BR":"São Paulo","en":"São Paulo"},"probe":{"host":"$host","port":$port,"protocolKind":"gameLiftPing"}}"""

    fun route(
        id: String = "g-aws", kind: String = "awsFallback", status: String = "active", region: String = "sa-east-1",
        strategy: String = "genericRegion", confidence: String = "medium", precision: String = "regionalReference",
        extra: String = ""
    ) = """{"id":"$id","kind":"$kind","status":"$status","regionID":"$region","strategy":"$strategy","confidence":"$confidence","precisionKey":"$precision"$extra}"""

    fun context(
        platforms: String = """"iphone"""", profile: String = "BATTLE_ROYALE_COMPETITIVE", availability: String = "available",
        routes: String = route(), market: String = "BR", measurement: String = "null"
    ) = """{"market":"$market","platforms":[$platforms],"profileID":"$profile","availability":"$availability","measurement":$measurement,"routes":[$routes]}"""

    fun defaultGame(
        id: String = "g", name: String = "G", contexts: String = context(),
        artwork: String = """{"path":"artwork/games/g.jpg","sha256":"${"a".repeat(64)}"}""",
        rating: String = """{"status":"pendingVerification","sourceName":"pendente"}"""
    ) = """{"id":"$id","name":"$name","artwork":$artwork,"rating":$rating,"contexts":[$contexts]}"""
}
