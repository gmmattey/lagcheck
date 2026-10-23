import AppKit
import CoreText

let root = CommandLine.arguments[1]
let output = root + "/marketing/betalist/en-US/hero-check-before-you-queue.jpg"
let width = 1600
let height = 900

func load(_ path: String) -> CGImage {
    CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!, 0, nil)!
}

let home = load(root + "/store/app-store/en-US/screenshots-v3/originals/home.png")
let wordmark = load(root + "/design-system/assets/brand/wordmark-purple-master.png")
let canvas = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let base = CGColor(red: 11 / 255, green: 13 / 255, blue: 16 / 255, alpha: 1)
let white = CGColor(red: 244 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)
let muted = CGColor(red: 181 / 255, green: 187 / 255, blue: 198 / 255, alpha: 1)
let purple = CGColor(red: 124 / 255, green: 58 / 255, blue: 237 / 255, alpha: 1)

canvas.translateBy(x: 0, y: CGFloat(height))
canvas.scaleBy(x: 1, y: -1)

func drawImage(_ image: CGImage, rect: CGRect) {
    canvas.saveGState()
    canvas.translateBy(x: rect.minX, y: rect.maxY)
    canvas.scaleBy(x: 1, y: -1)
    canvas.draw(image, in: CGRect(origin: .zero, size: rect.size))
    canvas.restoreGState()
}

func drawText(_ value: String, size: CGFloat, x: CGFloat, y: CGFloat, color: CGColor, tracking: CGFloat = 0) {
    let font = CTFontCreateWithName("HelveticaNeue-CondensedBlack" as CFString, size, nil)
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: value, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
        NSAttributedString.Key(kCTKernAttributeName as String): tracking
    ]))
    canvas.saveGState()
    canvas.translateBy(x: x, y: y)
    canvas.scaleBy(x: 1, y: -1)
    canvas.textPosition = .zero
    CTLineDraw(line, canvas)
    canvas.restoreGState()
}

canvas.setFillColor(base)
canvas.fill(CGRect(x: 0, y: 0, width: width, height: height))
let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
    CGColor(red: 124 / 255, green: 58 / 255, blue: 237 / 255, alpha: 0.42),
    CGColor(red: 11 / 255, green: 13 / 255, blue: 16 / 255, alpha: 0)
] as CFArray, locations: [0, 1])!
canvas.drawRadialGradient(glow, startCenter: CGPoint(x: 1280, y: 460), startRadius: 0, endCenter: CGPoint(x: 1280, y: 460), endRadius: 780, options: [])
canvas.setStrokeColor(CGColor(red: 124 / 255, green: 58 / 255, blue: 237 / 255, alpha: 0.18))
canvas.setLineWidth(2)
for index in -2...7 {
    let y = CGFloat(index) * 170
    canvas.move(to: CGPoint(x: 0, y: y))
    canvas.addLine(to: CGPoint(x: 1600, y: y + 450))
}
canvas.strokePath()

drawImage(wordmark, rect: CGRect(x: 105, y: 110, width: 335, height: 70))
drawText("CHECK YOUR", size: 92, x: 105, y: 285, color: white, tracking: 1)
drawText("CONNECTION", size: 92, x: 105, y: 390, color: white, tracking: 1)
drawText("BEFORE YOU QUEUE.", size: 92, x: 105, y: 495, color: purple, tracking: 1)
drawText("Latency, stability and packet loss.", size: 31, x: 110, y: 605, color: muted)

let phoneRect = CGRect(x: 1050, y: 72, width: 370, height: 806)
canvas.saveGState()
canvas.setShadow(offset: CGSize(width: 0, height: 20), blur: 35, color: CGColor(gray: 0, alpha: 0.7))
canvas.setFillColor(CGColor(red: 30 / 255, green: 35 / 255, blue: 43 / 255, alpha: 1))
canvas.addPath(CGPath(roundedRect: phoneRect, cornerWidth: 40, cornerHeight: 40, transform: nil))
canvas.fillPath()
canvas.restoreGState()
canvas.saveGState()
canvas.addPath(CGPath(roundedRect: phoneRect, cornerWidth: 40, cornerHeight: 40, transform: nil))
canvas.clip()
drawImage(home, rect: phoneRect)
canvas.restoreGState()
canvas.setStrokeColor(purple)
canvas.setLineWidth(3)
canvas.addPath(CGPath(roundedRect: phoneRect, cornerWidth: 40, cornerHeight: 40, transform: nil))
canvas.strokePath()

let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: output) as CFURL, "public.jpeg" as CFString, 1, nil)!
CGImageDestinationAddImage(destination, canvas.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.84] as CFDictionary)
precondition(CGImageDestinationFinalize(destination))
print(output)
