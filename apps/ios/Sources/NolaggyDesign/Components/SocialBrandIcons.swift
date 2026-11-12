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

/// Ícone vetorial autêntico do WhatsApp.
public struct WhatsAppLogo: View {
    public var size: CGFloat
    public var color: Color

    public init(size: CGFloat = 16, color: Color = NLBrandColor.whatsapp) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let scaleX = canvasSize.width / 24.0
            let scaleY = canvasSize.height / 24.0
            var path = Path()

            // Balão de fala com ponta
            path.move(to: CGPoint(x: 12.0 * scaleX, y: 2.0 * scaleY))
            path.addCurve(
                to: CGPoint(x: 3.5 * scaleX, y: 18.0 * scaleY),
                control1: CGPoint(x: 6.5 * scaleX, y: 2.0 * scaleY),
                control2: CGPoint(x: 2.0 * scaleX, y: 6.5 * scaleY)
            )
            // Rabicho do balão (canto inferior esquerdo)
            path.addLine(to: CGPoint(x: 2.0 * scaleX, y: 22.0 * scaleY))
            path.addLine(to: CGPoint(x: 6.3 * scaleX, y: 20.6 * scaleY))
            path.addCurve(
                to: CGPoint(x: 12.0 * scaleX, y: 22.0 * scaleY),
                control1: CGPoint(x: 8.0 * scaleX, y: 21.5 * scaleY),
                control2: CGPoint(x: 9.9 * scaleX, y: 22.0 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 22.0 * scaleX, y: 12.0 * scaleY),
                control1: CGPoint(x: 17.5 * scaleX, y: 22.0 * scaleY),
                control2: CGPoint(x: 22.0 * scaleX, y: 17.5 * scaleY)
            )
            path.addCurve(
                to: CGPoint(x: 12.0 * scaleX, y: 2.0 * scaleY),
                control1: CGPoint(x: 22.0 * scaleX, y: 6.5 * scaleY),
                control2: CGPoint(x: 17.5 * scaleX, y: 2.0 * scaleY)
            )
            path.closeSubpath()

            // Desenhar monofone interno (vazado)
            var phone = Path()
            phone.move(to: CGPoint(x: 8.5 * scaleX, y: 7.5 * scaleY))
            phone.addCurve(
                to: CGPoint(x: 16.5 * scaleX, y: 15.5 * scaleY),
                control1: CGPoint(x: 8.5 * scaleX, y: 12.5 * scaleY),
                control2: CGPoint(x: 11.5 * scaleX, y: 15.5 * scaleY)
            )
            phone.addLine(to: CGPoint(x: 15.0 * scaleX, y: 17.0 * scaleY))
            phone.addCurve(
                to: CGPoint(x: 7.0 * scaleX, y: 9.0 * scaleY),
                control1: CGPoint(x: 10.0 * scaleX, y: 14.5 * scaleY),
                control2: CGPoint(x: 9.5 * scaleX, y: 14.0 * scaleY)
            )
            phone.closeSubpath()

            path.addPath(phone)
            context.fill(path, with: .color(color), style: FillStyle(eoFill: true))
        }
        .frame(width: size, height: size)
    }
}
