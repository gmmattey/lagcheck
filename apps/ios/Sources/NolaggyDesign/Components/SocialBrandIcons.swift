import SwiftUI

/// Ícone vetorial autêntico do Discord (Clyde).
public struct DiscordLogo: View {
    public var size: CGFloat
    public var color: Color

    public init(size: CGFloat = 16, color: Color = NLBrandColor.discord) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let scaleX = canvasSize.width / 24.0
            let scaleY = canvasSize.height / 24.0
            var path = Path()

            // Silhueta do Discord Clyde normalizada para viewBox 0 0 24 24
            path.move(to: CGPoint(x: 19.54 * scaleX, y: 4.68 * scaleY))
            path.addCurve(
                to: CGPoint(x: 14.85 * scaleX, y: 3.23 * scaleY),
                control1: CGPoint(x: 18.06 * scaleX, y: 4.0 * scaleY),
                control2: CGPoint(x: 16.48 * scaleX, y: 3.51 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 14.24 * scaleX, y: 4.46 * scaleY),
                control1: CGPoint(x: 14.64 * scaleX, y: 3.6 * scaleY),
                control2: CGPoint(x: 14.41 * scaleX, y: 4.07 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 9.76 * scaleX, y: 4.46 * scaleY),
                control1: CGPoint(x: 12.78 * scaleX, y: 4.24 * scaleY),
                control2: CGPoint(x: 11.22 * scaleX, y: 4.24 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 9.15 * scaleX, y: 3.23 * scaleY),
                control1: CGPoint(x: 8.98 * scaleX, y: 4.07 * scaleY),
                control2: CGPoint(x: 8.75 * scaleX, y: 3.6 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 4.46 * scaleX, y: 4.68 * scaleY),
                control1: CGPoint(x: 7.52 * scaleX, y: 3.51 * scaleY),
                control2: CGPoint(x: 5.94 * scaleX, y: 4.0 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 1.45 * scaleX, y: 17.81 * scaleY),
                control1: CGPoint(x: 1.41 * scaleX, y: 9.13 * scaleY),
                control2: CGPoint(x: 0.61 * scaleX, y: 13.48 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 7.2 * scaleX, y: 20.77 * scaleY),
                control1: CGPoint(x: 3.19 * scaleX, y: 19.09 * scaleY),
                control2: CGPoint(x: 5.17 * scaleX, y: 20.77 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 8.38 * scaleX, y: 18.82 * scaleY),
                control1: CGPoint(x: 7.64 * scaleX, y: 20.17 * scaleY),
                control2: CGPoint(x: 8.04 * scaleX, y: 19.51 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 6.58 * scaleX, y: 17.95 * scaleY),
                control1: CGPoint(x: 7.75 * scaleX, y: 18.58 * scaleY),
                control2: CGPoint(x: 7.15 * scaleX, y: 18.29 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 6.94 * scaleX, y: 17.67 * scaleY),
                control1: CGPoint(x: 6.7 * scaleX, y: 17.86 * scaleY),
                control2: CGPoint(x: 6.82 * scaleX, y: 17.76 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 17.06 * scaleX, y: 17.67 * scaleY),
                control1: CGPoint(x: 10.22 * scaleX, y: 19.22 * scaleY),
                control2: CGPoint(x: 13.78 * scaleX, y: 19.22 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 17.42 * scaleX, y: 17.95 * scaleY),
                control1: CGPoint(x: 17.18 * scaleX, y: 17.76 * scaleY),
                control2: CGPoint(x: 17.3 * scaleX, y: 17.86 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 15.62 * scaleX, y: 18.82 * scaleY),
                control1: CGPoint(x: 16.85 * scaleX, y: 18.29 * scaleY),
                control2: CGPoint(x: 16.25 * scaleX, y: 18.58 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 16.8 * scaleX, y: 20.77 * scaleY),
                control1: CGPoint(x: 15.96 * scaleX, y: 19.51 * scaleY),
                control2: CGPoint(x: 16.36 * scaleX, y: 20.17 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 22.55 * scaleX, y: 17.81 * scaleY),
                control1: CGPoint(x: 18.83 * scaleX, y: 20.77 * scaleY),
                control2: CGPoint(x: 20.81 * scaleX, y: 19.09 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 19.54 * scaleX, y: 4.68 * scaleY),
                control1: CGPoint(x: 23.49 * scaleX, y: 13.43 * scaleY),
                control2: CGPoint(x: 22.59 * scaleX, y: 9.13 * scaleY)
            )
            path.closeSubpath()

            // Olhos do Clyde (vazados)
            let eyeY = 12.5 * scaleY
            let eyeRadius = 1.6 * scaleX
            path.addEllipse(in: CGRect(x: 8.5 * scaleX - eyeRadius, y: eyeY - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2))
            path.addEllipse(in: CGRect(x: 15.5 * scaleX - eyeRadius, y: eyeY - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2))

            context.fill(path, with: .color(color), style: FillStyle(eoFill: true))
        }
        .frame(width: size, height: size)
    }
}

/// Ícone vetorial autêntico do WhatsApp (Simple Icons, CC0; viewBox 24x24, paridade 1:1 com Android).
public struct WhatsAppLogo: View {
    public var size: CGFloat
    public var color: Color

    public init(size: CGFloat = 16, color: Color = NLBrandColor.whatsapp) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        SVGVectorLogo(svgPath: SocialBrandPaths.whatsapp, size: size, color: color)
    }
}

/// Ícone vetorial autêntico do Telegram (Simple Icons, CC0; viewBox 24x24, paridade 1:1 com Android).
public struct TelegramLogo: View {
    public var size: CGFloat
    public var color: Color

    public init(size: CGFloat = 16, color: Color = NLBrandColor.telegram) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        SVGVectorLogo(svgPath: SocialBrandPaths.telegram, size: size, color: color)
    }
}

/// Ícone vetorial autêntico do X (Simple Icons, CC0; viewBox 24x24, paridade 1:1 com Android).
public struct XLogo: View {
    public var size: CGFloat
    public var color: Color

    public init(size: CGFloat = 16, color: Color = NLBrandColor.x) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        SVGVectorLogo(svgPath: SocialBrandPaths.x, size: size, color: color)
    }
}

/// Ícone vetorial autêntico do TikTok (Simple Icons, CC0; viewBox 24x24, paridade 1:1 com Android).
public struct TikTokLogo: View {
    public var size: CGFloat
    public var color: Color

    public init(size: CGFloat = 16, color: Color = NLBrandColor.tiktok) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        SVGVectorLogo(svgPath: SocialBrandPaths.tiktok, size: size, color: color)
    }
}

/// Ícone vetorial autêntico do Instagram (Simple Icons, CC0; viewBox 24x24, paridade 1:1 com Android).
public struct InstagramLogo: View {
    public var size: CGFloat
    public var color: Color

    public init(size: CGFloat = 16, color: Color = NLBrandColor.instagram) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        SVGVectorLogo(svgPath: SocialBrandPaths.instagram, size: size, color: color)
    }
}

private struct SVGVectorLogo: View {
    let svgPath: String
    let size: CGFloat
    let color: Color

    var body: some View {
        Canvas { context, canvasSize in
            let scaleX = canvasSize.width / 24.0
            let scaleY = canvasSize.height / 24.0
            var path = SVGPathParser.parse(svgPath)
            path = path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
            context.fill(path, with: .color(color), style: FillStyle(eoFill: true))
        }
        .frame(width: size, height: size)
    }
}

public enum SocialBrandPaths {
    public static let whatsapp = "M 17.472 14.382 c -.297 -.149 -1.758 -.867 -2.03 -.967 -.273 -.099 -.471 -.148 -.67 .15 -.197 .297 -.767 .966 -.94 1.164 -.173 .199 -.347 .223 -.644 .075 -.297 -.15 -1.255 -.463 -2.39 -1.475 -.883 -.788 -1.48 -1.761 -1.653 -2.059 -.173 -.297 -.018 -.458 .13 -.606 .134 -.133 .298 -.347 .446 -.52 .149 -.174 .198 -.298 .298 -.497 .099 -.198 .05 -.371 -.025 -.52 -.075 -.149 -.669 -1.612 -.916 -2.207 -.242 -.579 -.487 -.5 -.669 -.51 -.173 -.008 -.371 -.01 -.57 -.01 -.198 0 -.52 .074 -.792 .372 -.272 .297 -1.04 1.016 -1.04 2.479 0 1.462 1.065 2.875 1.213 3.074 .149 .198 2.096 3.2 5.077 4.487 .709 .306 1.262 .489 1.694 .625 .712 .227 1.36 .195 1.871 .118 .571 -.085 1.758 -.719 2.006 -1.413 .248 -.694 .248 -1.289 .173 -1.413 -.074 -.124 -.272 -.198 -.57 -.347 m -5.421 7.403 h -.004 a 9.87 9.87 0 0 1 -5.031 -1.378 l -.361 -.214 -3.741 .982 .998 -3.648 -.235 -.374 a 9.86 9.86 0 0 1 -1.51 -5.26 c .001 -5.45 4.436 -9.884 9.888 -9.884 2.64 0 5.122 1.03 6.988 2.898 a 9.825 9.825 0 0 1 2.893 6.994 c -.003 5.45 -4.437 9.884 -9.885 9.884 m 8.413 -18.297 A 11.815 11.815 0 0 0 12.05 0 C 5.495 0 .16 5.335 .157 11.892 c 0 2.096 .547 4.142 1.588 5.945 L .057 24 l 6.305 -1.654 a 11.882 11.882 0 0 0 5.683 1.448 h .005 c 6.554 0 11.89 -5.335 11.893 -11.893 a 11.821 11.821 0 0 0 -3.48 -8.413 Z"
    public static let telegram = "M 11.944 0 A 12 12 0 0 0 0 12 a 12 12 0 0 0 12 12 12 12 0 0 0 12 -12 A 12 12 0 0 0 12 0 a 12 12 0 0 0 -.056 0 z m 4.962 7.224 c .1 -.002 .321 .023 .465 .14 a .506 .506 0 0 1 .171 .325 c .016 .093 .036 .306 .02 .472 -.18 1.898 -.962 6.502 -1.36 8.627 -.168 .9 -.499 1.201 -.82 1.23 -.696 .065 -1.225 -.46 -1.9 -.902 -1.056 -.693 -1.653 -1.124 -2.678 -1.8 -1.185 -.78 -.417 -1.21 .258 -1.91 .177 -.184 3.247 -2.977 3.307 -3.23 .007 -.032 .014 -.15 -.056 -.212 s -.174 -.041 -.249 -.024 c -.106 .024 -1.793 1.14 -5.061 3.345 -.48 .33 -.913 .49 -1.302 .48 -.428 -.008 -1.252 -.241 -1.865 -.44 -.752 -.245 -1.349 -.374 -1.297 -.789 .027 -.216 .325 -.437 .893 -.663 3.498 -1.524 5.83 -2.529 6.998 -3.014 3.332 -1.386 4.025 -1.627 4.476 -1.635 z"
    public static let x = "M 14.234 10.162 22.977 0 h -2.072 l -7.591 8.824 L 7.251 0 H .258 l 9.168 13.343 L .258 24 H 2.33 l 8.016 -9.318 L 16.749 24 h 6.993 z m -2.837 3.299 -.929 -1.329 L 3.076 1.56 h 3.182 l 5.965 8.532 .929 1.329 7.754 11.09 h -3.182 z"
    public static let tiktok = "M 12.525 .02 c 1.31 -.02 2.61 -.01 3.91 -.02 .08 1.53 .63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79 v 4.03 c -1.44 -.05 -2.89 -.35 -4.2 -.97 -.57 -.26 -1.1 -.59 -1.62 -.93 -.01 2.92 .01 5.84 -.02 8.75 -.08 1.4 -.54 2.79 -1.35 3.94 -1.31 1.92 -3.58 3.17 -5.91 3.21 -1.43 .08 -2.86 -.31 -4.08 -1.03 -2.02 -1.19 -3.44 -3.37 -3.65 -5.71 -.02 -.5 -.03 -1 -.01 -1.49 .18 -1.9 1.12 -3.72 2.58 -4.96 1.66 -1.44 3.98 -2.13 6.15 -1.72 .02 1.48 -.04 2.96 -.04 4.44 -.99 -.32 -2.15 -.23 -3.02 .37 -.63 .41 -1.11 1.04 -1.36 1.75 -.21 .51 -.15 1.07 -.14 1.61 .24 1.64 1.82 3.02 3.5 2.87 1.12 -.01 2.19 -.66 2.77 -1.61 .19 -.33 .4 -.67 .41 -1.06 .1 -1.79 .06 -3.57 .07 -5.36 .01 -4.03 -.01 -8.05 .02 -12.07 z"
    public static let instagram = "M 7.0301 .084 c -1.2768 .0602 -2.1487 .264 -2.911 .5634 -.7888 .3075 -1.4575 .72 -2.1228 1.3877 -.6652 .6677 -1.075 1.3368 -1.3802 2.127 -.2954 .7638 -.4956 1.6365 -.552 2.914 -.0564 1.2775 -.0689 1.6882 -.0626 4.947 .0062 3.2586 .0206 3.6671 .0825 4.9473 .061 1.2765 .264 2.1482 .5635 2.9107 .308 .7889 .72 1.4573 1.388 2.1228 .6679 .6655 1.3365 1.0743 2.1285 1.38 .7632 .295 1.6361 .4961 2.9134 .552 1.2773 .056 1.6884 .069 4.9462 .0627 3.2578 -.0062 3.668 -.0207 4.9478 -.0814 1.28 -.0607 2.147 -.2652 2.9098 -.5633 .7889 -.3086 1.4578 -.72 2.1228 -1.3881 .665 -.6682 1.0745 -1.3378 1.3795 -2.1284 .2957 -.7632 .4966 -1.636 .552 -2.9124 .056 -1.2809 .0692 -1.6898 .063 -4.948 -.0063 -3.2583 -.021 -3.6668 -.0817 -4.9465 -.0607 -1.2797 -.264 -2.1487 -.5633 -2.9117 -.3084 -.7889 -.72 -1.4568 -1.3876 -2.1228 C 21.2982 1.33 20.628 .9208 19.8378 .6165 19.074 .321 18.2017 .1197 16.9244 .0645 15.6471 .0093 15.236 -.005 11.977 .0014 8.718 .0076 8.31 .0215 7.0301 .0839 m .1402 21.6932 c -1.17 -.0509 -1.8053 -.2453 -2.2287 -.408 -.5606 -.216 -.96 -.4771 -1.3819 -.895 -.422 -.4178 -.6811 -.8186 -.9 -1.378 -.1644 -.4234 -.3624 -1.058 -.4171 -2.228 -.0595 -1.2645 -.072 -1.6442 -.079 -4.848 -.007 -3.2037 .0053 -3.583 .0607 -4.848 .05 -1.169 .2456 -1.805 .408 -2.2282 .216 -.5613 .4762 -.96 .895 -1.3816 .4188 -.4217 .8184 -.6814 1.3783 -.9003 .423 -.1651 1.0575 -.3614 2.227 -.4171 1.2655 -.06 1.6447 -.072 4.848 -.079 3.2033 -.007 3.5835 .005 4.8495 .0608 1.169 .0508 1.8053 .2445 2.228 .408 .5608 .216 .96 .4754 1.3816 .895 .4217 .4194 .6816 .8176 .9005 1.3787 .1653 .4217 .3617 1.056 .4169 2.2263 .0602 1.2655 .0739 1.645 .0796 4.848 .0058 3.203 -.0055 3.5834 -.061 4.848 -.051 1.17 -.245 1.8055 -.408 2.2294 -.216 .5604 -.4763 .96 -.8954 1.3814 -.419 .4215 -.8181 .6811 -1.3783 .9 -.4224 .1649 -1.0577 .3617 -2.2262 .4174 -1.2656 .0595 -1.6448 .072 -4.8493 .079 -3.2045 .007 -3.5825 -.006 -4.848 -.0608 M 16.953 5.5864 A 1.44 1.44 0 1 0 18.39 4.144 a 1.44 1.44 0 0 0 -1.437 1.4424 M 5.8385 12.012 c .0067 3.4032 2.7706 6.1557 6.173 6.1493 3.4026 -.0065 6.157 -2.7701 6.1506 -6.1733 -.0065 -3.4032 -2.771 -6.1565 -6.174 -6.1498 -3.403 .0067 -6.156 2.771 -6.1496 6.1738 M 8 12.0077 a 4 4 0 1 1 4.008 3.9921 A 3.9996 3.9996 0 0 1 8 12.0077"
}

public enum SVGPathParser {
    public static func parse(_ d: String) -> Path {
        var path = Path()
        let chars = Array(d.unicodeScalars)
        var i = 0
        let n = chars.count
        var cmd: Character = " "
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastCubicControl: CGPoint? = nil

        func skipSeparators() {
            while i < n {
                let c = chars[i]
                if c == " " || c == "\t" || c == "\n" || c == "\r" || c == "," {
                    i += 1
                } else {
                    break
                }
            }
        }

        func isCommand(_ scalar: UnicodeScalar) -> Bool {
            let v = scalar.value
            return (v >= 65 && v <= 90) || (v >= 97 && v <= 122)
        }

        func hasMoreNumbers() -> Bool {
            skipSeparators()
            guard i < n else { return false }
            let c = chars[i]
            if c == "e" || c == "E" { return false }
            return !isCommand(c)
        }

        func nextNumber() -> Double? {
            skipSeparators()
            guard i < n else { return nil }
            let start = i
            if chars[i] == "+" || chars[i] == "-" {
                i += 1
            }
            var seenDot = false
            var seenDigits = false
            while i < n {
                let c = chars[i]
                if c >= "0" && c <= "9" {
                    seenDigits = true
                    i += 1
                } else if c == "." && !seenDot {
                    seenDot = true
                    i += 1
                } else {
                    break
                }
            }
            guard seenDigits else {
                i = start
                return nil
            }
            if i < n && (chars[i] == "e" || chars[i] == "E") {
                i += 1
                if i < n && (chars[i] == "+" || chars[i] == "-") { i += 1 }
                while i < n && chars[i] >= "0" && chars[i] <= "9" { i += 1 }
            }
            return Double(String(String.UnicodeScalarView(chars[start..<i])))
        }

        func nextFlag() -> Bool? {
            skipSeparators()
            guard i < n else { return nil }
            let c = chars[i]
            if c == "0" { i += 1; return false }
            if c == "1" { i += 1; return true }
            return nil
        }

        while true {
            skipSeparators()
            guard i < n else { break }
            if isCommand(chars[i]) {
                cmd = Character(chars[i])
                i += 1
            }

            switch cmd {
            case "M", "m":
                let relative = (cmd == "m")
                guard let x = nextNumber(), let y = nextNumber() else { return path }
                let p = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                path.move(to: p)
                current = p
                subpathStart = p
                lastCubicControl = nil
                cmd = relative ? "l" : "L"
                while hasMoreNumbers(), let lx = nextNumber(), let ly = nextNumber() {
                    let np = relative ? CGPoint(x: current.x + lx, y: current.y + ly) : CGPoint(x: lx, y: ly)
                    path.addLine(to: np)
                    current = np
                }

            case "L", "l":
                let relative = (cmd == "l")
                while hasMoreNumbers(), let x = nextNumber(), let y = nextNumber() {
                    let p = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                    path.addLine(to: p)
                    current = p
                    lastCubicControl = nil
                }

            case "H", "h":
                let relative = (cmd == "h")
                while hasMoreNumbers(), let x = nextNumber() {
                    let nx = relative ? current.x + x : x
                    let p = CGPoint(x: nx, y: current.y)
                    path.addLine(to: p)
                    current = p
                    lastCubicControl = nil
                }

            case "V", "v":
                let relative = (cmd == "v")
                while hasMoreNumbers(), let y = nextNumber() {
                    let ny = relative ? current.y + y : y
                    let p = CGPoint(x: current.x, y: ny)
                    path.addLine(to: p)
                    current = p
                    lastCubicControl = nil
                }

            case "C", "c":
                let relative = (cmd == "c")
                while hasMoreNumbers(),
                      let x1 = nextNumber(), let y1 = nextNumber(),
                      let x2 = nextNumber(), let y2 = nextNumber(),
                      let x = nextNumber(), let y = nextNumber() {
                    let c1 = relative ? CGPoint(x: current.x + x1, y: current.y + y1) : CGPoint(x: x1, y: y1)
                    let c2 = relative ? CGPoint(x: current.x + x2, y: current.y + y2) : CGPoint(x: x2, y: y2)
                    let p = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                    path.addCurve(to: p, control1: c1, control2: c2)
                    lastCubicControl = c2
                    current = p
                }

            case "S", "s":
                let relative = (cmd == "s")
                while hasMoreNumbers(),
                      let x2 = nextNumber(), let y2 = nextNumber(),
                      let x = nextNumber(), let y = nextNumber() {
                    let c1: CGPoint
                    if let prev = lastCubicControl {
                        c1 = CGPoint(x: 2 * current.x - prev.x, y: 2 * current.y - prev.y)
                    } else {
                        c1 = current
                    }
                    let c2 = relative ? CGPoint(x: current.x + x2, y: current.y + y2) : CGPoint(x: x2, y: y2)
                    let p = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                    path.addCurve(to: p, control1: c1, control2: c2)
                    lastCubicControl = c2
                    current = p
                }

            case "A", "a":
                let relative = (cmd == "a")
                while hasMoreNumbers(),
                      let rx = nextNumber(), let ry = nextNumber(),
                      let angle = nextNumber(),
                      let largeArc = nextFlag(), let sweep = nextFlag(),
                      let x = nextNumber(), let y = nextNumber() {
                    let p = relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
                    addSVGArc(to: &path, from: current, to: p, rx: rx, ry: ry, xAxisRotationDeg: angle, largeArc: largeArc, sweep: sweep)
                    current = p
                    lastCubicControl = nil
                }

            case "Z", "z":
                path.closeSubpath()
                current = subpathStart
                lastCubicControl = nil

            default:
                return path
            }
        }
        return path
    }

    /// W3C SVG elliptical arc parameterization converted into cubic Bezier segments.
    private static func addSVGArc(
        to path: inout Path,
        from p0: CGPoint,
        to p1: CGPoint,
        rx rawRx: Double,
        ry rawRy: Double,
        xAxisRotationDeg: Double,
        largeArc: Bool,
        sweep: Bool
    ) {
        if p0 == p1 { return }
        var rx = abs(rawRx)
        var ry = abs(rawRy)
        if rx == 0 || ry == 0 {
            path.addLine(to: p1)
            return
        }

        let phi = xAxisRotationDeg * .pi / 180.0
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)

        let dx2 = (Double(p0.x) - Double(p1.x)) / 2.0
        let dy2 = (Double(p0.y) - Double(p1.y)) / 2.0
        let x1p = cosPhi * dx2 + sinPhi * dy2
        let y1p = -sinPhi * dx2 + cosPhi * dy2

        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1.0 {
            let s = sqrt(lambda)
            rx *= s
            ry *= s
        }

        let rx2 = rx * rx
        let ry2 = ry * ry
        let x1p2 = x1p * x1p
        let y1p2 = y1p * y1p

        let num = max(0.0, rx2 * ry2 - rx2 * y1p2 - ry2 * x1p2)
        let den = rx2 * y1p2 + ry2 * x1p2
        let factor = den == 0 ? 0.0 : sqrt(num / den) * (largeArc == sweep ? -1.0 : 1.0)
        let cxp = factor * (rx * y1p) / ry
        let cyp = factor * -(ry * x1p) / rx

        let cx = cosPhi * cxp - sinPhi * cyp + (Double(p0.x) + Double(p1.x)) / 2.0
        let cy = sinPhi * cxp + cosPhi * cyp + (Double(p0.y) + Double(p1.y)) / 2.0

        func vecAngle(ux: Double, uy: Double, vx: Double, vy: Double) -> Double {
            let dot = ux * vx + uy * vy
            let len = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
            let cosVal = max(-1.0, min(1.0, len == 0 ? 1.0 : dot / len))
            let sign = (ux * vy - uy * vx) < 0 ? -1.0 : 1.0
            return sign * acos(cosVal)
        }

        let ux = (x1p - cxp) / rx
        let uy = (y1p - cyp) / ry
        let vx = (-x1p - cxp) / rx
        let vy = (-y1p - cyp) / ry

        let theta1 = vecAngle(ux: 1.0, uy: 0.0, vx: ux, vy: uy)
        var dTheta = vecAngle(ux: ux, uy: uy, vx: vx, vy: vy)
        if !sweep && dTheta > 0 { dTheta -= 2.0 * .pi }
        if sweep && dTheta < 0 { dTheta += 2.0 * .pi }

        let segments = max(1, Int(ceil(abs(dTheta) / (.pi / 2.0))))
        let delta = dTheta / Double(segments)
        let alpha = (4.0 / 3.0) * tan(delta / 4.0)

        for seg in 0..<segments {
            let t1 = theta1 + Double(seg) * delta
            let t2 = t1 + delta

            let cosT1 = cos(t1), sinT1 = sin(t1)
            let cosT2 = cos(t2), sinT2 = sin(t2)

            let e1x = cosT1 - alpha * sinT1
            let e1y = sinT1 + alpha * cosT1
            let e2x = cosT2 + alpha * sinT2
            let e2y = sinT2 - alpha * cosT2

            func mapPoint(_ px: Double, _ py: Double) -> CGPoint {
                let sx = rx * px
                let sy = ry * py
                return CGPoint(
                    x: cx + cosPhi * sx - sinPhi * sy,
                    y: cy + sinPhi * sx + cosPhi * sy
                )
            }

            let cp1 = mapPoint(e1x, e1y)
            let cp2 = mapPoint(e2x, e2y)
            let endPt = (seg == segments - 1) ? p1 : mapPoint(cosT2, sinT2)
            path.addCurve(to: endPt, control1: cp1, control2: cp2)
        }
    }
}
