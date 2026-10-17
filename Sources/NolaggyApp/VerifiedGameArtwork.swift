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
        guard let assetName = GameArtworkAssetResolver.assetName(for: game.id),
              UIImage(named: assetName, in: .main, with: nil) != nil else { return nil }
        return Image(assetName, bundle: .main)
    }

    private var artworkIdentity: String {
        "\(game.assetBaseURL ?? "")|\(game.artwork?.path ?? "")|\(game.artwork?.sha256 ?? "")"
    }
}
