import Foundation
import UIKit
import CoreGraphics
import AVFoundation

/// Vídeo 9:16 de 14 s do resultado (MP4/H.264, AVFoundation), gerado no aparelho a partir do resultado real.
/// Cenas: escolha 0–3,5 s (grade de capas com scanner), medição 3,5–9,5 s (números subindo até o valor medido)
/// e resultado 9,5–14 s. Paridade 1:1 estrita com ShareVideoRenderer.kt do Android (Decisões 81 e 103).
public enum ShareVideoRenderer {

    public final class CancelledError: Error, @unchecked Sendable {}

    public static func videoOutputURL() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("share", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("lagcheck-check.mp4")
    }

    public static func render(
        scene: ShareMediaScene,
        images: ShareMediaImages,
        isCancelled: @escaping @Sendable () -> Bool = { false },
        onProgress: @escaping @Sendable (Float) -> Void = { _ in }
    ) async throws -> URL {
        let w = ShareVideoTimeline.WIDTH
        let h = ShareVideoTimeline.HEIGHT
        let fps = ShareVideoTimeline.FPS
        let totalFrames = ShareVideoTimeline.frameCount
        let outputURL = videoOutputURL()

        try? FileManager.default.removeItem(at: outputURL)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: w,
            AVVideoHeightKey: h,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8_000_000,
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false

        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: w,
            kCVPixelBufferHeightKey as String: h,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )

        guard writer.canAdd(writerInput) else {
            throw NSError(domain: "LagCheckShare", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input to AVAssetWriter"])
        }
        writer.add(writerInput)

        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "LagCheckShare", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to start writing"])
        }
        writer.startSession(atSourceTime: .zero)

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        for frameIndex in 0..<totalFrames {
            if isCancelled() {
                writerInput.markAsFinished()
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: outputURL)
                throw CancelledError()
            }

            while !writerInput.isReadyForMoreMediaData {
                try? await Task.sleep(nanoseconds: 5_000_000)
                if isCancelled() {
                    writerInput.markAsFinished()
                    writer.cancelWriting()
                    try? FileManager.default.removeItem(at: outputURL)
                    throw CancelledError()
                }
            }

            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, adaptor.pixelBufferPool!, &pixelBuffer)
            guard status == kCVReturnSuccess, let pb = pixelBuffer else {
                continue
            }

            CVPixelBufferLockBaseAddress(pb, [])
            let data = CVPixelBufferGetBaseAddress(pb)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pb)

            if let context = CGContext(
                data: data,
                width: w,
                height: h,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ) {
                // Cria uma camada UIKit / UIGraphicsPushContext para desenhar com UIKit e CoreGraphics
                UIGraphicsPushContext(context)
                let t = Double(frameIndex) / Double(fps)
                drawFrame(c: context, t: t, scene: scene, images: images)
                UIGraphicsPopContext()
            }

            CVPixelBufferUnlockBaseAddress(pb, [])

            let presentationTime = CMTime(value: Int64(frameIndex), timescale: fps)
            adaptor.append(pb, withPresentationTime: presentationTime)

            let progress = Float(frameIndex + 1) / Float(totalFrames)
            onProgress(min(1, max(0, progress)))
        }

        writerInput.markAsFinished()
        await withCheckedContinuation { continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }

        if writer.status != .completed {
            try? FileManager.default.removeItem(at: outputURL)
            throw writer.error ?? NSError(domain: "LagCheckShare", code: -3, userInfo: [NSLocalizedDescriptionKey: "Video render failed"])
        }

        return outputURL
    }

    // ---- Animação (mesma curva e paridade estrita com o Android) ----
    private static func clamp(_ v: Double, _ a: Double = 0.0, _ b: Double = 1.0) -> Double {
        max(a, min(b, v))
    }

    private static func easeOutCubic(_ x: Double) -> Double {
        1 - pow(1 - x, 3)
    }

    private static func easeInOut(_ x: Double) -> Double {
        -(cos(.pi * x) - 1) / 2
    }

    private static func easeOutBack(_ x: Double) -> Double {
        let c1 = 1.70158
        let c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }

    private static func ramp(_ t: Double, _ a: Double, _ b: Double, _ ease: (Double) -> Double) -> Double {
        ease(clamp((t - a) / (b - a)))
    }

    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ k: Double) -> CGFloat {
        a + (b - a) * CGFloat(k)
    }

    private static let TILE: CGFloat = 300
    private static let GAP: CGFloat = 26
    private static let X0: CGFloat = 64
    private static let Y0: CGFloat = 440
    private static let scan = [0, 1, 2, 5, 8, 7, 6, 3, 4]

    private static func tileCx(_ i: Int) -> CGFloat {
        X0 + CGFloat(i % 3) * (TILE + GAP) + TILE / 2
    }

    private static func tileCy(_ i: Int) -> CGFloat {
        Y0 + CGFloat(i / 3) * (TILE + GAP) + TILE / 2
    }

    private static func message(mt: Double, scene: ShareMediaScene) -> (Double, String) {
        let isPt = AppLocalization.locale.language.languageCode?.identifier == "pt"
        let isEs = AppLocalization.locale.language.languageCode?.identifier == "es"

        let all: [(Double, String)]
        if isPt {
            all = [
                (0.0, "Procurando o servidor mais próximo…"),
                (1.0, "Testando os reflexos da sua rede."),
                (2.4, "Cada milissegundo conta em \(scene.gameName)."),
                (3.8, "Enchendo a fila para ver se aguenta a pressão."),
                (5.0, "Quase lá. Preparando seu veredito.")
            ]
        } else if isEs {
            all = [
                (0.0, "Buscando el servidor más cercano…"),
                (1.0, "Probando los reflejos de tu red."),
                (2.4, "Cada milisegundo cuenta en \(scene.gameName)."),
                (3.8, "Probando bajo carga de red."),
                (5.0, "Casi listo. Preparando veredicto.")
            ]
        } else {
            all = [
                (0.0, "Finding the nearest game server…"),
                (1.0, "Testing your connection reflexes."),
                (2.4, "Every millisecond counts in \(scene.gameName)."),
                (3.8, "Testing connection under traffic load."),
                (5.0, "Almost done. Preparing your verdict.")
            ]
        }
        return all.last(where: { $0.0 <= mt }) ?? all[0]
    }

    public static func drawFrame(c: CGContext, t: Double, scene: ShareMediaScene, images: ShareMediaImages) {
        let tl = ShareVideoTimeline.self
        let w = CGFloat(tl.WIDTH)
        let h = CGFloat(tl.HEIGHT)
        let full = CGRect(x: 0, y: 0, width: w, height: h)
        let m = tl.MEASURE_START
        let r = tl.RESULT_START
        let end = tl.DURATION

        let fadeIn = ramp(t, 0.0, 0.5, easeOutCubic)
        let fadeOut = 1 - ramp(t, end - 0.5, end, easeOutCubic)
        let all = CGFloat(min(fadeIn, fadeOut))
        let picked = t >= 2.5
        let toMeasure = ramp(t, m - 0.1, m + 0.8, easeInOut)
        let toResult = ramp(t, r - 0.1, r + 0.7, easeInOut)
        let others = 1 - ramp(t, m - 0.2, m + 0.4, easeOutCubic)

        ShareCanvas.fillRect(c: c, l: 0, t: 0, r: w, b: h, color: ShareCanvas.deep)

        // Cena 1: título e grade de capas
        let head = 1 - toMeasure
        if head > 0.01 {
            let a = all * CGFloat(head)
            let dy = CGFloat(-toMeasure * 30)
            ShareCanvas.draw(
                c: c,
                text: "CHECK",
                x: 64,
                y: 322 + dy,
                size: 26,
                weight: .semibold,
                color: ShareCanvas.accent,
                kern: 3,
                alpha: a,
                mono: true
            )
            let isPt = AppLocalization.locale.language.languageCode?.identifier == "pt"
            let chooseText = isPt ? "Escolha seu jogo." : "Choose your game."
            let title = picked ? scene.gameName : chooseText
            ShareCanvas.draw(
                c: c,
                text: title,
                x: 64,
                y: 404 + dy,
                size: 80,
                weight: .bold,
                color: ShareCanvas.text,
                kern: -3,
                alpha: a
            )
        }

        let scanP = clamp((t - 1.2) / 1.2)
        let cursor = scan[min(scan.count - 1, Int(scanP * Double(scan.count)))]
        var tiles = images.tiles

        for i in 0..<9 {
            let isSel = (i == 4)
            let bmp: UIImage? = isSel ? images.art : (tiles.isEmpty ? nil : tiles.removeFirst())
            let k = ramp(t, 0.2 + Double(i) * 0.08, 0.7 + Double(i) * 0.08, easeOutBack)
            let op = isSel ? k : k * others * (picked ? 0.5 : 1.0)
            if op <= 0.01 { continue }

            let tw = isSel ? lerp(TILE, w, toMeasure) : TILE
            let th = isSel ? lerp(TILE, h, toMeasure) : TILE
            let cx = isSel ? w / 2 : tileCx(i)
            let cy = isSel ? lerp(tileCy(i), h / 2, toMeasure) : tileCy(i)
            let sc = isSel ? 1.0 : CGFloat(0.9 + 0.1 * clamp(k))
            let hot = ((cursor == i && t >= 1.2 && t < 2.5) || (isSel && picked)) && toMeasure < 0.05
            let radius = isSel ? lerp(67, 0, toMeasure) : 67

            c.saveGState()
            c.setAlpha(all * CGFloat(clamp(op)))
            c.translateBy(x: cx, y: cy)
            c.scaleBy(x: sc, y: sc)
            c.translateBy(x: -cx, y: -cy)

            let rect = CGRect(x: cx - tw / 2, y: cy - th / 2, width: tw, height: th)
            if hot {
                ShareCanvas.roundRect(c: c, rect: rect.insetBy(dx: -7, dy: -7), radius: radius + 7, color: ShareCanvas.purple)
            }
            ShareCanvas.roundRect(c: c, rect: rect, radius: radius, color: ShareCanvas.deep)
            ShareCanvas.drawFill(c: c, image: bmp, rect: rect, radius: radius)
            c.restoreGState()
        }

        if toMeasure > 0.01 {
            let deep = ShareCanvas.deep
            ShareCanvas.gradient(
                c: c,
                stops: [
                    (0, ShareCanvas.withAlpha(deep, 0.7)),
                    (0.22, ShareCanvas.withAlpha(deep, 0.05)),
                    (0.40, ShareCanvas.withAlpha(deep, 0.15)),
                    (0.62, ShareCanvas.withAlpha(deep, 0.9)),
                    (1, ShareCanvas.withAlpha(deep, 0.97))
                ],
                start: .zero,
                end: CGPoint(x: 0, y: h),
                rect: full,
                alpha: all * CGFloat(toMeasure)
            )
        }

        if toResult > 0.01 {
            ShareCanvas.fillRect(
                c: c,
                l: 0,
                t: 0,
                r: w,
                b: h,
                color: ShareCanvas.withAlpha(ShareCanvas.deep, all * CGFloat(toResult * 0.4))
            )
        }
        ShareCanvas.drawImage(c: c, image: images.wordmark, height: 60, x: 64, y: 200)

        // Cena 2: medição (os números do teste subindo até o valor medido)
        let meas = 1 - ramp(t, r - 0.3, r + 0.2, easeOutCubic)
        if toMeasure > 0.01 && meas > 0.01 {
            let mt = clamp(t - m, 0.0, r - m)
            let prog = clamp(mt / (r - m - 0.4))
            let a = all * CGFloat(toMeasure * meas)

            ShareCanvas.roundRect(
                c: c,
                rect: CGRect(x: 64, y: 1040, width: 952, height: 8),
                radius: 4,
                color: ShareCanvas.withAlpha(UIColor.white, 0.12 * a)
            )
            ShareCanvas.roundRect(
                c: c,
                rect: CGRect(x: 64, y: 1040, width: max(0, 952 * CGFloat(prog)), height: 8),
                radius: 4,
                color: ShareCanvas.withAlpha(ShareCanvas.purple, a)
            )

            let msg = message(mt: mt, scene: scene)
            let msgK = ramp(t, m + msg.0, m + msg.0 + 0.4, easeOutCubic)
            let wrapped = ShareCanvas.wrap(msg.1, size: 72, weight: .bold, kern: -2, maxWidth: 952)
            for (i, line) in wrapped.prefix(3).enumerated() {
                ShareCanvas.draw(
                    c: c,
                    text: line,
                    x: 64,
                    y: 1148 + CGFloat(i) * 80 + CGFloat((1 - msgK) * 24),
                    size: 72,
                    weight: .bold,
                    color: ShareCanvas.text,
                    kern: -2,
                    shadow: true,
                    alpha: a * CGFloat(msgK)
                )
            }

            let windows = [(1.0, 3.0), (2.0, 3.6), (3.8, 5.2)]
            let colW = (w - 128 - 56) / 3

            for (i, metric) in scene.metrics.enumerated() {
                let x = 64 + CGFloat(i) * (colW + 28)
                let y: CGFloat = 1420
                let p = clamp((mt - windows[i].0) / (windows[i].1 - windows[i].0))
                let n = metric.number
                let shown: String
                if let n, p > 0 {
                    if metric.kind == .ping {
                        shown = "\(Int(round(n * p)))"
                    } else {
                        shown = ShareMediaScene.format(n * p, decimals: 1)
                    }
                } else {
                    shown = "—"
                }

                ShareCanvas.fillRect(
                    c: c,
                    l: x,
                    t: y - 30,
                    r: x + 3,
                    b: y + 104,
                    color: ShareCanvas.withAlpha(UIColor.white, 0.28 * a)
                )
                ShareCanvas.draw(
                    c: c,
                    text: ShareMediaRenderer.label(metric: metric),
                    x: x + 26,
                    y: y,
                    size: 26,
                    weight: .semibold,
                    color: ShareCanvas.accent,
                    kern: 3,
                    alpha: a,
                    mono: true
                )
                ShareCanvas.draw(
                    c: c,
                    text: shown,
                    x: x + 26,
                    y: y + 84,
                    size: 84,
                    weight: .bold,
                    color: (shown == "—") ? ShareCanvas.muted : ShareCanvas.text,
                    kern: -3,
                    alpha: a
                )
                if shown != "—" && !metric.unit.isEmpty {
                    let vw = ShareCanvas.width(shown, size: 84, weight: .bold, kern: -3)
                    ShareCanvas.draw(
                        c: c,
                        text: metric.unit,
                        x: x + 26 + vw + 6,
                        y: y + 84,
                        size: 26,
                        weight: .medium,
                        color: ShareCanvas.muted,
                        alpha: a
                    )
                }
            }
        }

        // Cena 3: veredito, números medidos e chamada para o app
        let k = ramp(t, r + 0.2, r + 0.8, easeOutCubic)
        if k > 0.01 {
            c.saveGState()
            c.translateBy(x: 0, y: CGFloat((1 - k) * 50))
            ShareMediaRenderer.drawVerdictBlock(
                c: c,
                scene: scene,
                images: images,
                top: 700,
                alpha: all * CGFloat(k),
                reveal: CGFloat(ramp(t, r + 0.5, r + 1.7, easeOutBack)),
                width: w
            )
            c.restoreGState()
        }
    }
}
