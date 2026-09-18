import Foundation
import NolaggyDomain

/// A única porta da aplicação entre um catálogo já validado e uma medição.
/// Descoberta e seleção nunca expõem JSON, host ou porta para a interface.
public enum CatalogMeasurementJourney {
    public struct Game: Hashable, Sendable, Identifiable {
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

    public static func resolvedMarket(
        in payload: RemoteCatalogPayload,
        preferred: String? = nil
    ) -> String {
        let systemRegion = preferred ?? Locale.current.region?.identifier ?? "US"
        let upper = systemRegion.uppercased()
        let availableMarkets = Set(payload.games.flatMap { $0.contexts.map { $0.market.uppercased() } })
        if availableMarkets.contains(upper) {
            return upper
        }
        if availableMarkets.contains("US") {
            return "US"
        }
        if availableMarkets.contains("BR") {
            return "BR"
        }
        return availableMarkets.first ?? "BR"
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
        in payload: RemoteCatalogPayload,
        manualRegionID: String? = nil
    ) throws -> RegionalSelectionSnapshot {
        guard case let .available(baseResolved) = try RemoteCatalogVerifier.resolve(context, in: payload) else {
            throw Error.unavailableContext
        }
        var snapshot = try RemoteCatalogVerifier.regionalSelectionSnapshot(context, in: payload)
        if let manualRegionID,
           !snapshot.candidates.contains(where: { $0.regionID == manualRegionID }),
           let globalDef = GlobalProbeRegistry.definition(for: manualRegionID) {
            let manualResolved = ResolvedMeasurementContext(
                context: context,
                catalogVersion: payload.catalogVersion,
                profileID: baseResolved.profileID,
                profileRuleVersion: baseResolved.profileRuleVersion,
                regionID: globalDef.id,
                destination: globalDef.probeDestination,
                strategy: baseResolved.strategy,
                confidence: baseResolved.confidence,
                precisionKey: "regionalReference"
            )
            let manualCandidate = try RegionalSelectionCandidate(resolvedContext: manualResolved, priority: 0)
            snapshot = try RegionalSelectionSnapshot(
                catalogVersion: payload.catalogVersion,
                context: context,
                candidates: snapshot.candidates + [manualCandidate]
            )
        }
        return snapshot
    }

    public static func viewSnapshot(
        from snapshot: RegionalSelectionSnapshot,
        in payload: RemoteCatalogPayload,
        localeIdentifier: String = Locale.current.identifier
    ) -> RegionalSelectionViewSnapshot {
        let lower = localeIdentifier.lowercased()
        let language: String
        if lower.hasPrefix("pt") {
            language = "pt-BR"
        } else if lower.hasPrefix("es") {
            language = "es"
        } else {
            language = "en"
        }
        return RegionalSelectionViewSnapshot(
            catalogVersion: snapshot.catalogVersion,
            candidates: snapshot.candidates.map { candidate in
                let label = payload.regions.first(where: { $0.id == candidate.regionID })?.label[language]
                    ?? GlobalProbeRegistry.friendlyLabel(for: candidate.regionID, languageCode: language)
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
