import UIKit
import WidgetKit
import NolaggyInfrastructure

/// Materializa uma miniatura pequena a partir da mesma arte local aprovada que o app iOS exibe.
/// Não inicia transferência remota: o widget é só apresentação do último Check concluído.
enum WidgetArtworkSnapshotWriter {
    @discardableResult
    static func saveArtwork(forGameID gameID: String) -> Bool {
        guard let assetName = GameArtworkAssetResolver.assetName(for: gameID),
              let image = UIImage(named: assetName),
              let data = thumbnailData(from: image) else {
            SharedAppGroupStore.shared.saveLatestArtwork(nil)
            return false
        }
        return SharedAppGroupStore.shared.saveLatestArtwork(data)
    }

    static func refreshWidget() { WidgetCenter.shared.reloadTimelines(ofKind: "LagCheckWidget") }

    private static func thumbnailData(from image: UIImage) -> Data? {
        let target = CGSize(width: 480, height: 300)
        let ratio = max(target.width / image.size.width, target.height / image.size.height)
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let origin = CGPoint(x: (target.width - size.width) / 2, y: (target.height - size.height) / 2)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in image.draw(in: CGRect(origin: origin, size: size)) }
            .jpegData(compressionQuality: 0.72)
    }
}

enum GameArtworkAssetResolver {
    static func assetName(for gameID: String) -> String? {
        let id = gameID.lowercased().replacingOccurrences(of: "-", with: "")
        let mapping: [(String, String)] = [
            ("deadbydaylight", "GameDeadByDaylight"), ("forhonor", "GameForHonor"),
            ("borderlands3", "GameBorderlands3"), ("newworld", "GameNewWorld"),
            ("fortnite", "GameFortnite"), ("valorant", "GameValorant"), ("warzone", "GameWarzone"),
            ("cs2", "GameCs2"), ("leagueoflegends", "GameLeagueOfLegends"), ("roblox", "GameRoblox"),
            ("freefire", "GameFreeFire"), ("apex", "GameApexLegends"), ("rainbowsix", "GameRainbowSix"),
            ("rocketleague", "GameRocketLeague"), ("dota2", "GameDota2"), ("minecraft", "GameMinecraft"),
            ("brawlstars", "GameBrawlStars"), ("bloodstrike", "GameBloodStrike"), ("rust", "GameRust"),
            ("palworld", "GamePalworld"), ("eafc", "GameEaFc"), ("pubg", "GamePubg"),
            ("callofduty", "GameCodm"), ("codm", "GameCodm"), ("wildrift", "GameWildRift"),
            ("squidgame", "GameSquidGameUnleashed"), ("darktide", "GameWarhammerDarktide"),
            ("marvelsnap", "GameMarvelSnap"), ("outlast", "GameTheOutlastTrials"), ("midgard", "GameTribesOfMidgard"),
            ("crossfar", "GameCrossfar"), ("lostrift", "GameLostRift"), ("starwarshunters", "GameStarWarsHunters"),
            ("rematch", "GameRematch"), ("predecessor", "GamePredecessor"), ("supermegabaseball", "GameSuperMegaBaseball4"),
            ("marauders", "GameMarauders"), ("steelandsorcery", "GameLegacySteelAndSorcery"),
            ("ninjala", "GameNinjala"), ("rollerchampions", "GameRollerChampions"),
            ("breakpoint", "GameGhostReconBreakpoint"), ("darkalliance", "GameDarkAlliance"),
            ("wolcen", "GameWolcenLordsOfMayhem"), ("streamline", "GameStreamline"),
            ("tacticool", "GameTacticool"), ("ghostwar", "GameGhostWar"), ("overwatch", "GameOverwatch2"),
            ("clashroyale", "GameClashRoyale"), ("pokemonunite", "GamePokemonUnite"),
            ("genshin", "GameGenshinImpact"), ("mobilelegends", "GameMobileLegends"),
            ("deltaforce", "GameDeltaForce"), ("standoff2", "GameStandoff2")
        ]
        return mapping.first(where: { id.contains($0.0) })?.1
    }
}
