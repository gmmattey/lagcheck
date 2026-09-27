import SwiftUI
import UIKit
import NolaggyApplication
import NolaggyDesign
import NolaggyInfrastructure

/// Ponte de composição entre a referência assinada no catálogo e o componente
/// visual. Enquanto a arte não tiver bytes íntegros, `GameArtwork` continua
/// usando o asset local/fallback do app.
struct VerifiedGameArtwork: View {
    let game: CatalogMeasurementJourney.Game
    var aspectRatio: CGFloat? = nil

    @State private var verifiedImage: Image?

    var body: some View {
        GameArtwork(
            image: localAssetImage,
            title: game.name,
            aspectRatio: aspectRatio
        )
    }

    private var localAssetImage: Image? {
        let id = game.id.lowercased().replacingOccurrences(of: "-", with: "")
        let mapping: [(String, String)] = [
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
