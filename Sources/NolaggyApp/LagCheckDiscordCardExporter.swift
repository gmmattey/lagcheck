import SwiftUI
import UIKit
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

