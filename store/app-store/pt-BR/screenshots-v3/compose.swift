import AppKit
import CoreText

// uso: swift compose.swift <raiz do repo>
let root = CommandLine.arguments[1]
let base = root + "/store/app-store/pt-BR"
let out = base + "/screenshots-v3"
func load(_ path: String) -> CGImage {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
let bg = load(base + "/screenshots-v3/originals/background.png")
let logo = load(root + "/design-system/assets/brand/wordmark-purple-master.png")
func image(_ c: CGContext, _ i: CGImage, _ r: CGRect) {
    c.saveGState(); c.translateBy(x: r.minX, y: r.maxY); c.scaleBy(x: 1, y: -1)
    c.draw(i, in: CGRect(x: 0, y: 0, width: r.width, height: r.height)); c.restoreGState()
}
func text(_ c: CGContext, _ s: String, _ size: CGFloat, _ y: CGFloat, _ color: CGColor) {
    let font = CTFontCreateWithName("HelveticaNeue-CondensedBlack" as CFString, size, nil)
    let a = NSAttributedString(string: s, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font, NSAttributedString.Key(kCTForegroundColorAttributeName as String): color])
    let line = CTLineCreateWithAttributedString(a)
    let w = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    c.saveGState(); c.translateBy(x: (1206 - w) / 2, y: y); c.scaleBy(x: 1, y: -1)
    c.textPosition = .zero; CTLineDraw(line, c); c.restoreGState()
}
struct Item { let source: String; let filename: String; let title: [String] }
let items = [Item(source: "resultado-real-iphone", filename: "02-resultado", title: ["VEREDITO CLARO", "ANTES DA FILA."])]
let white = CGColor(red: 244/255, green: 245/255, blue: 247/255, alpha: 1)
let purple = CGColor(red: 167/255, green: 139/255, blue: 250/255, alpha: 1)
let border = CGColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1)
for item in items {
    let c = CGContext(data: nil, width: 1206, height: 2622, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.translateBy(x: 0, y: 2622); c.scaleBy(x: 1, y: -1); c.interpolationQuality = .high
    image(c, bg, CGRect(x: 0, y: 0, width: 1206, height: 2622))
    image(c, logo, CGRect(x: 343, y: 125, width: 520, height: 520 * CGFloat(logo.height) / CGFloat(logo.width)))
    text(c, item.title[0], 86, 390, white); text(c, item.title[1], 86, 492, purple)
    // captura real sem a barra de status do aparelho (140 px de cima), cantos arredondados
    let shot = load(base + "/screenshots-v3/originals/" + item.source + ".png")
    let cropTop = 140
    let cropped = shot.cropping(to: CGRect(x: 0, y: cropTop, width: shot.width, height: shot.height - cropTop))!
    let h: CGFloat = 1900
    let w = h * CGFloat(cropped.width) / CGFloat(cropped.height)
    let rect = CGRect(x: (1206 - w) / 2, y: 650, width: w, height: h)
    let path = CGPath(roundedRect: rect, cornerWidth: 64, cornerHeight: 64, transform: nil)
    c.saveGState(); c.addPath(path); c.clip(); image(c, cropped, rect); c.restoreGState()
    c.saveGState(); c.addPath(path); c.setStrokeColor(border); c.setLineWidth(4); c.strokePath(); c.restoreGState()
    let url = URL(fileURLWithPath: out + "/" + item.filename + ".png")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, c.makeImage()!, nil); precondition(CGImageDestinationFinalize(dest))
    print(url.path)
}
