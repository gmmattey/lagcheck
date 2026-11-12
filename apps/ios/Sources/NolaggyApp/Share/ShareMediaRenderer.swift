import UIKit
import CoreGraphics
import NolaggyDomain

/// Cards de compartilhamento: 1200x630 (link preview) e 1080x1920 (Status, Stories, TikTok).
/// Paridade 1:1 estrita com ShareMediaRenderer.kt do Android (Decisões 81 e 103).
public enum ShareMediaRenderer {
    public enum Kind: Sendable {
        case preview
        case story
    }

    public static let PREVIEW_W: CGFloat = 1200
    public static let PREVIEW_H: CGFloat = 630
    public static let STORY_W: CGFloat = 1080
    public static let STORY_H: CGFloat = 1920

    /// Gera JPEG do card (o preview fica abaixo de ~300 KB).
    public static func jpeg(kind: Kind, scene: ShareMediaScene, images: ShareMediaImages) -> Data? {
        let w = (kind == .preview) ? PREVIEW_W : STORY_W
        let h = (kind == .preview) ? PREVIEW_H : STORY_H
        let bounds = CGRect(x: 0, y: 0, width: w, height: h)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { rendererContext in
            let c = rendererContext.cgContext
            if kind == .preview {
                drawPreview(c: c, scene: scene, images: images)
            } else {
                drawStory(c: c, scene: scene, images: images)
            }
        }

        let quality: CGFloat = (kind == .preview) ? 0.82 : 0.90
        return image.jpegData(compressionQuality: quality)
    }

    public static func headlineSentence(scene: ShareMediaScene) -> String {
        let lower = scene.headline.lowercased(with: AppLocalization.locale)
        guard let first = lower.first else { return lower }
        return String(first).uppercased(with: AppLocalization.locale) + lower.dropFirst()
    }

    public static func label(metric: ShareMetric) -> String {
        switch metric.kind {
        case .ping:
            let s = AppLocalization.string("share.card.metric.response", comment: "")
            return (s.isEmpty ? "RESPOSTA" : s).uppercased()
        case .jitter:
            let s = AppLocalization.string("share.card.metric.jitter", comment: "")
            return (s.isEmpty ? "JITTER" : s).uppercased()
        case .packetLoss:
            let s = AppLocalization.string("share.card.metric.loss", comment: "")
            return (s.isEmpty ? "PERDA" : s).uppercased()
        }
    }

    public static func eyebrow(scene: ShareMediaScene) -> String {
        "CHECK · \(scene.gameName)".uppercased()
    }

    public struct MetricStyle {
        public let border: CGFloat
        public let pad: CGFloat
        public let label: CGFloat
        public let value: CGFloat
        public let unit: CGFloat
        public let gap: CGFloat
        public let height: CGFloat

        public init(
            border: CGFloat,
            pad: CGFloat,
            label: CGFloat,
            value: CGFloat,
            unit: CGFloat,
            gap: CGFloat,
            height: CGFloat
        ) {
            self.border = border
            self.pad = pad
            self.label = label
            self.value = value
            self.unit = unit
            self.gap = gap
            self.height = height
        }
    }

    public static func drawMetric(
        c: CGContext,
        metric: ShareMetric,
        x: CGFloat,
        y: CGFloat,
        k: MetricStyle,
        valueOverride: String? = nil,
        alpha: CGFloat = 1
    ) {
        ShareCanvas.fillRect(
            c: c,
            l: x,
            t: y - k.label - 4,
            r: x + k.border,
            b: y - k.label - 4 + k.height,
            color: ShareCanvas.withAlpha(UIColor.white, 0.28 * alpha)
        )
        ShareCanvas.draw(
            c: c,
            text: label(metric: metric),
            x: x + k.pad,
            y: y,
            size: k.label,
            weight: .semibold,
            color: ShareCanvas.accent,
            kern: k.label >= 26 ? 3 : 2,
            shadow: true,
            alpha: alpha,
            mono: true
        )
        let vy = y + k.value * 0.95
        let kern = -k.value / 30
        let shown = valueOverride ?? metric.value
        ShareCanvas.draw(
            c: c,
            text: shown,
            x: x + k.pad,
            y: vy,
            size: k.value,
            weight: .bold,
            color: ShareCanvas.text,
            kern: kern,
            shadow: true,
            alpha: alpha
        )
        if !metric.unit.isEmpty && shown != "—" {
            let w = ShareCanvas.width(shown, size: k.value, weight: .bold, kern: kern)
            ShareCanvas.draw(
                c: c,
                text: metric.unit,
                x: x + k.pad + w + k.gap,
                y: vy,
                size: k.unit,
                weight: .medium,
                color: ShareCanvas.muted,
                shadow: true,
                alpha: alpha
            )
        }
    }

    // ---- 1a · Link preview 1200x630 ----
    public static func drawPreview(c: CGContext, scene: ShareMediaScene, images: ShareMediaImages) {
        let w = PREVIEW_W
        let h = PREVIEW_H
        let rect = CGRect(x: 0, y: 0, width: w, height: h)

        ShareCanvas.fillRect(c: c, l: 0, t: 0, r: w, b: h, color: ShareCanvas.deep)
        ShareCanvas.drawFill(c: c, image: images.art, rect: rect)

        let deep = ShareCanvas.deep
        ShareCanvas.gradient(
            c: c,
            stops: [
                (0, ShareCanvas.withAlpha(deep, 0.12)),
                (0.38, ShareCanvas.withAlpha(deep, 0.35)),
                (0.58, ShareCanvas.withAlpha(deep, 0.90)),
                (1, ShareCanvas.withAlpha(deep, 0.97))
            ],
            start: .zero,
            end: CGPoint(x: w, y: 0),
            rect: rect
        )

        // Selo do veredito (canto inferior esquerdo)
        let tone = ShareCanvas.toneColor(scene.tone)
        let verdict = scene.headline.uppercased()
        let vw = ShareCanvas.width(verdict, size: 20, weight: .semibold, kern: 2.5, mono: true)
        let pill = CGRect(x: 56, y: 518, width: 18 + 16 + 14 + vw + 22, height: 56)

        ShareCanvas.roundRect(c: c, rect: pill, radius: 28, color: ShareCanvas.withAlpha(deep, 0.72))
        ShareCanvas.roundRect(c: c, rect: pill, radius: 28, color: ShareCanvas.withAlpha(UIColor.white, 0.14), stroke: true)
        ShareCanvas.circle(c: c, cx: 56 + 18 + 8, cy: 546, r: 8, color: tone, glow: 18)
        ShareCanvas.draw(c: c, text: verdict, x: 56 + 18 + 16 + 14, y: 554, size: 20, weight: .semibold, color: tone, kern: 2.5, mono: true)

        // Coluna direita
        let left: CGFloat = 610
        let right: CGFloat = w - 60
        ShareCanvas.drawImage(c: c, image: images.wordmark, height: 44, x: left, y: 60)
        ShareCanvas.draw(c: c, text: "lagcheck.signallq.com", x: right, y: 88, size: 20, weight: .medium, color: ShareCanvas.muted, align: .right, shadow: true, mono: true)

        let lines = ShareCanvas.wrap(headlineSentence(scene: scene), size: 60, weight: .bold, kern: -2, maxWidth: right - left)
        let lh: CGFloat = 62
        let blockH = 19 + 12 + CGFloat(lines.count) * lh + 28 + 90
        let top = 104 + (458 - 104 - blockH) / 2

        ShareCanvas.draw(c: c, text: eyebrow(scene: scene), x: left, y: top + 15, size: 19, weight: .semibold, color: ShareCanvas.accent, kern: 3, shadow: true, mono: true)
        for (i, line) in lines.enumerated() {
            ShareCanvas.draw(c: c, text: line, x: left, y: top + 31 + 60 * 0.85 + CGFloat(i) * lh, size: 60, weight: .bold, color: ShareCanvas.text, kern: -2, shadow: true)
        }

        let my = top + 31 + CGFloat(lines.count) * lh + 28 + 17
        let colW = (right - left - 40) / 3
        let style = MetricStyle(border: 2, pad: 20, label: 17, value: 56, unit: 22, gap: 6, height: 88)
        for (i, m) in scene.metrics.enumerated() {
            drawMetric(c: c, metric: m, x: left + CGFloat(i) * (colW + 20), y: my, k: style)
        }

        // Linha inferior: QR da App Store + chamada honesta + selo App Store
        ShareCanvas.drawQr(c: c, url: ShareMediaImages.STORE_URL, rect: CGRect(x: left, y: 458, width: 112, height: 112), radius: 16, padding: 8)
        let udpProof = AppLocalization.string("share.card.udp_proof", comment: "")
        let testCta = AppLocalization.string("share.card.cta", comment: "")
        ShareCanvas.draw(c: c, text: udpProof.isEmpty ? "Medido com pacotes UDP reais." : udpProof, x: left + 134, y: 494, size: 23, weight: .medium, color: ShareCanvas.muted)
        ShareCanvas.draw(c: c, text: testCta.isEmpty ? "Teste a sua conexão no Lagcheck." : testCta, x: left + 134, y: 524, size: 23, weight: .semibold, color: ShareCanvas.text)
        ShareCanvas.drawAppStoreBadge(c: c, height: 38, x: left + 130, y: 532)
    }

    // ---- 1b · Vertical 1080x1920 ----
    public static func drawStory(c: CGContext, scene: ShareMediaScene, images: ShareMediaImages) {
        let w = STORY_W
        let h = STORY_H
        let rect = CGRect(x: 0, y: 0, width: w, height: h)

        ShareCanvas.fillRect(c: c, l: 0, t: 0, r: w, b: h, color: ShareCanvas.deep)
        ShareCanvas.drawFill(c: c, image: images.art, rect: rect)

        let deep = ShareCanvas.deep
        ShareCanvas.gradient(
            c: c,
            stops: [
                (0, ShareCanvas.withAlpha(deep, 0.70)),
                (0.22, ShareCanvas.withAlpha(deep, 0.05)),
                (0.34, ShareCanvas.withAlpha(deep, 0.20)),
                (0.55, ShareCanvas.withAlpha(deep, 0.88)),
                (1, ShareCanvas.withAlpha(deep, 0.97))
            ],
            start: .zero,
            end: CGPoint(x: 0, y: h),
            rect: rect
        )
        ShareCanvas.drawImage(c: c, image: images.wordmark, height: 60, x: 64, y: 240)
        drawVerdictBlock(c: c, scene: scene, images: images, top: 830, alpha: 1, reveal: 1, width: w)
    }

    /// Bloco de veredito da vertical (selo, título, métricas, chamada, selo da App Store);
    /// usado também na cena final do vídeo.
    public static func drawVerdictBlock(
        c: CGContext,
        scene: ShareMediaScene,
        images: ShareMediaImages,
        top: CGFloat,
        alpha: CGFloat,
        reveal: CGFloat,
        width: CGFloat,
        valueOverrides: [String]? = nil
    ) {
        let side: CGFloat = 64
        let tone = ShareCanvas.toneColor(scene.tone)
        ShareCanvas.circle(c: c, cx: side + 13, cy: top + 15, r: 13, color: ShareCanvas.withAlpha(tone, alpha), glow: 28)
        ShareCanvas.draw(
            c: c,
            text: "CHECK · \(scene.gameName)".uppercased(),
            x: side + 54,
            y: top + 26,
            size: 30,
            weight: .semibold,
            color: tone,
            kern: 4,
            shadow: true,
            alpha: alpha,
            mono: true
        )

        var fontSize: CGFloat = 112
        var lines = ShareCanvas.wrap(headlineSentence(scene: scene), size: fontSize, weight: .bold, kern: -4, maxWidth: width - side * 2)
        if lines.count > 2 {
            fontSize = 88
            lines = ShareCanvas.wrap(headlineSentence(scene: scene), size: fontSize, weight: .bold, kern: -3, maxWidth: width - side * 2)
        }
        let firstY = top + 22 + 30 + fontSize * 0.9
        for (i, line) in lines.prefix(3).enumerated() {
            ShareCanvas.draw(
                c: c,
                text: line,
                x: side,
                y: firstY + CGFloat(i) * fontSize,
                size: fontSize,
                weight: .bold,
                color: ShareCanvas.text,
                kern: -fontSize / 28,
                shadow: true,
                alpha: alpha
            )
        }

        let my = firstY + CGFloat(min(lines.count, 3) - 1) * fontSize + 48 + 26
        let colW = (width - side * 2 - 56) / 3
        let style = MetricStyle(border: 3, pad: 26, label: 26, value: 88, unit: 30, gap: 8, height: 134)
        for (i, m) in scene.metrics.enumerated() {
            let a = alpha * max(0, min(1, reveal * 3 - CGFloat(i) * 0.5))
            let ov = valueOverrides != nil && i < valueOverrides!.count ? valueOverrides![i] : nil
            drawMetric(c: c, metric: m, x: side + CGFloat(i) * (colW + 28), y: my, k: style, valueOverride: ov, alpha: a)
        }

        let by = my + 88 + 54 - 16
        ShareCanvas.drawAppStoreBadge(c: c, height: 104, x: side - 8, y: by - 4, alpha: alpha)
        let tx = side + 104 * 2.58 + 28
        let udpProof = AppLocalization.string("share.card.udp_proof", comment: "")
        let testCta = AppLocalization.string("share.card.cta", comment: "")
        ShareCanvas.draw(
            c: c,
            text: udpProof.isEmpty ? "Medido com pacotes UDP reais." : udpProof,
            x: tx,
            y: by + 38,
            size: 32,
            weight: .medium,
            color: ShareCanvas.muted,
            alpha: alpha
        )
        ShareCanvas.draw(
            c: c,
            text: testCta.isEmpty ? "Teste a sua conexão no Lagcheck." : testCta,
            x: tx,
            y: by + 80,
            size: 32,
            weight: .semibold,
            color: ShareCanvas.text,
            alpha: alpha
        )
    }
}
