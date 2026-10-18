import UIKit

/// Imagens dos cards e do vídeo. A arte é a autoral local do jogo; sem ela, o fundo é liso escuro.
/// Paridade com ShareMediaImages.kt do Android, com STORE_URL apontando para a App Store.
public final class ShareMediaImages: @unchecked Sendable {
    public static let STORE_URL = "https://apps.apple.com/app/id6818706960"

    public let art: UIImage?
    public let wordmark: UIImage?
    public let tiles: [UIImage]

    public init(art: UIImage?, wordmark: UIImage?, tiles: [UIImage]) {
        self.art = art
        self.wordmark = wordmark
        self.tiles = tiles
    }

    /// Artes da grade da primeira cena do vídeo (sem o jogo escolhido).
    private static let gridAssetNames = [
        "GameFortnite", "GameCs2", "GameFreeFire", "GameLeagueOfLegends", "GameRoblox",
        "GameMinecraft", "GameEaFc", "GameApexLegends", "GameValorant"
    ]

    public static func load(scene: ShareMediaScene, withTiles: Bool) -> ShareMediaImages {
        let resolvedArt: UIImage?
        if !scene.artAssetName.isEmpty, let img = findImage(named: scene.artAssetName) {
            resolvedArt = img
        } else if let assetName = GameArtworkAssetResolver.assetName(for: scene.gameName),
                  let img = findImage(named: assetName) {
            resolvedArt = img
        } else if let fallback = findImage(named: "AppBackground") {
            resolvedArt = fallback
        } else {
            resolvedArt = nil
        }

        let wordmarkImg = findImage(named: "WordmarkPrimary")

        let tiles: [UIImage]
        if withTiles {
            tiles = gridAssetNames
                .filter { $0 != scene.artAssetName }
                .prefix(8)
                .compactMap { findImage(named: $0) }
        } else {
            tiles = []
        }

        return ShareMediaImages(
            art: resolvedArt,
            wordmark: wordmarkImg,
            tiles: tiles
        )
    }

    private static func findImage(named name: String) -> UIImage? {
        if let img = UIImage(named: name, in: .main, with: nil) {
            return img
        }
        return UIImage(named: name)
    }
}
