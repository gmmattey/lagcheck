import SwiftUI
import UIKit
import NolaggyDomain
import NolaggyApplication
import NolaggyDesign

/// Gerador do Card Viral de Alta Fidelidade para Discord, WhatsApp e Redes Sociais.
/// Gera um JPEG em 1200x630 (link preview), delegando para o motor canônico `ShareMediaRenderer`.
/// Mantém compatibilidade com pontos de chamada existentes.
public enum LagCheckDiscordCardExporter {

    public static let linkCardSize = CGSize(width: 1200, height: 630)

    public static func generateDiscordShareCard(
        gameID: String? = nil,
        gameName: String,
        regionName: String,
        verdict: GameReadinessVerdict,
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        bufferbloatGradeText: String? = nil,
        isWiFi: Bool = true,
        outputURL: URL? = nil
    ) -> URL? {
        guard let scene = ShareMediaScene.from(
            gameName: gameName,
            artAssetName: gameID.flatMap(GameArtworkAssetResolver.assetName(for:)) ?? "",
            verdict: verdict,
            headline: headlineSentence(for: verdict),
            regionName: regionName,
            pingMs: pingMs,
            jitterMs: jitterMs,
            lossPercentage: packetLossPercentage
        ) else {
            return nil
        }

        let images = ShareMediaImages.load(scene: scene, withTiles: false)
        guard let data = ShareMediaRenderer.jpeg(kind: .preview, scene: scene, images: images) else {
            return nil
        }

        let url = outputURL ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("lagcheck-share-\(UUID().uuidString).jpg")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Prepara apenas o card estático de link para um snapshot de Check já concluído.
    /// O cache é temporário e a chave inclui a medição, evitando reutilizar um reteste anterior.
    public static func prepareDiscordShareCard(
        snapshotKey: String,
        gameID: String? = nil,
        gameName: String,
        regionName: String,
        verdict: GameReadinessVerdict,
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        bufferbloatGradeText: String?,
        isWiFi: Bool
    ) -> URL? {
        guard let scene = ShareMediaScene.from(
            gameName: gameName,
            artAssetName: gameID.flatMap(GameArtworkAssetResolver.assetName(for:)) ?? "",
            verdict: verdict,
            headline: headlineSentence(for: verdict),
            regionName: regionName,
            pingMs: pingMs,
            jitterMs: jitterMs,
            lossPercentage: packetLossPercentage
        ) else {
            return nil
        }

        let snapshot = PreparedShareCardSnapshot.from(
            scene: scene,
            localeTag: AppLocalization.locale.identifier,
            measurementIdentity: snapshotKey
        )
        return PreparedShareCard.prepare(snapshot: snapshot)
    }

    public static func headlineSentence(for verdict: GameReadinessVerdict) -> String {
        switch verdict {
        case .ready: return AppLocalization.string("game_readiness.verdict.ready.headline", comment: "")
        case .caution: return AppLocalization.string("game_readiness.verdict.caution.headline", comment: "")
        case .notReady: return AppLocalization.string("game_readiness.verdict.not_ready.headline", comment: "")
        case .inconclusive: return AppLocalization.string("game_readiness.verdict.inconclusive.headline", comment: "")
        }
    }

    public static func gamerQuote(for verdict: GameReadinessVerdict) -> String {
        switch verdict {
        case .ready:
            return AppLocalization.string("exporter.discord.quote.ready", comment: "")
        case .caution:
            return AppLocalization.string("exporter.discord.quote.caution", comment: "")
        case .notReady:
            return AppLocalization.string("exporter.discord.quote.not_ready", comment: "")
        case .inconclusive:
            return AppLocalization.string("exporter.discord.quote.inconclusive", comment: "")
        }
    }
}
