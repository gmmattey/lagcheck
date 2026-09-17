import Foundation
import NolaggyDomain

/// A única porta da aplicação entre um catálogo já validado e uma medição.
/// Descoberta e seleção nunca expõem JSON, host ou porta para a interface.
public enum CatalogMeasurementJourney {
    public struct Game: Equatable, Sendable, Identifiable {
        public let id: String
        public let name: String
        public let context: GameContext
        public let profileID: QualityProfileID

        public init(id: String, name: String, context: GameContext, profileID: QualityProfileID) {
            self.id = id
            self.name = name
            self.context = context
            self.profileID = profileID
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case unavailableContext
    }

    public static func availableGames(
        in payload: RemoteCatalogPayload,
        market: String,
        platform: Platform
    ) -> [Game] {
        payload.games.compactMap { game in
            let context = GameContext(gameID: game.id, market: market, platform: platform)
            guard case let .available(resolved) = try? RemoteCatalogVerifier.resolve(context, in: payload) else { return nil }
            return Game(id: game.id, name: game.name, context: context, profileID: resolved.profileID)
        }
    }

    public static func regionalSnapshot(
        for context: GameContext,
        in payload: RemoteCatalogPayload
    ) throws -> RegionalSelectionSnapshot {
        guard case .available = try RemoteCatalogVerifier.resolve(context, in: payload) else {
            throw Error.unavailableContext
        }
        return try RemoteCatalogVerifier.regionalSelectionSnapshot(context, in: payload)
    }

    public static func viewSnapshot(
        from snapshot: RegionalSelectionSnapshot,
        in payload: RemoteCatalogPayload,
        localeIdentifier: String = Locale.current.identifier
    ) -> RegionalSelectionViewSnapshot {
        let language = localeIdentifier.lowercased().hasPrefix("pt") ? "pt-BR" : "en"
        return RegionalSelectionViewSnapshot(
            catalogVersion: snapshot.catalogVersion,
            candidates: snapshot.candidates.map { candidate in
                let label = payload.regions.first(where: { $0.id == candidate.regionID })?.label[language]
                    ?? candidate.regionID
                return .init(
                    regionID: candidate.regionID,
                    label: label,
                    priority: candidate.priority,
                    resolvedContext: candidate.resolvedContext
                )
            }
        )
    }
}
