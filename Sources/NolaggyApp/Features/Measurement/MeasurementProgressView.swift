import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Tela ao vivo do Quick Check (doc 01 §7.3): latência atual, gráfico vivo,
/// perda e spikes acumulados. Nenhum valor parcial aqui recebe score ou conclusão.
extension QuickCheckFeatureView {
    var measurementView: some View {
        VStack(spacing: NLSpacing.xl) {
            header(title: nil, showsBack: true)
            Spacer(minLength: NLSpacing.xs)
            VStack(spacing: NLSpacing.xs) {
                Text("quick_check.measuring.title")
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                Text(selectedGameName)
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.accentPrimary)
                Label("quick_check.measuring.region", systemImage: "mappin.and.ellipse")
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textTertiary)
            }
            MeasurementPulse(
                phase: .quick,
                phaseLabel: "quick_check.measuring.phase",
                progress: Double(partialSamples.count) / Double(ProbeAcceptancePolicy.plannedProbeCount),
                currentRTT: observedMetrics.currentRTT,
                measuringLabel: "quick_check.measuring.waiting",
                currentRTTLabel: "quick_check.measuring.current_rtt",
                phaseAccessibilityLabel: String(localized: "quick_check.measuring.phase"),
                currentRTTAccessibilityLabel: String(localized: "quick_check.measuring.current_rtt")
            )
            LatencyGraph(
                values: observedMetrics.rtts,
                awaitingLabel: "quick_check.measuring.awaiting_samples",
                accessibilityLabel: String(localized: "quick_check.measuring.latency_graph")
            )
            HStack(spacing: NLSpacing.md) {
                liveMetric(value: observedMetrics.loss, label: "quick_check.measuring.loss")
                liveMetric(value: observedMetrics.spikes, label: "quick_check.measuring.spikes")
            }
            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
    }

    var observedMetrics: ObservedMeasurementMetrics {
        ObservedMeasurementMetrics(samples: partialSamples)
    }

    func liveMetric(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: NLSpacing.xxs) {
            Text(value)
                .font(NLTypography.subheadline)
                .foregroundStyle(NLColor.textPrimary)
            Text(label)
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
    }
}

struct ObservedMeasurementMetrics {
    let samples: [ProbeSample]

    var rtts: [Double] { samples.compactMap(\.roundTripMilliseconds) }

    var currentRTT: String? {
        guard let last = rtts.last else { return nil }
        return "\(Int(last.rounded())) ms"
    }

    // Sem timeout observado, perda permanece desconhecida: a tela nunca presume 0%.
    var loss: String { "—" }

    var spikes: String {
        guard !rtts.isEmpty else { return "—" }
        let sorted = rtts.sorted()
        let position = Double(sorted.count - 1) * 0.5
        let lower = Int(position.rounded(.down))
        let upper = Int(position.rounded(.up))
        let p50 = sorted[lower] + (sorted[upper] - sorted[lower]) * (position - Double(lower))
        return String(rtts.filter { $0 > p50 + 30 && $0 >= 80 }.count)
    }
}
