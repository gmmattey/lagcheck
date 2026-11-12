import Foundation
import UIKit
import CryptoKit

/// Snapshot imutável de todos os campos que o card de link efetivamente desenha.
/// Paridade 1:1 estrita com PreparedShareCardSnapshot.kt do Android (Decisões 81 e 103).
public struct PreparedShareCardSnapshot: Sendable, Equatable {
    public let gameName: String
    public let artAssetName: String
    public let tone: ShareTone
    public let headline: String
    public let regionName: String
    public let metrics: [ShareMetric]
    public let localeTag: String
    public let measurementIdentity: String

    public var cacheKey: String {
        var result = "\(gameName)|\(artAssetName)|\(tone.rawValue)|\(headline)|\(regionName)|\(localeTag)|\(measurementIdentity)"
        for m in metrics {
            result += "|\(m.kind.rawValue):\(m.value):\(m.unit)"
        }
        return result
    }

    public func scene() -> ShareMediaScene {
        ShareMediaScene(
            gameName: gameName,
            artAssetName: artAssetName,
            tone: tone,
            headline: headline,
            regionName: regionName,
            metrics: metrics
        )
    }

    public static func from(
        scene: ShareMediaScene,
        localeTag: String,
        measurementIdentity: String
    ) -> PreparedShareCardSnapshot {
        PreparedShareCardSnapshot(
            gameName: scene.gameName,
            artAssetName: scene.artAssetName,
            tone: scene.tone,
            headline: scene.headline,
            regionName: scene.regionName,
            metrics: scene.metrics,
            localeTag: localeTag,
            measurementIdentity: measurementIdentity
        )
    }
}

/// Cache efêmero do card de link (1200x630 JPEG).
/// O arquivo é identificado pelo snapshot que o originou, para que um reteste nunca entregue por acidente o card anterior.
public enum PreparedShareCard {
    private static let lock = NSLock()

    public static func fileFor(snapshot: PreparedShareCardSnapshot) -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("share", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let hash = digest(snapshot.cacheKey)
        return dir.appendingPathComponent("lagcheck-link-\(hash).jpg")
    }

    public static func prepare(snapshot: PreparedShareCardSnapshot) -> URL? {
        lock.lock()
        defer { lock.unlock() }

        let file = fileFor(snapshot: snapshot)
        if FileManager.default.fileExists(atPath: file.path) {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
               let size = attrs[.size] as? UInt64, size > 0 {
                return file
            }
        }

        let scene = snapshot.scene()
        let images = ShareMediaImages.load(scene: scene, withTiles: false)
        guard let data = ShareMediaRenderer.jpeg(kind: .preview, scene: scene, images: images) else {
            return nil
        }

        let tempURL = file.appendingPathExtension("tmp")
        do {
            try data.write(to: tempURL, options: .atomic)
            if FileManager.default.fileExists(atPath: file.path) {
                try? FileManager.default.removeItem(at: file)
            }
            try FileManager.default.moveItem(at: tempURL, to: file)
            return file
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }

    public static func digest(_ snapshotKey: String) -> String {
        let data = Data(snapshotKey.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(24).description
    }
}
