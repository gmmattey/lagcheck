import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Tela ao vivo de medição: latência atual, gráfico vivo,
/// perda e spikes acumulados. Nenhum valor parcial aqui recebe score ou conclusão.
extension QuickCheckFeatureView {
    var measurementView: some View {
        VStack(spacing: NLSpacing.lg) {
            // Header in-view canônico com botão único de retorno e contexto do jogo
            HStack {
                Button(action: back) {
                    Image(systemName: "chevron.backward")
                        .font(NLTypography.navigationIcon)
                        .foregroundStyle(NLColor.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("measurement-back")

                Spacer()

                Text(selectedGameName)
                    .font(NLTypography.monospaceMetrics)
                    .foregroundStyle(NLColor.textTertiary)
            }
            .frame(height: 52)

            Spacer(minLength: NLSpacing.xs)

            MeasurementLiveTrail(
                isWiFi: selectedRegionalContext?.observedPhoneNetwork == .wifi,
                destinationName: selectedRegionFriendlyName,
                currentRTT: partialSamples.last?.roundTripMilliseconds,
                progress: min(1.0, max(0.04, Double(partialSamples.count) / 30.0)),
                sampleCount: partialSamples.count,
                isUnderStress: false,
                isPhaseRest: true,
                phaseTitle: "quick_check.measuring.phase",
                phaseSubtitle: LocalizedStringKey(selectedGameName)
            )

            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
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

    var hasSpike: Bool {
        guard rtts.count >= 2, let maxRTT = rtts.max(), let minRTT = rtts.min() else { return false }
        return (maxRTT - minRTT) > 40
    }

    var spikeCount: Int {
        guard rtts.count >= 2, let minRTT = rtts.min() else { return 0 }
        return rtts.filter { ($0 - minRTT) > 40 }.count
    }
}
