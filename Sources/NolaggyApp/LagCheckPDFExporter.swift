import SwiftUI
import UIKit
import NolaggyDomain
import NolaggyApplication

/// Gerador de relatórios em PDF oficiais do LagCheck.
/// Produz layouts vetoriais com a identidade Dark Competitive UI da marca.
public enum LagCheckPDFExporter {

    // MARK: - PDF 1: Relatório Técnico de Rede (Cockpit)
    public static func generateNetworkReportPDF(
        interfaceName: String,
        isWiFi: Bool,
        wifiBand: String,
        localIP: String?,
        gatewayIP: String?,
        gatewayRTTMs: Double?,
        natTypeDisplay: String,
        cgnatDisplay: String,
        doubleNATDisplay: String,
        publicIPDisplay: String,
        useCases: [(title: String, icon: String, status: String, color: UIColor, note: String)]
    ) -> URL? {
        let pageWidth: CGFloat = 595.2 // A4
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LagCheck_Diagnostico_Rede_\(Int(Date().timeIntervalSince1970)).pdf")

        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()
                let ctx = context.cgContext

                // Fundo Escuro Profundo (#0B0D10)
                ctx.setFillColor(UIColor(red: 11/255, green: 13/255, blue: 16/255, alpha: 1.0).cgColor)
                ctx.fill(pageRect)

                var currentY: CGFloat = 40

                // 1. Cabeçalho LagCheck
                drawHeader(ctx: ctx, title: "RELATÓRIO TÉCNICO DE REDE", subtitle: "AUDITORIA DE PRIMEIRO SALTO, WAN & CASOS DE USO", currentY: &currentY, pageWidth: pageWidth)

                // 2. Card: Primeiro Salto Local & Interface
                let rttText = gatewayRTTMs.map { "\(Int(round($0))) ms" } ?? "—"
                let localRows: [(String, String, UIColor)] = [
                    ("Interface Conectada", interfaceName, .white),
                    ("Frequência Wi-Fi", isWiFi ? wifiBand : "Não aplicável", isWiFi ? (wifiBand.contains("5") ? UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1) : UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1)) : .lightGray),
                    ("Endereço IP Local", localIP ?? "—", .white),
                    ("Gateway Padrão (Roteador)", gatewayIP ?? "—", .white),
                    ("Latência do Primeiro Salto (RTT)", rttText, (gatewayRTTMs ?? 99) <= 5.0 ? UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1) : UIColor(red: 255/255, green: 90/255, blue: 54/255, alpha: 1))
                ]
                drawCard(ctx: ctx, title: "1. CONEXÃO LOCAL & PRIMEIRO SALTO (RF / LAN)", rows: localRows, currentY: &currentY, pageWidth: pageWidth)

                // 3. Card: Borda WAN, NAT & CGNAT
                let wanRows: [(String, String, UIColor)] = [
                    ("Tipo de NAT", natTypeDisplay, natTypeDisplay.contains("Tipo 1") ? UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1) : UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1)),
                    ("Status CGNAT (RFC 6598)", cgnatDisplay, cgnatDisplay.contains("Livre") ? UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1) : UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)),
                    ("Duplo NAT (Roteadores em Cascata)", doubleNATDisplay, doubleNATDisplay.contains("Não") ? UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1) : UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)),
                    ("IP Público Identificado", publicIPDisplay, .lightGray)
                ]
                drawCard(ctx: ctx, title: "2. BORDA WAN & TOPOLOGIA DE REDE (RFC 5389)", rows: wanRows, currentY: &currentY, pageWidth: pageWidth)

                // 4. Card: Prontidão para Casos de Uso
                drawUseCasesCard(ctx: ctx, useCases: useCases, currentY: &currentY, pageWidth: pageWidth)

                // 5. Rodapé Oficial
                drawFooter(ctx: ctx, pageRect: pageRect)
            }
            return tempURL
        } catch {
            return nil
        }
    }

    // MARK: - PDF 2: Relatório do Veredito da Medição (Resultado)
    public static func generateMeasurementResultPDF(
        gameName: String,
        platformName: String,
        regionName: String,
        verdictHeadline: String,
        verdictColor: UIColor,
        verdictSubtitle: String,
        scoreText: String,
        pingMs: Double?,
        jitterMs: Double?,
        lossPercentage: Double?,
        bufferbloatGrade: String,
        topOptimization: String,
        optimizationSeverity: String
    ) -> URL? {
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LagCheck_Veredito_\(gameName)_\(Int(Date().timeIntervalSince1970)).pdf")

        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()
                let ctx = context.cgContext

                // Fundo Escuro Profundo (#0B0D10)
                ctx.setFillColor(UIColor(red: 11/255, green: 13/255, blue: 16/255, alpha: 1.0).cgColor)
                ctx.fill(pageRect)

                var currentY: CGFloat = 40

                // 1. Cabeçalho LagCheck
                drawHeader(ctx: ctx, title: "ATESTADO DE PRONTIDÃO PARA JOGOS", subtitle: "\(gameName.uppercased()) · \(platformName.uppercased()) · \(regionName.uppercased())", currentY: &currentY, pageWidth: pageWidth)

                // 2. Card Heroico de Veredito
                drawVerdictCard(ctx: ctx, headline: verdictHeadline, subtitle: verdictSubtitle, color: verdictColor, scoreText: scoreText, currentY: &currentY, pageWidth: pageWidth)

                // 3. Grid de Telemetria de Alta Precisão (Ping, Jitter, Perda, Bufferbloat)
                drawMetricsGrid(ctx: ctx, ping: pingMs, jitter: jitterMs, loss: lossPercentage, bufferbloat: bufferbloatGrade, currentY: &currentY, pageWidth: pageWidth)

                // 4. Oportunidade de Otimização de Maior Impacto
                drawOptimizationCard(ctx: ctx, tip: topOptimization, tag: optimizationSeverity, currentY: &currentY, pageWidth: pageWidth)

                // 5. Rodapé Oficial
                drawFooter(ctx: ctx, pageRect: pageRect)
            }
            return tempURL
        } catch {
            return nil
        }
    }

    // MARK: - Métodos Auxiliares de Desenho Vetorial

    private static func drawHeader(ctx: CGContext, title: String, subtitle: String, currentY: inout CGFloat, pageWidth: CGFloat) {
        // Marca LagCheck: "lag" em branco, "check" em Roxo Gamer (#7C3AED)
        let lagAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .black),
            .foregroundColor: UIColor.white
        ]
        let checkAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .black),
            .foregroundColor: UIColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1.0)
        ]
        let brandStr = NSMutableAttributedString(string: "lag", attributes: lagAttrs)
        brandStr.append(NSAttributedString(string: "check", attributes: checkAttrs))
        brandStr.draw(at: CGPoint(x: 40, y: currentY))

        // Badge Diagnostic Suite à direita
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .bold),
            .foregroundColor: UIColor(white: 0.7, alpha: 1.0)
        ]
        let dateStr = Date().formatted(date: .abbreviated, time: .shortened)
        let badgeStr = NSAttributedString(string: "DIAGNOSTIC SUITE · \(dateStr)", attributes: badgeAttrs)
        let badgeSize = badgeStr.size()
        badgeStr.draw(at: CGPoint(x: pageWidth - 40 - badgeSize.width, y: currentY + 6))

        currentY += 36

        // Título e Subtítulo
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        NSAttributedString(string: title, attributes: titleAttrs).draw(at: CGPoint(x: 40, y: currentY))
        currentY += 22

        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor(white: 0.6, alpha: 1.0)
        ]
        NSAttributedString(string: subtitle, attributes: subAttrs).draw(at: CGPoint(x: 40, y: currentY))
        currentY += 24

        // Linha divisória fina
        ctx.setStrokeColor(UIColor(white: 0.2, alpha: 1.0).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: 40, y: currentY))
        ctx.addLine(to: CGPoint(x: pageWidth - 40, y: currentY))
        ctx.strokePath()

        currentY += 20
    }

    private static func drawCard(ctx: CGContext, title: String, rows: [(String, String, UIColor)], currentY: inout CGFloat, pageWidth: CGFloat) {
        let cardWidth = pageWidth - 80
        let cardHeight: CGFloat = 36 + CGFloat(rows.count * 28)
        let cardRect = CGRect(x: 40, y: currentY, width: cardWidth, height: cardHeight)

        // Fundo do Card (#15181E)
        ctx.setFillColor(UIColor(red: 21/255, green: 24/255, blue: 30/255, alpha: 1.0).cgColor)
        let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 13)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        // Borda Fina
        ctx.setStrokeColor(UIColor(white: 1.0, alpha: 0.08).cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        // Título do Card
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1.0)
        ]
        NSAttributedString(string: title, attributes: titleAttrs).draw(at: CGPoint(x: 54, y: currentY + 14))

        var rowY = currentY + 36
        for (label, value, color) in rows {
            // Label
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor(white: 0.65, alpha: 1.0)
            ]
            NSAttributedString(string: label, attributes: labelAttrs).draw(at: CGPoint(x: 54, y: rowY))

            // Value
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: color
            ]
            let valStr = NSAttributedString(string: value, attributes: valueAttrs)
            let valSize = valStr.size()
            valStr.draw(at: CGPoint(x: pageWidth - 54 - valSize.width, y: rowY))

            rowY += 26
        }

        currentY += cardHeight + 16
    }

    private static func drawUseCasesCard(
        ctx: CGContext,
        useCases: [(title: String, icon: String, status: String, color: UIColor, note: String)],
        currentY: inout CGFloat,
        pageWidth: CGFloat
    ) {
        let cardWidth = pageWidth - 80
        let cardHeight: CGFloat = 36 + CGFloat(useCases.count * 42)
        let cardRect = CGRect(x: 40, y: currentY, width: cardWidth, height: cardHeight)

        ctx.setFillColor(UIColor(red: 21/255, green: 24/255, blue: 30/255, alpha: 1.0).cgColor)
        let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 13)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        ctx.setStrokeColor(UIColor(white: 1.0, alpha: 0.08).cgColor)
        ctx.strokePath()

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1.0)
        ]
        NSAttributedString(string: "3. PRONTIDÃO PARA PERFIS DE USO GAMER", attributes: titleAttrs).draw(at: CGPoint(x: 54, y: currentY + 14))

        var rowY = currentY + 36
        for item in useCases {
            let itemTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            NSAttributedString(string: item.title, attributes: itemTitleAttrs).draw(at: CGPoint(x: 54, y: rowY))

            let statusAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: item.color
            ]
            let stStr = NSAttributedString(string: item.status, attributes: statusAttrs)
            stStr.draw(at: CGPoint(x: pageWidth - 54 - stStr.size().width, y: rowY))

            let noteAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9.5, weight: .regular),
                .foregroundColor: UIColor(white: 0.5, alpha: 1.0)
            ]
            NSAttributedString(string: item.note, attributes: noteAttrs).draw(at: CGPoint(x: 54, y: rowY + 16))

            rowY += 40
        }

        currentY += cardHeight + 16
    }

    private static func drawVerdictCard(
        ctx: CGContext,
        headline: String,
        subtitle: String,
        color: UIColor,
        scoreText: String,
        currentY: inout CGFloat,
        pageWidth: CGFloat
    ) {
        let cardWidth = pageWidth - 80
        let cardHeight: CGFloat = 110
        let cardRect = CGRect(x: 40, y: currentY, width: cardWidth, height: cardHeight)

        ctx.setFillColor(UIColor(red: 21/255, green: 24/255, blue: 30/255, alpha: 1.0).cgColor)
        let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 13)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        // Borda com leve tom da cor do veredito
        ctx.setStrokeColor(color.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(1.5)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        // Veredito Headline
        let headAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .black),
            .foregroundColor: color
        ]
        NSAttributedString(string: headline, attributes: headAttrs).draw(at: CGPoint(x: 56, y: currentY + 22))

        // Subtítulo
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor(white: 0.7, alpha: 1.0)
        ]
        NSAttributedString(string: subtitle, attributes: subAttrs).draw(at: CGPoint(x: 56, y: currentY + 54))

        // Score Box à direita
        let scoreLabelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: UIColor(white: 0.5, alpha: 1.0)
        ]
        let sl = NSAttributedString(string: "SCORE", attributes: scoreLabelAttrs)
        sl.draw(at: CGPoint(x: pageWidth - 56 - 60, y: currentY + 24))

        let scoreNumAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 28, weight: .black),
            .foregroundColor: UIColor.white
        ]
        let sn = NSAttributedString(string: scoreText, attributes: scoreNumAttrs)
        sn.draw(at: CGPoint(x: pageWidth - 56 - 60, y: currentY + 38))

        currentY += cardHeight + 16
    }

    private static func drawMetricsGrid(
        ctx: CGContext,
        ping: Double?,
        jitter: Double?,
        loss: Double?,
        bufferbloat: String,
        currentY: inout CGFloat,
        pageWidth: CGFloat
    ) {
        let cardWidth = pageWidth - 80
        let cardHeight: CGFloat = 80
        let cardRect = CGRect(x: 40, y: currentY, width: cardWidth, height: cardHeight)

        ctx.setFillColor(UIColor(red: 21/255, green: 24/255, blue: 30/255, alpha: 1.0).cgColor)
        let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 13)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        ctx.setStrokeColor(UIColor(white: 1.0, alpha: 0.08).cgColor)
        ctx.strokePath()

        let cols = [
            ("PING", ping.map { "\(Int($0.rounded())) ms" } ?? "—"),
            ("JITTER", jitter.map { "\(Int($0.rounded())) ms" } ?? "—"),
            ("PERDA", loss.map { String(format: "%.1f%%", $0) } ?? "0.0%"),
            ("CARGA", bufferbloat)
        ]

        let colWidth = cardWidth / CGFloat(cols.count)
        for (i, (label, val)) in cols.enumerated() {
            let x = 40 + CGFloat(i) * colWidth

            let lAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: UIColor(white: 0.5, alpha: 1.0)
            ]
            NSAttributedString(string: label, attributes: lAttrs).draw(at: CGPoint(x: x + 18, y: currentY + 16))

            let vAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 18, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            NSAttributedString(string: val, attributes: vAttrs).draw(at: CGPoint(x: x + 18, y: currentY + 34))

            if i < cols.count - 1 {
                ctx.setStrokeColor(UIColor(white: 1.0, alpha: 0.08).cgColor)
                ctx.move(to: CGPoint(x: x + colWidth, y: currentY + 18))
                ctx.addLine(to: CGPoint(x: x + colWidth, y: currentY + cardHeight - 18))
                ctx.strokePath()
            }
        }

        currentY += cardHeight + 16
    }

    private static func drawOptimizationCard(
        ctx: CGContext,
        tip: String,
        tag: String,
        currentY: inout CGFloat,
        pageWidth: CGFloat
    ) {
        let cardWidth = pageWidth - 80
        let cardHeight: CGFloat = 95
        let cardRect = CGRect(x: 40, y: currentY, width: cardWidth, height: cardHeight)

        ctx.setFillColor(UIColor(red: 21/255, green: 24/255, blue: 30/255, alpha: 1.0).cgColor)
        let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 13)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        ctx.setStrokeColor(UIColor(red: 255/255, green: 90/255, blue: 54/255, alpha: 0.25).cgColor)
        ctx.strokePath()

        // Tag de Maior Impacto
        let tagAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .black),
            .foregroundColor: UIColor(red: 255/255, green: 90/255, blue: 54/255, alpha: 1)
        ]
        NSAttributedString(string: "OPORTUNIDADE DE MAIOR IMPACTO (\(tag.uppercased()))", attributes: tagAttrs).draw(at: CGPoint(x: 56, y: currentY + 16))

        // Texto da recomendação
        let tipAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor(white: 0.9, alpha: 1.0)
        ]
        let tipRect = CGRect(x: 56, y: currentY + 36, width: cardWidth - 32, height: 48)
        tip.draw(in: tipRect, withAttributes: tipAttrs)

        currentY += cardHeight + 16
    }

    private static func drawFooter(ctx: CGContext, pageRect: CGRect) {
        let footerY = pageRect.height - 45
        ctx.setStrokeColor(UIColor(white: 0.15, alpha: 1.0).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: 40, y: footerY))
        ctx.addLine(to: CGPoint(x: pageRect.width - 40, y: footerY))
        ctx.strokePath()

        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .regular),
            .foregroundColor: UIColor(white: 0.45, alpha: 1.0)
        ]
        let footerText = "LagCheck · Auditoria de Rede e Medição de Rota para Jogadores Competitivos · Relatório auditável RFC 5389 & Probing Local"
        NSAttributedString(string: footerText, attributes: footerAttrs).draw(at: CGPoint(x: 40, y: footerY + 12))
    }
}

/// Compartilhamento padrão nativo do iOS para abrir o PDF gerado.
public struct ShareSheet: UIViewControllerRepresentable {
    public let items: [Any]

    public init(items: [Any]) {
        self.items = items
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
