import AppKit
import AVFoundation
import CoreText

let root = CommandLine.arguments[1]
let output = URL(fileURLWithPath: root + "/marketing/tiktok/v2/lagcheck-tiktok-ranked-12s.mp4")
let silentOutput = URL(fileURLWithPath: root + "/marketing/tiktok/v2/video-sem-som.mp4")
let audioOutput = URL(fileURLWithPath: root + "/marketing/tiktok/v2/trilha-original.wav")

let width = 1080
let height = 1920
let fps: Int32 = 30
let duration = 12.0

func image(_ path: String) -> CGImage {
    let url = URL(fileURLWithPath: path)
    return CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(url as CFURL, nil)!, 0, nil)!
}

let home = image(root + "/store/app-store/pt-BR/screenshots-v3/originals/inicio.png")
let result = image(root + "/store/app-store/pt-BR/screenshots-v3/originals/resultado-real-iphone.png")
let games = image(root + "/store/app-store/pt-BR/screenshots-v3/originals/jogos.png")
let wordmark = image(root + "/design-system/assets/brand/wordmark-purple-master.png")
let icon = image(root + "/design-system/assets/app-icon/appicon-1024-master.png")

let base = CGColor(red: 11 / 255, green: 13 / 255, blue: 16 / 255, alpha: 1)
let white = CGColor(red: 244 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)
let purple = CGColor(red: 124 / 255, green: 58 / 255, blue: 237 / 255, alpha: 1)
let green = CGColor(red: 89 / 255, green: 202 / 255, blue: 104 / 255, alpha: 1)
let muted = CGColor(red: 138 / 255, green: 147 / 255, blue: 160 / 255, alpha: 1)

func easeOut(_ value: CGFloat) -> CGFloat {
    let t = min(1, max(0, value))
    return 1 - pow(1 - t, 3)
}

func drawImage(_ context: CGContext, _ image: CGImage, _ rect: CGRect, alpha: CGFloat = 1) {
    context.saveGState()
    context.setAlpha(alpha)
    context.translateBy(x: rect.minX, y: rect.maxY)
    context.scaleBy(x: 1, y: -1)
    context.draw(image, in: CGRect(origin: .zero, size: rect.size))
    context.restoreGState()
}

func drawCover(_ context: CGContext, _ image: CGImage, rect: CGRect, focusY: CGFloat, alpha: CGFloat = 1) {
    let sourceRatio = CGFloat(image.width) / CGFloat(image.height)
    let targetRatio = rect.width / rect.height
    let scaledWidth: CGFloat
    let scaledHeight: CGFloat
    if sourceRatio > targetRatio {
        scaledHeight = rect.height
        scaledWidth = scaledHeight * sourceRatio
    } else {
        scaledWidth = rect.width
        scaledHeight = scaledWidth / sourceRatio
    }
    let x = rect.minX - (scaledWidth - rect.width) / 2
    let y = rect.minY - (scaledHeight - rect.height) * focusY
    context.saveGState()
    context.clip(to: rect)
    drawImage(context, image, CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight), alpha: alpha)
    context.restoreGState()
}

func drawText(_ context: CGContext, _ text: String, size: CGFloat, x: CGFloat, y: CGFloat, color: CGColor, alpha: CGFloat = 1, tracking: CGFloat = 0) {
    let font = CTFontCreateWithName("HelveticaNeue-CondensedBlack" as CFString, size, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
        NSAttributedString.Key(kCTKernAttributeName as String): tracking
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    context.saveGState()
    context.setAlpha(alpha)
    context.translateBy(x: x, y: y)
    context.scaleBy(x: 1, y: -1)
    CTLineDraw(line, context)
    context.restoreGState()
}

func drawCentered(_ context: CGContext, _ text: String, size: CGFloat, y: CGFloat, color: CGColor, alpha: CGFloat = 1, tracking: CGFloat = 0) {
    let font = CTFontCreateWithName("HelveticaNeue-CondensedBlack" as CFString, size, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
        NSAttributedString.Key(kCTKernAttributeName as String): tracking
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    let measuredWidth = CTLineGetBoundsWithOptions(line, []).width
    context.saveGState()
    context.setAlpha(alpha)
    context.translateBy(x: (CGFloat(width) - measuredWidth) / 2, y: y)
    context.scaleBy(x: 1, y: -1)
    context.textPosition = .zero
    CTLineDraw(line, context)
    context.restoreGState()
}

func roundedRect(_ context: CGContext, _ rect: CGRect, radius: CGFloat, color: CGColor, alpha: CGFloat = 1) {
    context.saveGState()
    context.setAlpha(alpha)
    context.setFillColor(color)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.fillPath()
    context.restoreGState()
}

func screenCard(_ context: CGContext, image: CGImage, rect: CGRect, focusY: CGFloat, alpha: CGFloat = 1) {
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 26), blur: 40, color: CGColor(gray: 0, alpha: 0.55))
    roundedRect(context, rect, radius: 44, color: CGColor(red: 30 / 255, green: 35 / 255, blue: 43 / 255, alpha: 1), alpha: alpha)
    context.restoreGState()
    context.saveGState()
    context.addPath(CGPath(roundedRect: rect, cornerWidth: 44, cornerHeight: 44, transform: nil))
    context.clip()
    drawCover(context, image, rect: rect, focusY: focusY, alpha: alpha)
    context.restoreGState()
    context.saveGState()
    context.setAlpha(alpha)
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.18))
    context.setLineWidth(2)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: 44, cornerHeight: 44, transform: nil))
    context.strokePath()
    context.restoreGState()
}

func drawBackdrop(_ context: CGContext, time: CGFloat) {
    context.setFillColor(base)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let center = CGPoint(x: CGFloat(width) * 0.5, y: 780)
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        CGColor(red: 124 / 255, green: 58 / 255, blue: 237 / 255, alpha: 0.24),
        CGColor(red: 11 / 255, green: 13 / 255, blue: 16 / 255, alpha: 0)
    ] as CFArray, locations: [0, 1])!
    context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 900, options: [])
    context.saveGState()
    context.setStrokeColor(CGColor(red: 124 / 255, green: 58 / 255, blue: 237 / 255, alpha: 0.16))
    context.setLineWidth(2)
    let offset = time.truncatingRemainder(dividingBy: 1) * 160
    for index in -10...14 {
        let y = CGFloat(index) * 160 + offset
        context.move(to: CGPoint(x: 0, y: y))
        context.addLine(to: CGPoint(x: CGFloat(width), y: y + 300))
    }
    context.strokePath()
    context.restoreGState()
}

func render(_ context: CGContext, time: CGFloat) {
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    context.interpolationQuality = .high
    drawBackdrop(context, time: time)

    let beat = 0.5 + 0.5 * sin(time * .pi * 4)
    let progress = max(0, min(1, time / CGFloat(duration)))
    roundedRect(context, CGRect(x: 74, y: 1810, width: 932 * progress, height: 7), radius: 4, color: purple)

    if time < 1.8 {
        let enter = easeOut(time / 0.28)
        drawCentered(context, "VAI ENTRAR", size: 116, y: 592 - (1 - enter) * 45, color: white, alpha: enter, tracking: 1)
        drawCentered(context, "NA RANKED?", size: 144, y: 742 - (1 - enter) * 45, color: purple, alpha: enter, tracking: 1)
        drawCentered(context, "CONFERE A ROTA ANTES.", size: 45, y: 920, color: muted, alpha: enter)
        let iconScale = 1 + beat * 0.025
        let iconRect = CGRect(x: 425 - (iconScale - 1) * 115, y: 1115 - (iconScale - 1) * 115, width: 230 * iconScale, height: 230 * iconScale)
        drawImage(context, icon, iconRect, alpha: enter)
    } else if time < 4.5 {
        let local = time - 1.8
        let enter = easeOut(local / 0.35)
        drawCentered(context, "ANTES DA FILA.", size: 78, y: 190, color: white, alpha: enter, tracking: 1)
        drawCentered(context, "FAZ O CHECK.", size: 92, y: 287, color: purple, alpha: enter, tracking: 1)
        let zoom = 1 + local * 0.035
        let rect = CGRect(x: 94 - (zoom - 1) * 446, y: 462 - (zoom - 1) * 640, width: 892 * zoom, height: 1170 * zoom)
        screenCard(context, image: home, rect: rect, focusY: 0.20, alpha: enter)
        let ringProgress = min(1, max(0, (local - 0.55) / 0.55))
        context.saveGState()
        context.setAlpha(1 - ringProgress)
        context.setStrokeColor(purple)
        context.setLineWidth(5)
        context.addEllipse(in: CGRect(x: 410 - ringProgress * 75, y: 1222 - ringProgress * 75, width: 260 + ringProgress * 150, height: 110 + ringProgress * 150))
        context.strokePath()
        context.restoreGState()
    } else if time < 7.2 {
        let local = time - 4.5
        let enter = easeOut(local / 0.25)
        drawCentered(context, "A ROTA MOSTRA", size: 69, y: 180, color: white, alpha: enter, tracking: 1)
        drawCentered(context, "O QUE TÁ ROLANDO.", size: 69, y: 264, color: white, alpha: enter, tracking: 1)
        screenCard(context, image: games, rect: CGRect(x: 128, y: 447, width: 824, height: 1130), focusY: 0.20, alpha: enter)
    } else if time < 9.9 {
        let local = time - 7.2
        let enter = easeOut(local / 0.22)
        drawCentered(context, "RESULTADO CLARO.", size: 76, y: 168, color: white, alpha: enter, tracking: 1)
        screenCard(context, image: result, rect: CGRect(x: 120, y: 365, width: 840, height: 1195), focusY: 0.30, alpha: enter)
        roundedRect(context, CGRect(x: 184, y: 1648, width: 712, height: 88), radius: 44, color: green, alpha: enter)
        drawCentered(context, "PRONTO PARA RANKED", size: 40, y: 1674, color: base, alpha: enter, tracking: 1)
    } else {
        let local = time - 9.9
        let enter = easeOut(local / 0.30)
        drawImage(context, wordmark, CGRect(x: 220, y: 285, width: 640, height: 133), alpha: enter)
        drawCentered(context, "ANTES DA FILA.", size: 92, y: 682, color: white, alpha: enter, tracking: 1)
        drawCentered(context, "FAZ UM LAGCHECK.", size: 92, y: 792, color: purple, alpha: enter, tracking: 1)
        roundedRect(context, CGRect(x: 190, y: 1045, width: 700, height: 120), radius: 60, color: purple, alpha: enter)
        drawCentered(context, "CONHEÇA NA APP STORE", size: 37, y: 1085, color: white, alpha: enter, tracking: 1.2)
        drawCentered(context, "lagcheck", size: 38, y: 1320, color: muted, alpha: enter, tracking: 1)
    }
}

func makeAudio() throws {
    let sampleRate = 48_000.0
    let samples = Int(sampleRate * duration)
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples))!
    buffer.frameLength = AVAudioFrameCount(samples)
    for index in 0..<samples {
        let time = Double(index) / sampleRate
        let beat = time.truncatingRemainder(dividingBy: 0.5)
        let eighth = time.truncatingRemainder(dividingBy: 0.25)
        let kick = 0.34 * exp(-beat * 24) * sin(2 * Double.pi * (58 * beat + 2.2 * (1 - exp(-beat * 34))))
        let bass = 0.085 * sin(2 * Double.pi * 55 * time) * exp(-beat * 3.6)
        let tick = 0.030 * sin(2 * Double.pi * 1600 * time) * exp(-eighth * 70)
        let tension = time < 1.8 ? 0.7 : 1.0
        let fade = min(1, time / 0.10) * min(1, (duration - time) / 0.55)
        let value = Float((kick + bass + tick) * tension * fade)
        buffer.floatChannelData![0][index] = value
        buffer.floatChannelData![1][index] = value
    }
    let file = try AVAudioFile(forWriting: audioOutput, settings: format.settings)
    try file.write(from: buffer)
}

try? FileManager.default.removeItem(at: silentOutput)
try? FileManager.default.removeItem(at: output)
try? FileManager.default.removeItem(at: audioOutput)
let writer = try AVAssetWriter(outputURL: silentOutput, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 10_000_000, AVVideoExpectedSourceFrameRateKey: fps]
])
let adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: width,
    kCVPixelBufferHeightKey as String: height,
    kCVPixelBufferCGImageCompatibilityKey as String: true,
    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
])
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

for frame in 0..<Int(duration * Double(fps)) {
    while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.003) }
    autoreleasepool {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adapter.pixelBufferPool!, &pixelBuffer)
        CVPixelBufferLockBaseAddress(pixelBuffer!, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer!),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )!
        render(context, time: CGFloat(frame) / CGFloat(fps))
        if [20, 78, 165, 250, 330].contains(frame) {
            let preview = URL(fileURLWithPath: root + "/marketing/tiktok/v2/frame-\(frame).png")
            let destination = CGImageDestinationCreateWithURL(preview as CFURL, "public.png" as CFString, 1, nil)!
            CGImageDestinationAddImage(destination, context.makeImage()!, nil)
            CGImageDestinationFinalize(destination)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, [])
        precondition(adapter.append(pixelBuffer!, withPresentationTime: CMTime(value: Int64(frame), timescale: fps)))
    }
}

input.markAsFinished()
let finished = DispatchSemaphore(value: 0)
writer.finishWriting { finished.signal() }
finished.wait()
precondition(writer.status == .completed, "Video writing failed")

try makeAudio()
let composition = AVMutableComposition()
let videoAsset = AVURLAsset(url: silentOutput)
let audioAsset = AVURLAsset(url: audioOutput)
let range = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))
try composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
    .insertTimeRange(range, of: videoAsset.tracks(withMediaType: .video)[0], at: .zero)
try composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
    .insertTimeRange(range, of: audioAsset.tracks(withMediaType: .audio)[0], at: .zero)
let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
export.outputURL = output
export.outputFileType = .mp4
export.shouldOptimizeForNetworkUse = true
let exported = DispatchSemaphore(value: 0)
export.exportAsynchronously { exported.signal() }
exported.wait()
precondition(export.status == .completed, "Mux failed: \(String(describing: export.error))")
print(output.path)
