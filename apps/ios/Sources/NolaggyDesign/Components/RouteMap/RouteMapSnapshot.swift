import UIKit

/// Renderiza o mapa mundi pontilhado oficial (`RouteMapGridData`) como `UIImage` estática
/// para cards e vídeos de compartilhamento quando não houver jogo selecionado.
public enum RouteMapSnapshot {
    public static func render(size: CGSize = CGSize(width: 1200, height: 900)) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { ctx in
            let c = ctx.cgContext
            let w = size.width
            let h = size.height

            // Fundo base Dark Competitive UI (#0B0D10)
            c.setFillColor(UIColor(red: 11 / 255, green: 13 / 255, blue: 16 / 255, alpha: 1).cgColor)
            c.fill(CGRect(origin: .zero, size: size))

            // Brilho sutil Roxo Gamer no centro do mapa
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let glowColors = [
                UIColor(red: 124 / 255, green: 58 / 255, blue: 237 / 255, alpha: 0.16).cgColor,
                UIColor(red: 11 / 255, green: 13 / 255, blue: 16 / 255, alpha: 0).cgColor
            ] as CFArray
            if let grad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1]) {
                let center = CGPoint(x: w * 0.45, y: h * 0.48)
                c.drawRadialGradient(grad, startCenter: center, startRadius: 0, endCenter: center, endRadius: w * 0.55, options: [])
            }

            // Grade técnica sutil
            c.setStrokeColor(UIColor(red: 138 / 255, green: 147 / 255, blue: 160 / 255, alpha: 0.09).cgColor)
            c.setLineWidth(1)
            let stepGrid = w / 12
            var gx = stepGrid
            while gx < w {
                c.move(to: CGPoint(x: gx, y: 0))
                c.addLine(to: CGPoint(x: gx, y: h))
                gx += stepGrid
            }
            var gy = stepGrid
            while gy < h {
                c.move(to: CGPoint(x: 0, y: gy))
                c.addLine(to: CGPoint(x: w, y: gy))
                gy += stepGrid
            }
            c.strokePath()

            // Pontos de terra do RouteMapGridData
            let rows = RouteMapGridData.rows
            guard !rows.isEmpty else { return }
            let rowCount = rows.count
            let colCount = rows[0].count

            let padX = w * 0.04
            let mapW = w - padX * 2
            let cellW = mapW / CGFloat(colCount)
            let mapH = cellW * CGFloat(rowCount)
            let padY = (h - mapH) * 0.46
            let dotRadius = max(1.4, cellW * 0.36)

            c.setFillColor(UIColor(red: 58 / 255, green: 68 / 255, blue: 84 / 255, alpha: 1).cgColor)
            for (r, row) in rows.enumerated() {
                let cy = padY + (CGFloat(r) + 0.5) * cellW
                var col = 0
                for ch in row {
                    if ch == "1" {
                        let cx = padX + (CGFloat(col) + 0.5) * cellW
                        c.fillEllipse(in: CGRect(x: cx - dotRadius, y: cy - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
                    }
                    col += 1
                }
            }
        }
    }
}
