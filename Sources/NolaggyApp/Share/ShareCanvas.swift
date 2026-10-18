import UIKit
import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import NolaggyDesign

/// Utilitários de desenho em CGContext compartilhados pelos cards e pelo vídeo.
/// Paridade 1:1 estrita com ShareCanvas.kt do Android (Decisões 81 e 103).
public enum ShareCanvas {

    // Paleta oficial da Dark Competitive UI: tokens do app, sem cores soltas (Decisão 66).
    public static let deep = UIColor(red: 11 / 255, green: 13 / 255, blue: 16 / 255, alpha: 1) // #0B0D10
    public static let text = UIColor(red: 244 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1) // #F4F5F7
    public static let muted = UIColor(red: 138 / 255, green: 147 / 255, blue: 160 / 255, alpha: 1) // #8A93A0
    public static let accent = UIColor(red: 167 / 255, green: 139 / 255, blue: 250 / 255, alpha: 1) // #A78BFA (gamerPurpleLight)
    public static let purple = UIColor(red: 124 / 255, green: 58 / 255, blue: 237 / 255, alpha: 1) // #7C3AED (gamerPurple)
    public static let ready = UIColor(red: 34 / 255, green: 197 / 255, blue: 94 / 255, alpha: 1) // #22C55E
    public static let caution = UIColor(red: 245 / 255, green: 158 / 255, blue: 11 / 255, alpha: 1) // #F59E0B
    public static let notReady = UIColor(red: 255 / 255, green: 90 / 255, blue: 54 / 255, alpha: 1) // #FF5A36 (coralSolar)

    public static func toneColor(_ tone: ShareTone) -> UIColor {
        switch tone {
        case .ready: return ready
        case .caution: return caution
        case .notReady: return notReady
        }
    }

    public static func withAlpha(_ color: UIColor, _ alpha: CGFloat) -> UIColor {
        color.withAlphaComponent(max(0, min(1, alpha)))
    }

    public static func fillRect(c: CGContext, l: CGFloat, t: CGFloat, r: CGFloat, b: CGFloat, color: UIColor) {
        c.saveGState()
        c.setFillColor(color.cgColor)
        c.fill(CGRect(x: l, y: t, width: r - l, height: b - t))
        c.restoreGState()
    }

    public static func roundRect(
        c: CGContext,
        rect: CGRect,
        radius: CGFloat,
        color: UIColor,
        stroke: Bool = false,
        strokeWidth: CGFloat = 1
    ) {
        c.saveGState()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        if stroke {
            c.setStrokeColor(color.cgColor)
            c.setLineWidth(strokeWidth)
            c.addPath(path.cgPath)
            c.strokePath()
        } else {
            c.setFillColor(color.cgColor)
            c.addPath(path.cgPath)
            c.fillPath()
        }
        c.restoreGState()
    }

    public static func circle(c: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, color: UIColor, glow: CGFloat = 0) {
        c.saveGState()
        if glow > 0 {
            c.setShadow(offset: .zero, blur: glow, color: color.cgColor)
        }
        c.setFillColor(color.cgColor)
        c.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        c.restoreGState()
    }

    /// Preenche `rect` com a imagem recortada ao centro (aspect fill); sem imagem, fundo #1A0B2E.
    public static func drawFill(c: CGContext, image: UIImage?, rect: CGRect, radius: CGFloat = 0) {
        c.saveGState()
        if radius > 0 {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
            c.addPath(path.cgPath)
            c.clip()
        } else {
            c.clip(to: rect)
        }

        if let image, image.size.width > 0, image.size.height > 0 {
            let scale = max(rect.width / image.size.width, rect.height / image.size.height)
            let w = image.size.width * scale
            let h = image.size.height * scale
            let drawRect = CGRect(
                x: rect.midX - w / 2,
                y: rect.midY - h / 2,
                width: w,
                height: h
            )
            image.draw(in: drawRect)
        } else {
            c.setFillColor(UIColor(red: 26 / 255, green: 11 / 255, blue: 46 / 255, alpha: 1).cgColor)
            c.fill(rect)
        }
        c.restoreGState()
    }

    public static func gradient(
        c: CGContext,
        stops: [(CGFloat, UIColor)],
        start: CGPoint,
        end: CGPoint,
        rect: CGRect,
        alpha: CGFloat = 1
    ) {
        c.saveGState()
        c.clip(to: rect)
        let colors = stops.map { withAlpha($0.1, $0.1.cgColor.alpha * alpha).cgColor } as CFArray
        let locations = stops.map { $0.0 }
        let space = CGColorSpaceCreateDeviceRGB()
        if let grad = CGGradient(colorsSpace: space, colors: colors, locations: locations) {
            c.drawLinearGradient(grad, start: start, end: end, options: [])
        }
        c.restoreGState()
    }

    public static func drawImage(
        c: CGContext,
        image: UIImage?,
        height: CGFloat,
        x: CGFloat,
        y: CGFloat,
        alpha: CGFloat = 1
    ) {
        guard let image, image.size.height > 0 else { return }
        let w = height * (image.size.width / image.size.height)
        c.saveGState()
        c.setAlpha(max(0, min(1, alpha)))
        image.draw(in: CGRect(x: x, y: y, width: w, height: height))
        c.restoreGState()
    }

    public static func font(size: CGFloat, weight: UIFont.Weight, mono: Bool) -> UIFont {
        if mono {
            return UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        } else {
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
    }

    public static func draw(
        c: CGContext,
        text: String,
        x: CGFloat,
        y: CGFloat,
        size: CGFloat,
        weight: UIFont.Weight,
        color: UIColor,
        kern: CGFloat = 0,
        align: NSTextAlignment = .left,
        shadow: Bool = false,
        alpha: CGFloat = 1,
        mono: Bool = false
    ) {
        let f = font(size: size, weight: weight, mono: mono)
        let cColor = withAlpha(color, alpha)
        var attrs: [NSAttributedString.Key: Any] = [
            .font: f,
            .foregroundColor: cColor
        ]
        if kern != 0 {
            attrs[.kern] = kern
        }
        if shadow {
            let s = NSShadow()
            s.shadowBlurRadius = 12
            s.shadowOffset = CGSize(width: 0, height: 2)
            s.shadowColor = UIColor.black.withAlphaComponent(0.55 * max(0, min(1, alpha)))
            attrs[.shadow] = s
        }

        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let measured = attrStr.size()

        let originX: CGFloat
        switch align {
        case .left, .natural, .justified:
            originX = x
        case .center:
            originX = x - measured.width / 2
        case .right:
            originX = x - measured.width
        @unknown default:
            originX = x
        }

        // y passado no renderer é a linha de base (baseline);
        // para UIFont, baseline = y - font.ascender
        let drawY = y - f.ascender
        attrStr.draw(at: CGPoint(x: originX, y: drawY))
    }

    public static func width(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight,
        kern: CGFloat = 0,
        mono: Bool = false
    ) -> CGFloat {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font(size: size, weight: weight, mono: mono)
        ]
        if kern != 0 {
            attrs[.kern] = kern
        }
        return (text as NSString).size(withAttributes: attrs).width
    }

    /// Quebra em linhas de até `maxWidth`, sem cortar palavras.
    public static func wrap(
        _ text: String,
        size: CGFloat,
        weight: UIFont.Weight,
        kern: CGFloat,
        maxWidth: CGFloat
    ) -> [String] {
        var lines: [String] = []
        var cur = ""
        let words = text.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        for word in words {
            let trial = cur.isEmpty ? word : "\(cur) \(word)"
            if !cur.isEmpty && width(trial, size: size, weight: weight, kern: kern) > maxWidth {
                lines.append(cur)
                cur = word
            } else {
                cur = trial
            }
        }
        if !cur.isEmpty {
            lines.append(cur)
        }
        return lines
    }

    private static let qrContext = CIContext(options: [.useSoftwareRenderer: false])

    /// QR Code de link da loja (App Store) com quadro branco arredondado em volta.
    /// Renderizado de forma perfeitamente nítida, não invertida e padronizada.
    public static func drawQr(
        c: CGContext,
        url: String,
        rect: CGRect,
        radius: CGFloat,
        padding: CGFloat
    ) {
        roundRect(c: c, rect: rect, radius: radius, color: .white)

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return }
        let extent = output.extent
        guard extent.width > 0, extent.height > 0 else { return }

        let inner = rect.insetBy(dx: padding, dy: padding)
        guard let cgImage = qrContext.createCGImage(output, from: extent) else { return }

        c.saveGState()
        c.interpolationQuality = .none
        // UIImage(cgImage:) compensa automaticamente a inversão de coordenadas do UIKit
        UIImage(cgImage: cgImage).draw(in: inner)
        c.restoreGState()
    }

    /// Desenha o selo oficial estilizado da App Store em vetor nítido.
    public static func drawAppStoreBadge(
        c: CGContext,
        height: CGFloat,
        x: CGFloat,
        y: CGFloat,
        alpha: CGFloat = 1
    ) {
        c.saveGState()
        c.setAlpha(max(0, min(1, alpha)))

        // Aspect ratio padrão do badge da App Store: ~3.0 (ex: 120 x 40 ou 312 x 104)
        let width = height * 2.95
        let badgeRect = CGRect(x: x, y: y, width: width, height: height)
        let radius = height * 0.22

        // Fundo preto e borda sutil 1px
        let path = UIBezierPath(roundedRect: badgeRect, cornerRadius: radius)
        c.setFillColor(UIColor.black.cgColor)
        c.addPath(path.cgPath)
        c.fillPath()

        c.setStrokeColor(UIColor.white.withAlphaComponent(0.35).cgColor)
        c.setLineWidth(max(1, height * 0.025))
        c.addPath(path.cgPath)
        c.strokePath()

        // Logo da Apple à esquerda
        let logoHeight = height * 0.52
        let logoWidth = logoHeight * 0.82
        let logoX = x + height * 0.22
        let logoY = y + (height - logoHeight) / 2

        if let appleLogo = UIImage(systemName: "apple.logo")?.withTintColor(.white, renderingMode: .alwaysOriginal) {
            appleLogo.draw(in: CGRect(x: logoX, y: logoY, width: logoWidth, height: logoHeight))
        }

        // Textos: "Disponível na / Download on the" + "App Store"
        let textLeft = logoX + logoWidth + height * 0.16
        let isPortuguese = AppLocalization.locale.language.languageCode?.identifier == "pt"
        let isSpanish = AppLocalization.locale.language.languageCode?.identifier == "es"
        let line1 = isPortuguese ? "Disponível na" : (isSpanish ? "Disponible en el" : "Download on the")
        let line2 = "App Store"

        let size1 = height * 0.20
        let size2 = height * 0.38

        let font1 = UIFont.systemFont(ofSize: size1, weight: .regular)
        let font2 = UIFont.systemFont(ofSize: size2, weight: .semibold)

        let attr1: [NSAttributedString.Key: Any] = [.font: font1, .foregroundColor: UIColor.white]
        let attr2: [NSAttributedString.Key: Any] = [.font: font2, .foregroundColor: UIColor.white]

        let y1 = y + height * 0.22
        let y2 = y + height * 0.44

        (line1 as NSString).draw(at: CGPoint(x: textLeft, y: y1), withAttributes: attr1)
        (line2 as NSString).draw(at: CGPoint(x: textLeft, y: y2), withAttributes: attr2)

        c.restoreGState()
    }
}
