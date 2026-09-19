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
            image: verifiedImage,
            sourceRecordID: game.artwork?.sha256,
            title: game.name,
            aspectRatio: aspectRatio
        )
        .task(id: artworkIdentity) {
            verifiedImage = nil
            guard let data = await VerifiedRemoteArtworkLoader.shared.imageData(
                artwork: game.artwork,
                assetBaseURL: game.assetBaseURL
            ),
            !Task.isCancelled,
            let uiImage = UIImage(data: data) else {
                return
            }
            verifiedImage = Image(uiImage: uiImage)
        }
    }

    private var artworkIdentity: String {
        "\(game.assetBaseURL ?? "")|\(game.artwork?.path ?? "")|\(game.artwork?.sha256 ?? "")"
    }
}
