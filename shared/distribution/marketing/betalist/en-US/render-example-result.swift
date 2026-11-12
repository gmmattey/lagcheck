import AppKit
import CoreText
import ImageIO

// Usage: swift render-example-result.swift <repository root>
let root = CommandLine.arguments[1]
let kit = root + "/marketing/betalist/en-US"

func load(_ path: String) -> CGImage {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}

func drawImage(_ context: CGContext, _ image: CGImage, in rect: CGRect) {
    context.saveGState()
    context.translateBy(x: rect.minX, y: rect.maxY)
    context.scaleBy(x: 1, y: -1)
    context.draw(image, in: CGRect(origin: .zero, size: rect.size))
    context.restoreGState()
}

func drawCenteredText(_ context: CGContext, _ value: String, size: CGFloat, y: CGFloat, color: CGColor) {
    let font = CTFontCreateWithName("HelveticaNeue-CondensedBlack" as CFString, size, nil)
    let attributed = NSAttributedString(string: value, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
    ])
    let line = CTLineCreateWithAttributedString(attributed)
    let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    context.saveGState()
    context.translateBy(x: (1206 - width) / 2, y: y)
    context.scaleBy(x: 1, y: -1)
    CTLineDraw(line, context)
    context.restoreGState()
}

let background = load(root + "/store/app-store/pt-BR/screenshots-v3/originals/background.png")
let wordmark = load(root + "/design-system/assets/brand/wordmark-purple-master.png")
let result = load(kit + "/source-example-result.png")
let canvas = CGContext(
    data: nil,
    width: 1206,
    height: 2622,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

canvas.translateBy(x: 0, y: 2622)
canvas.scaleBy(x: 1, y: -1)
canvas.interpolationQuality = .high

let white = CGColor(red: 244 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)
let border = CGColor(red: 124 / 255, green: 58 / 255, blue: 237 / 255, alpha: 1)

drawImage(canvas, background, in: CGRect(x: 0, y: 0, width: 1206, height: 2622))
drawImage(canvas, wordmark, in: CGRect(x: 343, y: 128, width: 520, height: 108))
drawCenteredText(canvas, "EXAMPLE RESULT.", size: 82, y: 390, color: white)

// Remove the device status bar so the result is the visual focus.
let cropTop = 140
let cropped = result.cropping(to: CGRect(x: 0, y: cropTop, width: result.width, height: result.height - cropTop))!
let height: CGFloat = 1745
let width = height * CGFloat(cropped.width) / CGFloat(cropped.height)
let screen = CGRect(x: (1206 - width) / 2, y: 650, width: width, height: height)
let roundedScreen = CGPath(roundedRect: screen, cornerWidth: 64, cornerHeight: 64, transform: nil)
canvas.saveGState()
canvas.addPath(roundedScreen)
canvas.clip()
drawImage(canvas, cropped, in: screen)
canvas.restoreGState()
canvas.saveGState()
canvas.addPath(roundedScreen)
canvas.setStrokeColor(border)
canvas.setLineWidth(4)
canvas.strokePath()
canvas.restoreGState()

let output = URL(fileURLWithPath: kit + "/03-example-result.jpg")
let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.jpeg" as CFString, 1, nil)!
CGImageDestinationAddImage(destination, canvas.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.84] as CFDictionary)
precondition(CGImageDestinationFinalize(destination))
print(output.path)
