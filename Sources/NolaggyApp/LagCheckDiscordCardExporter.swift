import SwiftUI
import UIKit
import NolaggyDomain
import NolaggyDesign

/// JPEG 1200×630 preparado somente para um snapshot conclusivo já medido.
public enum LagCheckDiscordCardExporter {
    private static let preparationLock = NSLock()
    public static let linkCardSize = CGSize(width: 1200, height: 630)

    public static func generateDiscordShareCard(gameName: String, gameID: String? = nil, regionName: String, verdict: GameReadinessVerdict, pingMs: Double?, jitterMs: Double?, packetLossPercentage: Double?, bufferbloatGradeText: String?, isWiFi: Bool, outputURL: URL? = nil) -> URL? {
        guard verdict != .inconclusive, pingMs != nil, jitterMs != nil else { return nil }
        let bounds = CGRect(origin: .zero, size: linkCardSize)
        let output = outputURL ?? FileManager.default.temporaryDirectory.appendingPathComponent("LagCheck_\(UUID().uuidString).jpg")
        let image = UIGraphicsImageRenderer(bounds: bounds).image { context in
            let cg = context.cgContext
            cg.setFillColor(UIColor(NLColor.deep).cgColor); cg.fill(bounds)
            drawArtwork(forGameID: gameID, in: CGRect(x: 0, y: 0, width: 590, height: linkCardSize.height))
            drawArtworkGradient(in: bounds, context: cg)

            let left: CGFloat = 610, right: CGFloat = 1140
            if let wordmark = UIImage(named: "WordmarkPrimary") { wordmark.draw(in: aspectFitRect(image: wordmark, in: CGRect(x: left, y: 42, width: 160, height: 38))) }
            draw("lagcheck.signallq.com", in: CGRect(x: left, y: 58, width: right - left, height: 28), font: .monospacedSystemFont(ofSize: 18, weight: .medium), color: UIColor(NLColor.textSecondary), alignment: .right)
            draw(String(format: AppLocalization.string("share.card.kicker %@", comment: ""), gameName.uppercased()), at: CGPoint(x: left, y: 135), font: .monospacedSystemFont(ofSize: 18, weight: .bold), color: UIColor(NLColor.accentPrimary))
            let headline = AppLocalization.string(headlineKey(for: verdict), comment: "")
            drawWrapped(headline, in: CGRect(x: left, y: 170, width: right - left, height: 142), font: .systemFont(ofSize: 48, weight: .bold), color: UIColor(NLColor.textPrimary), lineHeight: 54)

            let metrics = [
                (AppLocalization.string("share.card.metric.response", comment: ""), formattedMilliseconds(pingMs), "ms"),
                (AppLocalization.string("share.card.metric.jitter", comment: ""), formattedMilliseconds(jitterMs), "ms"),
                (AppLocalization.string("share.card.metric.loss", comment: ""), formattedLoss(packetLossPercentage), "%")
            ]
            for (index, metric) in metrics.enumerated() {
                drawMetric(label: metric.0, value: metric.1, unit: metric.1 == "—" ? "" : metric.2, in: CGRect(x: left + CGFloat(index) * 180, y: 346, width: 160, height: 94))
            }
            drawPill(headline, tone: toneColor(for: verdict), in: CGRect(x: 48, y: 520, width: 390, height: 58))
            draw(AppLocalization.string("share.card.udp_proof", comment: ""), at: CGPoint(x: left, y: 500), font: .systemFont(ofSize: 20, weight: .medium), color: UIColor(NLColor.textSecondary))
            draw(regionName.uppercased(), at: CGPoint(x: left, y: 531), font: .monospacedSystemFont(ofSize: 17, weight: .semibold), color: UIColor(NLColor.textPrimary))
            let connection = isWiFi ? AppLocalization.string("exporter.discord.wifi_iphone", comment: "") : AppLocalization.string("exporter.discord.cellular", comment: "")
            draw(connection, in: CGRect(x: left, y: 531, width: right - left, height: 28), font: .monospacedSystemFont(ofSize: 14, weight: .medium), color: UIColor(NLColor.textTertiary), alignment: .right)
            _ = bufferbloatGradeText
        }
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        do { try data.write(to: output); return output } catch { return nil }
    }

    public static func prepareDiscordShareCard(snapshotKey: String, gameName: String, gameID: String? = nil, regionName: String, verdict: GameReadinessVerdict, pingMs: Double?, jitterMs: Double?, packetLossPercentage: Double?, bufferbloatGradeText: String?, isWiFi: Bool) -> URL? {
        guard verdict != .inconclusive, pingMs != nil, jitterMs != nil else { return nil }
        preparationLock.lock(); defer { preparationLock.unlock() }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lagcheck-share-\(stableIdentifier(snapshotKey)).jpg")
        if FileManager.default.fileExists(atPath: url.path) { return url }
        return generateDiscordShareCard(gameName: gameName, gameID: gameID, regionName: regionName, verdict: verdict, pingMs: pingMs, jitterMs: jitterMs, packetLossPercentage: packetLossPercentage, bufferbloatGradeText: bufferbloatGradeText, isWiFi: isWiFi, outputURL: url)
    }

    public static func gamerQuote(for verdict: GameReadinessVerdict) -> String {
        switch verdict {
        case .ready: return AppLocalization.string("exporter.discord.quote.ready", comment: "")
        case .caution: return AppLocalization.string("exporter.discord.quote.caution", comment: "")
        case .notReady: return AppLocalization.string("exporter.discord.quote.not_ready", comment: "")
        case .inconclusive: return AppLocalization.string("exporter.discord.quote.inconclusive", comment: "")
        }
    }

    private static func drawArtwork(forGameID gameID: String?, in rect: CGRect) {
        guard let gameID, let name = GameArtworkAssetResolver.assetName(for: gameID), let artwork = UIImage(named: name) else {
            drawNeutralArtwork(in: rect)
            return
        }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.clip(to: rect)
        artwork.draw(in: aspectFillRect(image: artwork, in: rect))
        context.restoreGState()
    }
    private static func drawNeutralArtwork(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.setFillColor(UIColor(NLColor.surface).cgColor)
        context.fill(rect)
        context.setStrokeColor(UIColor(NLColor.borderSubtle).cgColor)
        context.setLineWidth(1)
        context.stroke(rect.insetBy(dx: 20, dy: 20))
        if let wordmark = UIImage(named: "WordmarkPrimary") {
            wordmark.draw(in: aspectFitRect(image: wordmark, in: CGRect(x: rect.minX + 74, y: rect.midY - 40, width: rect.width - 148, height: 56)))
        }
        draw(AppLocalization.string("exporter.discord.official_tag", comment: "").uppercased(), at: CGPoint(x: rect.minX + 74, y: rect.midY + 42), font: .monospacedSystemFont(ofSize: 15, weight: .bold), color: UIColor(NLColor.textSecondary))
        context.restoreGState()
    }
    private static func drawArtworkGradient(in bounds: CGRect, context: CGContext) {
        let colors = [UIColor(NLColor.deep).withAlphaComponent(0.08).cgColor, UIColor(NLColor.deep).withAlphaComponent(0.36).cgColor, UIColor(NLColor.deep).withAlphaComponent(0.96).cgColor]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.42, 0.62]) else { return }
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: bounds.width, y: 0), options: [])
    }
    private static func drawMetric(label: String, value: String, unit: String, in rect: CGRect) {
        draw(label.uppercased(), at: CGPoint(x: rect.minX, y: rect.minY), font: .monospacedSystemFont(ofSize: 13, weight: .bold), color: UIColor(NLColor.textTertiary))
        draw(value, at: CGPoint(x: rect.minX, y: rect.minY + 25), font: .monospacedSystemFont(ofSize: 34, weight: .heavy), color: UIColor(NLColor.textPrimary))
        if !unit.isEmpty { draw(unit, at: CGPoint(x: rect.minX, y: rect.minY + 67), font: .monospacedSystemFont(ofSize: 16, weight: .bold), color: UIColor(NLColor.textSecondary)) }
    }
    private static func drawPill(_ text: String, tone: UIColor, in rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
        UIColor(NLColor.deep).withAlphaComponent(0.75).setFill(); path.fill(); UIColor.white.withAlphaComponent(0.14).setStroke(); path.lineWidth = 1; path.stroke()
        tone.setFill(); UIBezierPath(ovalIn: CGRect(x: rect.minX + 20, y: rect.midY - 8, width: 16, height: 16)).fill()
        draw(text, at: CGPoint(x: rect.minX + 50, y: rect.minY + 17), font: .monospacedSystemFont(ofSize: 16, weight: .bold), color: tone)
    }
    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        draw(text, in: CGRect(origin: point, size: CGSize(width: 700, height: 100)), font: font, color: color)
    }
    private static func draw(_ text: String, in rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) {
        let style = NSMutableParagraphStyle(); style.alignment = alignment
        NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style]).draw(in: rect)
    }
    private static func drawWrapped(_ text: String, in rect: CGRect, font: UIFont, color: UIColor, lineHeight: CGFloat) {
        let style = NSMutableParagraphStyle(); style.lineBreakMode = .byWordWrapping; style.minimumLineHeight = lineHeight; style.maximumLineHeight = lineHeight
        NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style]).draw(in: rect)
    }
    private static func aspectFillRect(image: UIImage, in rect: CGRect) -> CGRect { let scale = max(rect.width / image.size.width, rect.height / image.size.height); let size = CGSize(width: image.size.width * scale, height: image.size.height * scale); return CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height) }
    private static func aspectFitRect(image: UIImage, in rect: CGRect) -> CGRect { let scale = min(rect.width / image.size.width, rect.height / image.size.height); let size = CGSize(width: image.size.width * scale, height: image.size.height * scale); return CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height) }
    private static func formattedMilliseconds(_ value: Double?) -> String { value.map { "\(Int($0.rounded()))" } ?? "—" }
    private static func formattedLoss(_ value: Double?) -> String {
        guard let value else { return "—" }
        if value <= 0.05 { return "0" }
        let formatter = NumberFormatter()
        formatter.locale = AppLocalization.locale
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    private static func headlineKey(for verdict: GameReadinessVerdict) -> String { switch verdict { case .ready: return "game_readiness.verdict.ready.headline"; case .caution: return "game_readiness.verdict.caution.headline"; case .notReady: return "game_readiness.verdict.not_ready.headline"; case .inconclusive: return "game_readiness.verdict.inconclusive.headline" } }
    private static func toneColor(for verdict: GameReadinessVerdict) -> UIColor { switch verdict { case .ready: return UIColor(NLColor.semanticReady); case .caution: return UIColor(NLColor.semanticCaution); case .notReady: return UIColor(NLColor.semanticNotReady); case .inconclusive: return UIColor(NLColor.textSecondary) } }
    private static func stableIdentifier(_ value: String) -> String { var hash: UInt64 = 1_469_598_103_934_665_603; for byte in value.utf8 { hash ^= UInt64(byte); hash &*= 1_099_511_628_211 }; return String(hash, radix: 16) }
}
