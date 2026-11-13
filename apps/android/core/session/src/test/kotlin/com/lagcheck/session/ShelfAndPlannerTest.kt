package com.lagcheck.session

import com.google.common.truth.Truth.assertThat
import com.lagcheck.catalog.Platform
import com.lagcheck.catalog.ProbeProtocolKind
import com.lagcheck.catalog.RemoteCatalogVerifier
import com.lagcheck.domain.model.OfficialGameCatalog
import com.lagcheck.domain.model.QualityProfileId
import java.io.File
import java.time.Instant
import org.junit.Test

/** Guarda de aderência: a prateleira da UI não pode se afastar do catálogo assinado. */
class ShelfAndPlannerTest {
    private val now = Instant.parse("2026-10-20T00:00:00Z")
    private val root: File = generateSequence(File(System.getProperty("user.dir")).absoluteFile) { it.parentFile }
        .first { File(it, "worker/catalog/catalog-v3.candidate.json").exists() }
    private val payload = RemoteCatalogVerifier.decodeBundled(File(root, "worker/catalog/catalog-v3.candidate.json").readBytes())

    @Test fun shelfHasExactlyTheCatalogGames() {
        assertThat(OfficialGameCatalog.games.map { it.id }).containsExactlyElementsIn(payload.games.map { it.id })
        assertThat(OfficialGameCatalog.games.map { it.id }.toSet()).hasSize(OfficialGameCatalog.games.size)
    }

    @Test fun shelfNamesAndPlatformsMatchTheSignedCatalog() {
        for (game in payload.games) {
            val shelf = OfficialGameCatalog.games.first { it.id == game.id }
            assertThat(shelf.name).isEqualTo(game.name)
            val expected = game.contexts.flatMap { it.platformKeys }.mapNotNull(PlatformLabels::labelForCatalogKey).toSet()
            assertThat(shelf.platforms.toSet()).isEqualTo(expected)
        }
    }

    @Test fun everyShelfGameAndPlatformResolvesToAnActiveGameLiftBeacon() {
        for (shelf in OfficialGameCatalog.games) for (label in shelf.platforms) {
            val plan = MeasurementPlanner.plan(payload, shelf.id, label, now = now)
            assertThat(plan).isInstanceOf(PlanResult.Ready::class.java)
            val ctx = (plan as PlanResult.Ready).context
            assertThat(ctx.destination.protocolKind).isEqualTo(ProbeProtocolKind.GAMELIFT_PING)
            assertThat(ctx.destination.host).isEqualTo("gamelift-ping.sa-east-1.api.aws")
        }
    }

    @Test fun artworkInTheAppIsExactlyTheApprovedEditorialArt() {
        val drawables = File(root, "android/app/src/main/res/drawable")
        for (shelf in OfficialGameCatalog.games) {
            if (shelf.drawableResName.isEmpty()) {
                assertThat(shelf.id).isAnyOf("rainbow-six-mobile", "rocket-league-sideswipe")
                continue
            }
            val file = listOf("jpg", "png")
                .map { extension -> File(drawables, "${shelf.drawableResName}.$extension") }
                .firstOrNull(File::exists)
            assertThat(file).isNotNull()
            val artworkFile = requireNotNull(file)
            val sha = java.security.MessageDigest.getInstance("SHA-256").digest(artworkFile.readBytes()).joinToString("") { "%02x".format(it) }
            val declared = payload.games.first { it.id == shelf.id }.artwork!!.sha256
            assertThat(sha).isEqualTo(declared) // mesma arte autoral aprovada do catálogo (Decisões 18 e 44)
        }
    }

    @Test fun bundledBaseCatalogIsTheSameFileAsTheWorkerCandidateAndTheIosBase() {
        val asset = File(root, "android/app/src/main/assets/catalog-base.json").readBytes()
        assertThat(asset).isEqualTo(File(root, "worker/catalog/catalog-v3.candidate.json").readBytes())
        assertThat(asset).isEqualTo(File(root, "ios/Sources/NolaggyInfrastructure/Resources/DebugCatalogBase.json").readBytes())
    }

    @Test fun legacyPrototypeIdsStillFindTheirGame() {
        assertThat(OfficialGameCatalog.findById("codm").id).isEqualTo("call-of-duty-mobile")
        assertThat(OfficialGameCatalog.findById("pubg").id).isEqualTo("pubg-mobile")
        assertThat(OfficialGameCatalog.findById("ea-fc").id).isEqualTo("eafc")
    }

    @Test fun uiPlatformLabelsMapToCatalogPlatforms() {
        assertThat(PlatformLabels.toPlatform("PlayStation")).isEqualTo(Platform.PLAYSTATION)
        assertThat(PlatformLabels.toPlatform("Xbox")).isEqualTo(Platform.XBOX)
        assertThat(PlatformLabels.toPlatform("PC")).isEqualTo(Platform.PC)
        assertThat(PlatformLabels.toPlatform("Nintendo")).isEqualTo(Platform.NINTENDO)
        assertThat(PlatformLabels.toPlatform("Nintendo Switch")).isEqualTo(Platform.NINTENDO)
        assertThat(PlatformLabels.toPlatform("Mobile")).isEqualTo(Platform.MOBILE)
        assertThat(PlatformLabels.toPlatform("Android")).isEqualTo(Platform.MOBILE)
    }

    @Test fun profilesComeFromTheCatalogNotFromHardcodedThresholds() {
        fun profile(id: String, plat: String) = (MeasurementPlanner.plan(payload, id, plat, now = now) as PlanResult.Ready).context.profileId
        assertThat(profile("valorant", "PC")).isEqualTo(QualityProfileId.BATTLE_ROYALE_COMPETITIVE)
        assertThat(profile("brawl-stars", "Mobile")).isEqualTo(QualityProfileId.MOBILE_REALTIME)
        assertThat(profile("roblox", "PlayStation")).isEqualTo(QualityProfileId.CASUAL_REALTIME)
    }

    @Test fun genericCheckResolvesWithoutAGame() {
        val plan = MeasurementPlanner.plan(payload, PlatformLabels.GENERIC_GAME_ID, "Android", now = now) as PlanResult.Ready
        assertThat(plan.context.profileId).isEqualTo(QualityProfileId.BATTLE_ROYALE_COMPETITIVE)
        assertThat(plan.context.regionId).isEqualTo("sa-east-1")
    }

    @Test fun regionalPlanPreReadsEverySignedReferenceBeforeChoosing() {
        val snapshot = MeasurementPlanner.planRegional(payload, "fortnite", "Mobile", now = now)!!

        assertThat(snapshot.candidates.map { it.regionId }).isEqualTo(payload.regions.map { it.id })
        assertThat(snapshot.candidates.map { it.priority }.toSet()).containsExactly(0)
        assertThat(snapshot.candidates[0].resolvedContext.destination.host).isEqualTo("gamelift-ping.sa-east-1.api.aws")
        assertThat(snapshot.candidates[1].resolvedContext.destination.host).isEqualTo("gamelift-ping.us-east-1.api.aws")
    }

    @Test fun unsupportedGamePlatformCombinationFailsExplicitly() {
        val plan = MeasurementPlanner.plan(payload, "valorant", "Mobile", now = now)
        assertThat(plan).isEqualTo(PlanResult.Failed(PlanFailure.UNSUPPORTED_GAME_OR_PLATFORM))
        assertThat(MeasurementPlanner.plan(payload, "nao-existe", "PC", now = now))
            .isEqualTo(PlanResult.Failed(PlanFailure.UNSUPPORTED_GAME_OR_PLATFORM))
    }
}
