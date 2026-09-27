import SwiftUI
import UIKit
import NolaggyDomain
import NolaggyApplication

/// Gerador do Card Viral de Alta Fidelidade para Discord, WhatsApp e Redes Sociais.
/// Gera uma imagem PNG em 1200x675 (16:9, padrão de preview do Discord/Twitter)
/// com estética Dark Competitive UI, tipografia pesada e números de corrida.
public enum LagCheckDiscordCardExporter {

    public static func generateDiscordShareCard(
        gameName: String,
        regionName: String,
        verdict: GameReadinessVerdict,
        pingMs: Double?,
        jitterMs: Double?,
        packetLossPercentage: Double?,
        isWiFi: Bool
    ) -> URL? {
        let width: CGFloat = 1200
        let height: CGFloat = 675
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LagCheck_\(gameName.replacingOccurrences(of: " ", with: "_"))_\(Int(Date().timeIntervalSince1970)).png")

        let image = renderer.image { ctx in
            let cg = ctx.cgContext

            // 1. Fundo Dark Profundo (#0B0D10)
            cg.setFillColor(UIColor(red: 11/255, green: 13/255, blue: 16/255, alpha: 1.0).cgColor)
            cg.fill(bounds)

            // 2. Painel Central com borda fina 1px
            let cardInset = CGRect(x: 40, y: 40, width: width - 80, height: height - 80)
            let cardPath = UIBezierPath(roundedRect: cardInset, cornerRadius: 24)
            cg.setFillColor(UIColor(red: 21/255, green: 24/255, blue: 30/255, alpha: 1.0).cgColor)
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
                .foregroundColor: UIColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1.0)
            ]
            let tag = NSAttributedString(string: "● ATESTADO OFICIAL DE ROTA", attributes: tagAttrs)
            tag.draw(at: CGPoint(x: 230, y: 85))

            // Subtítulo da conexão
            let connType = isWiFi ? "WI-FI OBSERVADO NO IPHONE" : "REDE CELULAR OBSERVADA"
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
            let discordGamerQuote: String

            switch verdict {
            case .ready:
                verdictText = "● PRONTO PARA RANKED"
                verdictColor = UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1.0)
                discordGamerQuote = "“Rota 100% lisa. Se perder no ranked hoje a culpa é sua.”"
            case .caution:
                verdictText = "▲ INSTÁVEL: PODE TER DELAY"
                verdictColor = UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1.0)
                discordGamerQuote = "“Oscilação detectada. Joga por sua conta e risco, vai ter micro-teleporte.”"
            case .notReady:
                verdictText = "■ EVITE JOGAR RANKED AGORA"
                verdictColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
                discordGamerQuote = "“Nem me chama pra jogar hoje. A rota da operadora tá um lixo completo.”"
            case .inconclusive:
                verdictText = "— RESULTADO INCONCLUSIVO"
                verdictColor = UIColor.lightGray
                discordGamerQuote = "“Amostras insuficientes na rota de rede. Verifique seu sinal.”"
            }

            // Desenhar Badge do Veredito
            let verdictAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 46, weight: .black),
                .foregroundColor: verdictColor
            ]
            let verdictString = NSAttributedString(string: verdictText, attributes: verdictAttrs)
            verdictString.draw(at: CGPoint(x: 75, y: 190))

            // Frase do Discord (A Regra do Discord)
            let quoteAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 22),
                .foregroundColor: UIColor(white: 0.85, alpha: 1.0)
            ]
            let quoteString = NSAttributedString(string: discordGamerQuote, attributes: quoteAttrs)
            quoteString.draw(at: CGPoint(x: 75, y: 255))

            // 5. Bloco de Telemetria com 3 Colunas (Números de Velocímetro)
            let teleY: CGFloat = 330
            let colWidth: CGFloat = (width - 150) / 3

            let pingStr = pingMs.map { "\(Int(round($0))) ms" } ?? "—"
            let jitterStr = jitterMs.map { "\(String(format: "%.1f", $0)) ms" } ?? "—"
            let lossStr = packetLossPercentage.map { "\(String(format: "%.1f", $0))%" } ?? "—"

            let metrics = [
                ("LATÊNCIA (PING)", pingStr, (pingMs ?? 999) <= 40 ? verdictColor : UIColor.white),
                ("OSCILAÇÃO (JITTER)", jitterStr, (jitterMs ?? 999) <= 4.0 ? verdictColor : UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1.0)),
                ("PERDA DE PACOTES", lossStr, (packetLossPercentage ?? 999) == 0 ? verdictColor : UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0))
            ]

            for (index, item) in metrics.enumerated() {
                let colX = 75 + (CGFloat(index) * colWidth)
                let rectCol = CGRect(x: colX, y: teleY, width: colWidth - 20, height: 165)

                // Fundo da coluna
                let colPath = UIBezierPath(roundedRect: rectCol, cornerRadius: 16)
                cg.setFillColor(UIColor(red: 14/255, green: 16/255, blue: 20/255, alpha: 1.0).cgColor)
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
                let subLegStr = NSAttributedString(string: "Amostragem real UDP", attributes: subLegAttrs)
                subLegStr.draw(at: CGPoint(x: colX + 20, y: teleY + 128))
            }

            // 6. Rodapé com Carimbo de Autenticidade
            let footY: CGFloat = height - 90
            let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            let footAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor(white: 0.4, alpha: 1.0)
            ]
            let footText = NSAttributedString(string: "TESTADO EM: \(dateStr.uppercased()) · DADOS BRUTOS SEM ESTIMATIVA · LAGCHECK.APP", attributes: footAttrs)
            footText.draw(at: CGPoint(x: 75, y: footY))
        }

        // Salvar em disco para share sheet
        guard let data = image.pngData() else { return nil }
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
}
