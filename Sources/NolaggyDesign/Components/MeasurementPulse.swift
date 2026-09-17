import SwiftUI
import UIKit

public struct MeasurementPulse: View {
    public enum Phase: String, Sendable { case quick, deepIdle, deepLoad }

    private let phase: Phase
    private let phaseLabel: LocalizedStringKey
    private let progress: Double?
    private let currentRTT: String?
    private let measuringLabel: LocalizedStringKey
    private let currentRTTLabel: LocalizedStringKey
    private let phaseAccessibilityLabel: String
    private let currentRTTAccessibilityLabel: String
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var currentRTTFontSize: CGFloat = 56
    @ScaledMetric(relativeTo: .largeTitle) private var pulseDiameter: CGFloat = NLSizing.measurementPulseDiameter

    public init(
        phase: Phase,
        phaseLabel: LocalizedStringKey,
        progress: Double? = nil,
        currentRTT: String? = nil,
        measuringLabel: LocalizedStringKey,
        currentRTTLabel: LocalizedStringKey,
        phaseAccessibilityLabel: String,
        currentRTTAccessibilityLabel: String
    ) {
        self.phase = phase
        self.phaseLabel = phaseLabel
        self.progress = progress.map { min(max($0, 0), 1) }
        self.currentRTT = currentRTT
        self.measuringLabel = measuringLabel
        self.currentRTTLabel = currentRTTLabel
        self.phaseAccessibilityLabel = phaseAccessibilityLabel
        self.currentRTTAccessibilityLabel = currentRTTAccessibilityLabel
    }

    public var body: some View {
        VStack(spacing: NLSpacing.lg) {
            ZStack {
                Circle()
                    .stroke(NLColor.borderSubtle, lineWidth: NLSizing.measurementPulseStrokeWidth)
                if let progress {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(NLColor.accentPrimary, style: StrokeStyle(lineWidth: NLSizing.measurementPulseStrokeWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                } else {
                    Circle()
                        .trim(from: 0, to: 0.66)
                        .stroke(NLColor.accentPrimary, style: StrokeStyle(lineWidth: NLSizing.measurementPulseStrokeWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                pulseCore
                VStack(spacing: NLSpacing.xxs) {
                    if let currentRTT {
                        Text(currentRTT)
                            .font(.system(size: currentRTTFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(NLColor.textPrimary)
                        Text(currentRTTLabel)
                            .font(NLTypography.footnote)
                            .foregroundStyle(NLColor.textTertiary)
                    } else {
                        Text(measuringLabel)
                            .font(NLTypography.subheadline)
                            .foregroundStyle(NLColor.textPrimary)
                    }
                }
            }
            .frame(width: pulseDiameter, height: pulseDiameter)

            Text(phaseLabel)
                .font(NLTypography.callout)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(phaseAccessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .onAppear {
            guard !isPulsing else { return }
            guard !reduceMotion else {
                isPulsing = true
                return
            }
            withAnimation(NLMotion.measurementPulse) {
                isPulsing = true
            }
        }
        .onChange(of: reduceMotion) { _, isReduced in
            guard isReduced else { return }
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                isPulsing = true
            }
        }
        .onChange(of: accessibilityValue) { oldValue, newValue in
            guard UIAccessibility.isVoiceOverRunning,
                  newValue != oldValue,
                  !newValue.isEmpty else { return }
            UIAccessibility.post(
                notification: .announcement,
                argument: "\(phaseAccessibilityLabel). \(newValue)"
            )
        }
        .onDisappear { isPulsing = false }
    }

    private var pulseCore: some View {
        Circle()
            .fill(NLColor.accentPrimary.opacity(0.16))
            .frame(width: pulseDiameter - NLSpacing.huge, height: pulseDiameter - NLSpacing.huge)
            .scaleEffect(reduceMotion ? 1 : (isPulsing ? 1 : 0.94))
            .opacity(isPulsing ? 1 : 0.64)
    }

    private var accessibilityValue: String {
        currentRTT.map { "\(currentRTTAccessibilityLabel) \($0)" } ?? ""
    }
}

#Preview("Measurement pulse") {
    MeasurementPulse(
        phase: .quick,
        phaseLabel: "Procurando picos de lag…",
        progress: 0.66,
        currentRTT: "24 ms",
        measuringLabel: "Medindo",
        currentRTTLabel: "Ping atual",
        phaseAccessibilityLabel: "Medição em andamento",
        currentRTTAccessibilityLabel: "Ping atual"
    )
        .padding()
        .background(NLColor.backgroundBase)
        .preferredColorScheme(.dark)
}
