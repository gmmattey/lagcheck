import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Tela ao vivo do Quick Check (doc 01 §7.3): latência atual, gráfico vivo,
/// perda e spikes acumulados. Nenhum valor parcial aqui recebe score ou conclusão.
extension QuickCheckFeatureView {
    var measurementView: some View {
        VStack(spacing: NLSpacing.lg) {
            Spacer(minLength: NLSpacing.xs)

            MeasurementLiveTrail(
                isWiFi: (context?.equipmentConnection ?? .wifi) == .wifi,
                destinationName: selectedRegionFriendlyName,
                currentRTT: observedMetrics.currentRTTValue,
                progress: Double(partialSamples.count) / Double(ProbeAcceptancePolicy.plannedProbeCount),
                sampleCount: partialSamples.count,
                lossCount: observedMetrics.lossCount,
                isUnderStress: false,
                stressLocation: .none,
                phaseTitle: "quick_check.measuring.phase",
                phaseSubtitle: LocalizedStringKey(selectedGameName)
            )

            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NolaggyBackButton(action: back, accessibilityIdentifier: "quick-check-back")
            }
        }
    }

    var observedMetrics: ObservedMeasurementMetrics {
        ObservedMeasurementMetrics(samples: partialSamples)
    }
}

struct ObservedMeasurementMetrics {
    let samples: [ProbeSample]

    var rtts: [Double] { samples.compactMap(\.roundTripMilliseconds) }

    var currentRTTValue: Double? { rtts.last }

    var currentRTT: String? {
        guard let last = rtts.last else { return nil }
        return "\(Int(last.rounded())) ms"
    }

    var lossCount: Int {
        samples.filter { $0.outcome == .timeout || $0.outcome == .transportError }.count
    }

    var loss: String {
        guard !samples.isEmpty else { return "—" }
        return "\(lossCount)"
    }

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
