import SwiftUI
import UIKit
import NolaggyApplication
import NolaggyDesign
import NolaggyInfrastructure

private struct ArtworkDownloadsAllowedKey: EnvironmentKey {
    static let defaultValue = true
}
extension EnvironmentValues {
    var artworkDownloadsAllowed: Bool {
        get { self[ArtworkDownloadsAllowedKey.self] }
        set { self[ArtworkDownloadsAllowedKey.self] = newValue }
    }
}

/// Arte remota oportunista (Decisão 71), com fallback local imediato.
struct VerifiedGameArtwork: View {
    let game: CatalogMeasurementJourney.Game
    var aspectRatio: CGFloat? = nil

    @State private var verifiedImage: Image?
    @Environment(\.artworkDownloadsAllowed) private var downloadsAllowed

    var body: some View {
        GameArtwork(
            image: verifiedImage ?? localAssetImage,
            title: game.name,
            aspectRatio: aspectRatio
        )
        .task(id: "\(artworkIdentity)|\(downloadsAllowed)") {
            guard downloadsAllowed else { return }
            verifiedImage = nil
            guard let data = await VerifiedRemoteArtworkLoader.shared.imageData(
                artwork: game.artwork, assetBaseURL: game.assetBaseURL
            ), !Task.isCancelled, let image = UIImage(data: data) else { return }
            verifiedImage = Image(uiImage: image)
        }
    }

    private var localAssetImage: Image? {
        let id = game.id.lowercased().replacingOccurrences(of: "-", with: "")
        let mapping: [(String, String)] = [
            ("deadbydaylight", "GameDeadByDaylight"),
            ("forhonor", "GameForHonor"),
            ("borderlands3", "GameBorderlands3"),
            ("newworld", "GameNewWorld"),
            ("fortnite", "GameFortnite"),
            ("valorant", "GameValorant"),
            ("warzone", "GameWarzone"),
            ("cs2", "GameCs2"),
            ("leagueoflegends", "GameLeagueOfLegends"),
            ("roblox", "GameRoblox"),
            ("freefire", "GameFreeFire"),
            ("apex", "GameApexLegends"),
            ("rainbowsix", "GameRainbowSix"),
            ("rocketleague", "GameRocketLeague"),
            ("dota2", "GameDota2"),
            ("minecraft", "GameMinecraft"),
            ("brawlstars", "GameBrawlStars"),
            ("bloodstrike", "GameBloodStrike"),
            ("rust", "GameRust"),
            ("palworld", "GamePalworld"),
            ("eafc", "GameEaFc"),
            ("pubg", "GamePubg"),
            ("callofduty", "GameCodm"),
            ("codm", "GameCodm"),
            ("wildrift", "GameWildRift")
        ]
        for (key, assetName) in mapping {
            if id.contains(key) {
                if UIImage(named: assetName, in: .main, with: nil) != nil {
                    return Image(assetName, bundle: .main)
                }
            }
        }
        return nil
    }

    private var artworkIdentity: String {
        "\(game.assetBaseURL ?? "")|\(game.artwork?.path ?? "")|\(game.artwork?.sha256 ?? "")"
    }
}
