import Foundation
import CoreSpotlight
import NolaggyDomain

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Adaptador para indexação nativa no CoreSpotlight do iOS (Decisão 76).
/// Permite que títulos do LagCheck apareçam na busca do sistema e no Siri Suggestions.
public final class AppleCoreSpotlightIndexer: SpotlightIndexing, @unchecked Sendable {
    private let searchableIndex: CSSearchableIndex
    
    public init(searchableIndex: CSSearchableIndex = CSSearchableIndex.default()) {
        self.searchableIndex = searchableIndex
    }
    
    public func indexGames(_ games: [SpotlightIndexableGame]) async throws {
        guard CSSearchableIndex.isIndexingAvailable() else { return }
        
        let items: [CSSearchableItem] = games.map { game in
            let attributeSet: CSSearchableItemAttributeSet
            if #available(iOS 14.0, *) {
                attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            } else {
                attributeSet = CSSearchableItemAttributeSet(itemContentType: "kUTTypeContent")
            }
            
            attributeSet.title = game.title
            attributeSet.contentDescription = game.summary
            attributeSet.keywords = game.keywords
            
            return CSSearchableItem(
                uniqueIdentifier: "lagcheck.game.\(game.gameID)",
                domainIdentifier: "com.lagcheck.catalog",
                attributeSet: attributeSet
            )
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            searchableIndex.indexSearchableItems(items) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    public func removeAllIndexedGames() async throws {
        guard CSSearchableIndex.isIndexingAvailable() else { return }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            searchableIndex.deleteSearchableItems(withDomainIdentifiers: ["com.lagcheck.catalog"]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
