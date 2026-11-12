import AppKit

// uso: swift compose-card.swift <raiz do repo>
// Cabeçalho do cartão do App Clip: 1800x1200, PNG sem alpha, sem texto (vale para qualquer idioma).
let root = CommandLine.arguments[1]
func load(_ path: String) -> CGImage {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
let bg = load(root + "/store/app-store/pt-BR/screenshots-v3/originals/background.png")
let logo = load(root + "/design-system/assets/brand/wordmark-purple-master.png")
let W = 1800, H = 1200
let c = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
c.interpolationQuality = .high
c.setFillColor(CGColor(red: 11/255, green: 13/255, blue: 16/255, alpha: 1)); c.fill(CGRect(x: 0, y: 0, width: W, height: H))
// fundo vertical girado 90° e ampliado para cobrir (largura original vira a altura)
let scale = CGFloat(H) / CGFloat(bg.width)
let drawW = CGFloat(bg.width) * scale, drawH = CGFloat(bg.height) * scale
c.saveGState()
c.translateBy(x: CGFloat(W) / 2, y: CGFloat(H) / 2); c.rotate(by: .pi / 2)
c.draw(bg, in: CGRect(x: -drawW / 2, y: -drawH / 2, width: drawW, height: drawH))
c.restoreGState()
let lw: CGFloat = 1050, lh = lw * CGFloat(logo.height) / CGFloat(logo.width)
c.draw(logo, in: CGRect(x: (CGFloat(W) - lw) / 2, y: (CGFloat(H) - lh) / 2, width: lw, height: lh))
let url = URL(fileURLWithPath: root + "/store/app-store/app-clip/card-1800x1200.png")
let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, c.makeImage()!, nil); precondition(CGImageDestinationFinalize(dest))
print(url.path)
