import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import NolaggyDomain
import NolaggyApplication
import NolaggyDesign

/// Gerador do Card Viral de Alta Fidelidade para Discord, WhatsApp e Redes Sociais.
/// Gera um JPEG em 1200x630, o formato de preview de link do LagCheck.
/// com estética Dark Competitive UI, tipografia pesada e números de corrida.
public enum LagCheckDiscordCardExporter {

    private static let preparationLock = NSLock()
    public static let linkCardSize = CGSize(width: 1200, height: 630)

    public static func generateDiscordShareCard(
        gameID: String? = nil,
        gameName: String,
        regionName: String,
        verdict: GameReadinessVerdict,
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        bufferbloatGradeText: String?,
        isWiFi: Bool,
        outputURL: URL? = nil
    ) -> URL? {
        generateEditorialShareCard(
            gameID: gameID,
            gameName: gameName,
            regionName: regionName,
            verdict: verdict,
            pingMs: pingMs,
            jitterMs: jitterMs,
            packetLossPercentage: packetLossPercentage,
            outputURL: outputURL
        )
    }

    /// A mesma composição editorial Link do Android, adaptada para UIKit.
    /// As coordenadas são mantidas em canvas de 1200×630 para que a miniatura
    /// do iPhone seja o mesmo card de decisão, e não uma versão "parecida".
    private static func generateEditorialShareCard(
        gameID: String?,
        gameName: String,
        regionName: String,
        verdict: GameReadinessVerdict,
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        outputURL: URL?
    ) -> URL? {
        let bounds = CGRect(origin: .zero, size: linkCardSize)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { rendererContext in
            let cg = rendererContext.cgContext
            let deep = UIColor(NLColor.deep)
            let text = UIColor(NLColor.textPrimary)
            let muted = UIColor(NLColor.textTertiary)
            let accent = UIColor(NLColor.gamerPurple)
            let tone = verdictColor(verdict)

            cg.setFillColor(deep.cgColor)
            cg.fill(bounds)
            if let artwork = artworkImage(gameID: gameID, gameName: gameName) {
                drawAspectFill(artwork, in: bounds, context: cg)
            }
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    deep.withAlphaComponent(0.12).cgColor,
                    deep.withAlphaComponent(0.35).cgColor,
                    deep.withAlphaComponent(0.90).cgColor,
                    deep.withAlphaComponent(0.97).cgColor
                ] as CFArray,
                locations: [0, 0.38, 0.58, 1]
            )!
            cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: linkCardSize.width, y: 0), options: [])

            let contentLeft: CGFloat = 610
            let right: CGFloat = linkCardSize.width - 60
            if let wordmark = UIImage(named: "WordmarkPrimary") {
                let ratio = wordmark.size.width / max(wordmark.size.height, 1)
                wordmark.draw(in: CGRect(x: contentLeft, y: 44, width: 160, height: 160 / ratio))
            } else {
                draw("lagcheck", at: CGPoint(x: contentLeft, y: 44), size: 30, weight: .heavy, color: text)
            }
            draw("lagcheck.signallq.com", in: CGRect(x: contentLeft, y: 68, width: right - contentLeft, height: 26), size: 20, weight: .medium, color: muted, alignment: .right)

            let headline = headlineSentence(for: verdict)
            let titleWidth = right - contentLeft
            let titleFont = UIFont.systemFont(ofSize: 60, weight: .bold)
            let titleStyle = NSMutableParagraphStyle()
            titleStyle.lineBreakMode = .byWordWrapping
            let titleHeight = ceil((headline as NSString).boundingRect(
                with: CGSize(width: titleWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: titleFont, .kern: -2, .paragraphStyle: titleStyle],
                context: nil
            ).height)
            // Mesmo bloco vertical do renderer Android: eyebrow, headline e
            // três métricas ocupam o centro da coluna direita.
            let blockHeight: CGFloat = 19 + 12 + titleHeight + 28 + 90
            let blockTop: CGFloat = 104 + (458 - 104 - blockHeight) / 2
            draw("CHECK · \(gameName)".uppercased(), at: CGPoint(x: contentLeft, y: blockTop), size: 19, weight: .semibold, color: accent, monospaced: true)
            draw(headline, in: CGRect(x: contentLeft, y: blockTop + 31, width: titleWidth, height: titleHeight + 12), size: 60, weight: .bold, color: text, lineBreak: .byWordWrapping)

            let metrics: [(String, String, String)] = [
                (AppLocalization.string("share.card.metric.response", comment: "").uppercased(), formatted(pingMs, decimals: 0), "ms"),
                (AppLocalization.string("share.card.metric.jitter", comment: "").uppercased(), formatted(jitterMs, decimals: 1), "ms"),
                (AppLocalization.string("share.card.metric.loss", comment: "").uppercased(), formatted(packetLossPercentage, decimals: 1), "%")
            ]
            let metricWidth: CGFloat = (right - contentLeft - 40) / 3
            for (index, metric) in metrics.enumerated() {
                let x = contentLeft + CGFloat(index) * (metricWidth + 20)
                let metricY = blockTop + 31 + titleHeight + 28
                let rect = CGRect(x: x, y: metricY, width: metricWidth, height: 88)
                cg.setFillColor(UIColor.white.withAlphaComponent(0.28).cgColor)
                cg.fill(rect)
                draw(metric.0, at: CGPoint(x: x + 20, y: metricY + 17), size: 17, weight: .semibold, color: accent, monospaced: true)
                draw(metric.1, at: CGPoint(x: x + 20, y: metricY + 39), size: 56, weight: .bold, color: text)
                if metric.1 != "—" { draw(metric.2, at: CGPoint(x: x + 20, y: metricY + 95), size: 22, weight: .medium, color: muted) }
            }

            let verdict = headline.uppercased()
            let pillFont = UIFont.monospacedSystemFont(ofSize: 20, weight: .semibold)
            let pillWidth = verdict.size(withAttributes: [.font: pillFont, .kern: 2.5]).width + 70
            let pill = UIBezierPath(roundedRect: CGRect(x: 56, y: 518, width: pillWidth, height: 56), cornerRadius: 28)
            cg.setFillColor(deep.withAlphaComponent(0.76).cgColor)
            pill.fill()
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.16).cgColor)
            cg.setLineWidth(1)
            pill.stroke()
            cg.setFillColor(tone.cgColor)
            cg.fillEllipse(in: CGRect(x: 74, y: 538, width: 16, height: 16))
            draw(verdict, at: CGPoint(x: 104, y: 534), size: 20, weight: .semibold, color: tone, monospaced: true)

            drawQRCode("https://lagcheck.signallq.com", in: CGRect(x: contentLeft, y: 458, width: 112, height: 112), context: cg)
            draw(AppLocalization.string("share.card.udp_proof", comment: ""), at: CGPoint(x: contentLeft + 134, y: 490), size: 23, weight: .medium, color: muted)
            draw(AppLocalization.string("share.card.cta", comment: ""), at: CGPoint(x: contentLeft + 134, y: 522), size: 23, weight: .semibold, color: text)
            if let wordmark = UIImage(named: "WordmarkPrimary") {
                let ratio = wordmark.size.width / max(wordmark.size.height, 1)
                wordmark.draw(in: CGRect(x: contentLeft + 130, y: 540, width: 118, height: 118 / ratio))
            }
        }
        let url = outputURL ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("lagcheck-share-\(UUID().uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.88) else { return nil }
        do { try data.write(to: url); return url } catch { return nil }
    }

    private static func artworkImage(gameID: String?, gameName: String) -> UIImage? {
        let asset = gameID.flatMap(GameArtworkAssetResolver.assetName(for:))
            ?? GameArtworkAssetResolver.assetName(for: gameName)
        return asset.flatMap { UIImage(named: $0) }
    }

    private static func drawAspectFill(_ image: UIImage, in rect: CGRect, context: CGContext) {
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawRect = CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height)
        context.saveGState(); context.clip(to: rect); image.draw(in: drawRect); context.restoreGState()
    }

    private static func drawQRCode(_ value: String, in rect: CGRect, context: CGContext) {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(value.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return }
        let scale = min(rect.width / output.extent.width, rect.height / output.extent.height)
        let image = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = CIContext(options: nil).createCGImage(image, from: image.extent) else { return }
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)
        context.interpolationQuality = .none
        context.draw(cgImage, in: rect)
    }

    private static func headlineSentence(for verdict: GameReadinessVerdict) -> String {
        switch verdict {
        case .ready: return AppLocalization.string("game_readiness.verdict.ready.headline", comment: "")
        case .caution: return AppLocalization.string("game_readiness.verdict.caution.headline", comment: "")
        case .notReady: return AppLocalization.string("game_readiness.verdict.not_ready.headline", comment: "")
        case .inconclusive: return AppLocalization.string("game_readiness.verdict.inconclusive.headline", comment: "")
        }
    }

    private static func verdictColor(_ verdict: GameReadinessVerdict) -> UIColor {
        switch verdict {
        case .ready: return UIColor(NLColor.semanticReady)
        case .caution: return UIColor(NLColor.semanticCaution)
        case .notReady: return UIColor(NLColor.coralSolar)
        case .inconclusive: return UIColor(NLColor.textTertiary)
        }
    }

    private static func formatted(_ value: Double?, decimals: Int) -> String {
        guard let value else { return "—" }
        let formatter = NumberFormatter()
        formatter.locale = AppLocalization.locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    private static func draw(_ text: String, at point: CGPoint, size: CGFloat, weight: UIFont.Weight, color: UIColor, monospaced: Bool = false) {
        let font = monospaced ? UIFont.monospacedSystemFont(ofSize: size, weight: weight) : UIFont.systemFont(ofSize: size, weight: weight)
        NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color]).draw(at: point)
    }

    private static func draw(_ text: String, in rect: CGRect, size: CGFloat, weight: UIFont.Weight, color: UIColor, alignment: NSTextAlignment = .left, monospaced: Bool = false, lineBreak: NSLineBreakMode = .byTruncatingTail) {
        let font = monospaced ? UIFont.monospacedSystemFont(ofSize: size, weight: weight) : UIFont.systemFont(ofSize: size, weight: weight)
        let style = NSMutableParagraphStyle(); style.alignment = alignment; style.lineBreakMode = lineBreak
        NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style]).draw(in: rect)
    }

    /* Legacy card renderer retained below only while existing call sites migrate. */
    private static func legacyDiscordShareCard(
        gameName: String,
        regionName: String,
        verdict: GameReadinessVerdict,
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        bufferbloatGradeText: String?,
        isWiFi: Bool,
        outputURL: URL? = nil
    ) -> URL? {
        let width = linkCardSize.width
        let height = linkCardSize.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let tempURL = outputURL ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("LagCheck_\(gameName.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString).jpg")

        let image = renderer.image { ctx in
            let cg = ctx.cgContext

            // 1. Fundo Dark Profundo (#0B0D10)
            cg.setFillColor(UIColor(NLColor.deep).cgColor)
            cg.fill(bounds)

            // 2. Painel Central com borda fina 1px
            let cardInset = CGRect(x: 40, y: 40, width: width - 80, height: height - 80)
            let cardPath = UIBezierPath(roundedRect: cardInset, cornerRadius: 24)
            cg.setFillColor(UIColor(NLColor.surface).cgColor)
            cardPath.fill()

            // Borda do card
            cg.setStrokeColor(UIColor(white: 1.0, alpha: 0.12).cgColor)
            cg.setLineWidth(1.5)
            cardPath.stroke()

            // 3. Header: Wordmark lagcheck + Selo Oficial
            let wordmarkAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            let wordmark = NSAttributedString(string: "lagcheck", attributes: wordmarkAttrs)
            wordmark.draw(at: CGPoint(x: 75, y: 75))

            // Tag "ATESTADO DE ROTA"
            let tagAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 15, weight: .bold),
                .foregroundColor: UIColor(NLColor.gamerPurple)
            ]
            let tag = NSAttributedString(string: AppLocalization.string("exporter.discord.official_tag", comment: ""), attributes: tagAttrs)
            tag.draw(at: CGPoint(x: 230, y: 85))

            // Subtítulo da conexão
            let connType = isWiFi
                ? AppLocalization.string("exporter.discord.wifi_iphone", comment: "")
                : AppLocalization.string("exporter.discord.cellular", comment: "")
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor(white: 0.6, alpha: 1.0)
            ]
            let connString = NSAttributedString(string: "\(gameName.uppercased()) · \(regionName.uppercased()) · \(connType)", attributes: subAttrs)
            connString.draw(at: CGPoint(x: 75, y: 125))

            // Linha divisória
            cg.setStrokeColor(UIColor(white: 1.0, alpha: 0.08).cgColor)
            cg.setLineWidth(1)
            cg.move(to: CGPoint(x: 75, y: 160))
            cg.addLine(to: CGPoint(x: width - 75, y: 160))
            cg.strokePath()

            // 4. Veredito Central Gigante
            let verdictText: String
            let verdictColor: UIColor
            let discordGamerQuote = gamerQuote(for: verdict)

            switch verdict {
            case .ready:
                verdictText = AppLocalization.string("game_readiness.verdict.ready.headline", comment: "")
                verdictColor = UIColor(NLColor.semanticReady)
            case .caution:
                verdictText = AppLocalization.string("game_readiness.verdict.caution.headline", comment: "")
                verdictColor = UIColor(NLColor.semanticCaution)
            case .notReady:
                verdictText = AppLocalization.string("game_readiness.verdict.not_ready.headline", comment: "")
                // Decisão Renan: #EF4444 não é token oficial; colapsado para coralSolar
                // (Decisão 66 reserva Coral Solar para atenção/erro — não cabe um segundo vermelho).
                verdictColor = UIColor(NLColor.coralSolar)
            case .inconclusive:
                verdictText = AppLocalization.string("game_readiness.verdict.inconclusive.headline", comment: "")
                verdictColor = UIColor.lightGray
            }

            // Desenhar Badge do Veredito
            let verdictAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 46, weight: .black),
                .foregroundColor: verdictColor
            ]
            switch verdict {
            case .ready:
                cg.setFillColor(verdictColor.cgColor)
                cg.fillEllipse(in: CGRect(x: 75, y: 205, width: 18, height: 18))
            case .caution:
                cg.setFillColor(verdictColor.cgColor)
                cg.move(to: CGPoint(x: 84, y: 201)); cg.addLine(to: CGPoint(x: 94, y: 221)); cg.addLine(to: CGPoint(x: 74, y: 221)); cg.closePath(); cg.fillPath()
            case .notReady:
                cg.setFillColor(verdictColor.cgColor)
                cg.fill(CGRect(x: 76, y: 204, width: 17, height: 17))
            case .inconclusive: break
            }
            let verdictString = NSAttributedString(string: verdictText, attributes: verdictAttrs)
            verdictString.draw(at: CGPoint(x: 106, y: 190))

            // Frase do Discord (A Regra do Discord)
            let quoteAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 22),
                .foregroundColor: UIColor(white: 0.85, alpha: 1.0)
            ]
            let quoteString = NSAttributedString(string: discordGamerQuote, attributes: quoteAttrs)
            quoteString.draw(at: CGPoint(x: 75, y: 255))

            // 5. Bloco de Telemetria com 3 Colunas (Números de Velocímetro)
            let teleY: CGFloat = 330
            let colWidth: CGFloat = (width - 150) / 4

            let pingStr = pingMs.map { "\(Int(round($0))) ms" } ?? "—"
            let jitterStr = jitterMs.map { "\(String(format: "%.1f", $0)) ms" } ?? "—"
            let lossStr = packetLossPercentage.map { "\(String(format: "%.1f", $0))%" } ?? "—"

            let bbStr = bufferbloatGradeText ?? "—"
            let bbColor: UIColor
            if bbStr.starts(with: "A") || bbStr == "B" {
                bbColor = verdictColor
            } else if bbStr == "C" {
                bbColor = UIColor(NLColor.semanticCaution)
            } else {
                bbColor = UIColor(NLColor.coralSolar)
            }

            let metrics = [
                (AppLocalization.string("exporter.discord.ping_label", comment: ""), pingStr, (pingMs ?? 999) <= 40 ? verdictColor : UIColor.white),
                (AppLocalization.string("exporter.discord.jitter_label", comment: ""), jitterStr, (jitterMs ?? 999) <= 4.0 ? verdictColor : UIColor(NLColor.semanticCaution)),
                (AppLocalization.string("exporter.discord.loss_label", comment: ""), lossStr, (packetLossPercentage ?? 999) == 0 ? verdictColor : UIColor(NLColor.coralSolar)),
                (AppLocalization.string("exporter.discord.bufferbloat_label", comment: ""), bbStr, bbColor)
            ]

            for (index, item) in metrics.enumerated() {
                let colX = 75 + (CGFloat(index) * colWidth)
                let rectCol = CGRect(x: colX, y: teleY, width: colWidth - 20, height: 165)

                // Fundo da coluna
                let colPath = UIBezierPath(roundedRect: rectCol, cornerRadius: 16)
                // Decisão Renan: #0E1014 era quase idêntico ao fundo (deep), não elevava a
                // superfície. Colapsado para o token de card/contêiner da Decisão 51.
                cg.setFillColor(UIColor(NLColor.surface).cgColor)
                colPath.fill()
                cg.setStrokeColor(UIColor(white: 1.0, alpha: 0.08).cgColor)
                cg.setLineWidth(1)
                colPath.stroke()

                // Label
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: UIColor(white: 0.5, alpha: 1.0)
                ]
                let labelStr = NSAttributedString(string: item.0, attributes: labelAttrs)
                labelStr.draw(at: CGPoint(x: colX + 20, y: teleY + 22))

                // Valor Grande Monoespaçado
                let valAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 52, weight: .heavy),
                    .foregroundColor: item.2
                ]
                let valStr = NSAttributedString(string: item.1, attributes: valAttrs)
                valStr.draw(at: CGPoint(x: colX + 20, y: teleY + 65))

                // Sub-legenda de honestidade
                let subLegAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                    .foregroundColor: UIColor(white: 0.45, alpha: 1.0)
                ]
                let subLegStr = NSAttributedString(string: AppLocalization.string("exporter.discord.real_udp_sampling", comment: ""), attributes: subLegAttrs)
                subLegStr.draw(at: CGPoint(x: colX + 20, y: teleY + 128))
            }

            // 6. Rodapé com Carimbo de Autenticidade
            let footY: CGFloat = height - 90
            let footAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor(white: 0.4, alpha: 1.0)
            ]
            let footText = NSAttributedString(string: AppLocalization.string("exporter.discord.footer", comment: ""), attributes: footAttrs)
            footText.draw(at: CGPoint(x: 75, y: footY))
        }

        // Salvar em disco para share sheet
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }

    /// Prepara apenas o card estático de link para um snapshot de Check já concluído.
    /// O cache é temporário e a chave inclui a medição, evitando reutilizar um reteste anterior.
    public static func prepareDiscordShareCard(
        snapshotKey: String,
        gameID: String? = nil,
        gameName: String,
        regionName: String,
        verdict: GameReadinessVerdict,
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        bufferbloatGradeText: String?,
        isWiFi: Bool
    ) -> URL? {
        guard verdict != .inconclusive else { return nil }

        preparationLock.lock()
        defer { preparationLock.unlock() }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lagcheck-share-\(stableIdentifier(snapshotKey)).jpg")
        if FileManager.default.fileExists(atPath: url.path) { return url }

        return generateDiscordShareCard(
            gameID: gameID,
            gameName: gameName,
            regionName: regionName,
            verdict: verdict,
            pingMs: pingMs,
            jitterMs: jitterMs,
            packetLossPercentage: packetLossPercentage,
            bufferbloatGradeText: bufferbloatGradeText,
            isWiFi: isWiFi,
            outputURL: url
        )
    }

    private static func stableIdentifier(_ value: String) -> String {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }

    public static func gamerQuote(for verdict: GameReadinessVerdict) -> String {
        switch verdict {
        case .ready:
            return AppLocalization.string("exporter.discord.quote.ready", comment: "")
        case .caution:
            return AppLocalization.string("exporter.discord.quote.caution", comment: "")
        case .notReady:
            return AppLocalization.string("exporter.discord.quote.not_ready", comment: "")
        case .inconclusive:
            return AppLocalization.string("exporter.discord.quote.inconclusive", comment: "")
        }
    }
}

