package com.lagcheck.network

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.Platform
import com.lagcheck.network.health.PlatformHealthClient
import com.lagcheck.network.health.PlatformHealthParsers
import com.lagcheck.network.health.PlatformHealthStatus
import kotlinx.coroutines.runBlocking
import org.junit.Test

class PlatformHealthTest {
    private fun b(s: String) = s.trimIndent().toByteArray()

    @Test fun psnOperational() {
        val h = PlatformHealthParsers.parsePlayStation(b("""{"countries":[{"countryCode":"BR","status":[],"services":[
            {"serviceId":"Account_Management","serviceName":"Account Management","status":[]}]}]}"""), "BR")
        assertThat(h.status).isEqualTo(PlatformHealthStatus.Operational)
        assertThat(h.isIssueReported).isFalse()
    }

    @Test fun psnDegradedNamesTheAffectedService() {
        val h = PlatformHealthParsers.parsePlayStation(b("""{"countries":[{"countryCode":"BR","status":[],"services":[
            {"serviceId":"Gaming_And_Social","serviceName":"Jogos e redes sociais","status":[
              {"statusType":"degraded","message":{"message":"Lentidão ao buscar partidas"}}]}]}]}"""), "BR")
        assertThat(h.status).isInstanceOf(PlatformHealthStatus.Degraded::class.java)
        assertThat(h.affectedServices).containsExactly("Jogos e redes sociais")
    }

    @Test fun psnOutageUsesTheCountryMessage() {
        val h = PlatformHealthParsers.parsePlayStation(b("""{"countries":[{"countryCode":"BR","status":[
            {"statusType":"outage","message":{"message":"Queda geral no Brasil"}}],"services":[]}]}"""), "BR")
        assertThat(h.status).isEqualTo(PlatformHealthStatus.MajorOutage("Queda geral no Brasil"))
        assertThat(h.isMajorOutage).isTrue()
    }

    @Test fun xboxOperationalDegradedAndMajor() {
        assertThat(PlatformHealthParsers.parseXbox(b("""{"Status":{"Overall":{"State":"None"}},"CoreServices":[{"Name":"Conta","Status":{"Name":"None"}}]}""")).status)
            .isEqualTo(PlatformHealthStatus.Operational)
        val minor = PlatformHealthParsers.parseXbox(b("""{"Status":{"Overall":{"State":"Minor"}},"CoreServices":[
            {"Name":"Jogos multijogador","Status":{"Name":"Minor"},"Scenarios":[{"Status":{"Name":"Minor"},"Description":"Lentidão ao iniciar partidas."}]}]}"""))
        assertThat(minor.status).isEqualTo(PlatformHealthStatus.Degraded("Lentidão ao iniciar partidas."))
        assertThat(minor.affectedServices).containsExactly("Jogos multijogador")
        val major = PlatformHealthParsers.parseXbox(b("""{"Status":{"Overall":{"State":"Major"}},"CoreServices":[]}"""))
        assertThat(major.status).isInstanceOf(PlatformHealthStatus.MajorOutage::class.java)
    }

    @Test fun nintendoOutageOnlyWhenListed() {
        assertThat(PlatformHealthParsers.parseNintendo(b("""{"operational_statuses":[]}""")).status).isEqualTo(PlatformHealthStatus.Operational)
        assertThat(PlatformHealthParsers.parseNintendo(b("""{"operational_statuses":[{"message":"Manutenção"}]}""")).status)
            .isEqualTo(PlatformHealthStatus.MajorOutage("Manutenção"))
    }

    @Test fun malformedOrWrongShapeIsUnknownNeverAnAlert() {
        val junk = "isto nao e um json".toByteArray()
        assertThat(PlatformHealthParsers.parsePlayStation(junk, "BR").status).isEqualTo(PlatformHealthStatus.Unknown)
        assertThat(PlatformHealthParsers.parseXbox(junk).status).isEqualTo(PlatformHealthStatus.Unknown)
        assertThat(PlatformHealthParsers.parseNintendo(junk).status).isEqualTo(PlatformHealthStatus.Unknown)
        assertThat(PlatformHealthParsers.parsePlayStation(b("""{"countries":[]}"""), "BR").status).isEqualTo(PlatformHealthStatus.Unknown)
        assertThat(PlatformHealthParsers.parsePlayStation(b("""{"outra":"coisa"}"""), "BR").isIssueReported).isFalse()
    }

    @Test fun clientSkipsMobileAndFailsOpen() = runBlocking {
        var calls = 0
        val client = PlatformHealthClient(fetch = { calls++; null })
        assertThat(client.check(Platform.MOBILE)).isNull()
        assertThat(calls).isEqualTo(0)

        val pc = client.check(Platform.PC)!!
        assertThat(pc.status).isEqualTo(PlatformHealthStatus.Unknown)
        assertThat(pc.isIssueReported).isFalse()

        val psn = client.check(Platform.PLAYSTATION, "BR")!!
        assertThat(psn.status).isEqualTo(PlatformHealthStatus.Unknown)
        assertThat(psn.isIssueReported).isFalse()
    }

    @Test fun clientCachesWithinTtlAndRefetchesAfter() = runBlocking {
        var now = 1_700_000_000_000L
        var calls = 0
        val payload = """{"platforms":[{"id":"nintendo","name":"Nintendo","status":"operational","checkedAt":"2023-11-14T22:13:20Z"}]}""".toByteArray()
        val client = PlatformHealthClient(
            fetch = { calls++; payload },
            cacheTtlMillis = 1000, clock = { now }
        )
        client.check(Platform.NINTENDO); client.check(Platform.NINTENDO)
        assertThat(calls).isEqualTo(1)
        now += 1500
        client.check(Platform.NINTENDO)
        assertThat(calls).isEqualTo(2)
    }

    @Test fun statusApiParsesPcSteamAndEpicAndRejectsStaleTimestamps() {
        val now = 1_700_000_000_000L
        val json = b("""
            {
              "platforms": [
                {"id":"playstation","name":"PlayStation Network","status":"operational","checkedAt":"2023-11-14T22:13:00Z"},
                {"id":"steam","name":"Steam","status":"outage","checkedAt":"2023-11-14T22:13:00Z"},
                {"id":"epicgames","name":"Epic Games","status":"operational","checkedAt":"2023-11-14T22:13:00Z"}
              ]
            }
        """)
        val psn = PlatformHealthParsers.parseStatusApi(json, Platform.PLAYSTATION, now)!!
        assertThat(psn.status).isEqualTo(PlatformHealthStatus.Operational)

        val pc = PlatformHealthParsers.parseStatusApi(json, Platform.PC, now)!!
        assertThat(pc.isMajorOutage).isTrue()
        assertThat(pc.serviceName).isEqualTo("Steam")
        assertThat(pc.affectedServices).containsExactly("Steam")

        val staleJson = b("""
            {
              "platforms": [
                {"id":"playstation","name":"PlayStation Network","status":"outage","checkedAt":"2023-11-14T22:00:00Z"},
                {"id":"steam","name":"Steam","status":"outage","checkedAt":"2023-11-14T22:00:00Z"}
              ]
            }
        """)
        assertThat(PlatformHealthParsers.parseStatusApi(staleJson, Platform.PLAYSTATION, now)).isNull()
        val stalePc = PlatformHealthParsers.parseStatusApi(staleJson, Platform.PC, now)!!
        assertThat(stalePc.status).isEqualTo(PlatformHealthStatus.Unknown)
        assertThat(stalePc.isIssueReported).isFalse()
    }

    @Test fun clientFallsBackToDirectCdnWhenStatusApiFails() = runBlocking {
        val requested = mutableListOf<String>()
        val client = PlatformHealthClient(
            fetch = { url ->
                requested += url
                if (url == PlatformHealthClient.STATUS_API_URL) null
                else """{"operational_statuses":[{"message":"Manutenção"}]}""".toByteArray()
            }
        )
        val nintendo = client.check(Platform.NINTENDO)!!
        assertThat(nintendo.isMajorOutage).isTrue()
        assertThat(requested).containsExactly(PlatformHealthClient.STATUS_API_URL, PlatformHealthClient.NINTENDO_URL).inOrder()
    }

    @Test fun regionAndLocaleRouting() {
        assertThat(PlatformHealthClient.psnUrl("br")).endsWith("/SCEA.json")
        assertThat(PlatformHealthClient.psnUrl("DE")).endsWith("/SCEE.json")
        assertThat(PlatformHealthClient.xboxUrl("BR")).endsWith("/BR/pt-BR")
        assertThat(PlatformHealthClient.xboxUrl("US")).endsWith("/US/en-US")
    }
}
