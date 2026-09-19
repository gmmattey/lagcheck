import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Tela de Resultado do LagCheck (Decisão 35).
/// Implementa o padrão Apple HIG com Hero Editorial, Atestado da Rota,
/// Grid de Métricas 2x2, Diagnóstico de Partida e Ações balanceadas.
struct DeepCheckResultView: View {
    let result: DeepCheckResult
    let availability: DeepCheckLoadAvailability
    let profileID: QualityProfileID
    let gameName: String
    let platform: Platform
    let regionFriendlyName: String
    let isWiFi: Bool
    let showDetails: () -> Void
    let showBooster: () -> Void
    let retry: () -> Void
    let exit: () -> Void

    var body: some View {
        let interpretation = ResultInterpreter.interpret(result.restResult, profile: profileID)
        let isLocalHealthy = (result.metrics.loadImpact?.increaseMilliseconds ?? 0) < 35.0 && interpretation.primaryCauseKey != .highJitter
        let isDestinationHealthy = interpretation.scoreBand == .excellent || interpretation.scoreBand == .great
        let wifiStatusText = isWiFi
            ? (isLocalHealthy
                ? AppLocalization.string("result.route_trail.wifi_healthy", comment: "")
                : AppLocalization.string("result.route_trail.wifi_unstable", comment: ""))
            : AppLocalization.string("result.route_trail.cellular_active", comment: "")
        let pingMs = milliseconds(result.metrics.rest.p50Milliseconds)
        let destinationStatus = String(
            format: AppLocalization.string("result.route_trail.destination_responding %@", comment: ""),
            pingMs
        )
        let scoreColor = scoreToneColor(for: interpretation.scoreBand)

        ScrollView {
            VStack(spacing: NLSpacing.xl) {
                // 1. Hero Editorial HIG (Veredito Imediato)
                VStack(spacing: NLSpacing.sm) {
                    // Pílula semântica: [ 92 · EXCELENTE ]
                    HStack(spacing: NLSpacing.xs) {
                        Text("\(interpretation.score)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("·")
                            .font(.system(size: 15, weight: .bold))
                        Text(localizedKey(interpretation.headlineKey.rawValue))
                            .font(NLTypography.caption.weight(.bold))
                            .textCase(.uppercase)
                    }
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, NLSpacing.sm)
                    .padding(.vertical, NLSpacing.xxs)
                    .background(scoreColor.opacity(0.12), in: Capsule())
                    .overlay { Capsule().stroke(scoreColor.opacity(0.3), lineWidth: 0.5) }

                    // Veredito verbal em destaque
                    Text(localizedKey(interpretation.conclusionKey.rawValue))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(NLColor.textPrimary)
                        .multilineTextAlignment(.center)

                    // Explicação amigável da conexão
                    Text(localizedKey(interpretation.explanationKey.rawValue))
                        .font(NLTypography.callout)
                        .foregroundStyle(NLColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, NLSpacing.sm)

                    // Contexto: Fortnite · iPhone · São Paulo (AWS)
                    Text("\(gameName) · \(platform.displayName) · \(regionFriendlyName)")
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                        .padding(.top, NLSpacing.xxs)
                }
                .frame(maxWidth: .infinity)

                // 2. Atestado da Rota HIG (Trilha Consolidada)
                RouteTrailSummaryCard(
                    isWiFi: isWiFi,
                    wifiStatusText: wifiStatusText,
                    isLocalHealthy: isLocalHealthy,
                    destinationName: regionFriendlyName,
                    destinationStatusText: destinationStatus,
                    isDestinationHealthy: isDestinationHealthy
                )

                // 3. Grid de Métricas 2x2 HIG
                VStack(alignment: .leading, spacing: NLSpacing.xs) {
                    Text(LocalizedStringKey("result.metrics.title"))
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.leading, NLSpacing.xxs)

                    VStack(spacing: NLSpacing.sm) {
                        HStack(spacing: NLSpacing.sm) {
                            metricCard(
                                title: "result.metric.ping",
                                value: pingMs,
                                unit: "ms",
                                isCause: interpretation.primaryCauseKey == .highLatency,
                                causeColor: insightColor(for: interpretation.primaryCauseKey)
                            )
                            metricCard(
                                title: "result.metric.jitter",
                                value: milliseconds(result.metrics.rest.jitterMilliseconds),
                                unit: "ms",
                                isCause: interpretation.primaryCauseKey == .highJitter,
                                causeColor: insightColor(for: interpretation.primaryCauseKey)
                            )
                        }
                        HStack(spacing: NLSpacing.sm) {
                            metricCard(
                                title: "result.metric.loss",
                                value: percentage(result.metrics.rest.packetLossPercentage),
                                unit: nil,
                                isCause: interpretation.primaryCauseKey == .packetLoss,
                                causeColor: insightColor(for: interpretation.primaryCauseKey)
                            )
                            metricCard(
                                title: "result.metric.spikes",
                                value: String(result.metrics.rest.spikeCount),
                                unit: nil,
                                isCause: interpretation.primaryCauseKey == .severeSpikes,
                                causeColor: insightColor(for: interpretation.primaryCauseKey)
                            )
                        }
                    }
                }

                // 4. Diagnóstico de Partida (Insight Banner)
                InsightBanner(
                    tone: insightTone(for: interpretation.primaryCauseKey),
                    message: localizedKey(interpretation.insightKey.rawValue),
                    icon: insightIcon(for: interpretation.primaryCauseKey)
                )

                // 5. Barra de Ações HIG
                VStack(spacing: NLSpacing.sm) {
                    PrimaryButton(title: "quick_check.result.retry", action: retry)
                        .accessibilityIdentifier("lagcheck-result-retry")

                    HStack(spacing: NLSpacing.sm) {
                        secondaryActionButton("result.action.details", identifier: "lagcheck-result-details", action: showDetails)
                        secondaryActionButton("result.action.optimize", identifier: "lagcheck-result-booster", action: showBooster)
                    }
                }
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
            .navigationTitle(LocalizedStringKey("result.title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NolaggyBackButton(action: exit, accessibilityIdentifier: "deep-check-result-back")
                }
            }
        }
    }

    private func localizedKey(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }

    private func scoreToneColor(for band: ResultClass) -> Color {
        switch band {
        case .excellent, .great: return NLColor.scoreExcellent
        case .unstable: return NLColor.scoreUnstable
        case .lagRisk: return NLColor.coralSolarRed
        }
    }

    private func metricCard(title: String, value: String, unit: String?, isCause: Bool, causeColor: Color) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isCause ? causeColor : NLColor.textPrimary)
                if let unit {
                    Text(unit)
                        .font(NLTypography.caption)
                        .foregroundStyle(isCause ? causeColor : NLColor.textTertiary)
                }
            }
            Text(LocalizedStringKey(title))
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isCause ? causeColor.opacity(0.5) : NLColor.borderSubtle, lineWidth: isCause ? 1.0 : 0.5)
        }
    }

    private func secondaryActionButton(_ titleKey: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(LocalizedStringKey(titleKey))
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(NLColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous)
                        .stroke(NLColor.borderSubtle, lineWidth: 0.5)
                }
        }
        .accessibilityIdentifier(identifier)
    }

    private func milliseconds(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(Int(value.rounded()))
    }

    private func percentage(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    private func insightColor(for cause: ResultPrimaryCauseKey) -> Color {
        switch cause {
        case .stableConnection: return NLColor.scoreExcellent
        case .highLatency, .highJitter: return NLColor.scoreUnstable
        case .packetLoss, .severeSpikes: return NLColor.coralSolarRed
        }
    }

    private func insightTone(for cause: ResultPrimaryCauseKey) -> InsightBanner.Tone {
        switch cause {
        case .stableConnection: return .positive
        case .highLatency, .highJitter: return .tip
        case .packetLoss, .severeSpikes: return .risk
        }
    }

    private func insightIcon(for cause: ResultPrimaryCauseKey) -> Image {
        switch cause {
        case .stableConnection: return Image(systemName: "checkmark.shield.fill")
        case .highLatency, .highJitter: return Image(systemName: "info.circle.fill")
        case .packetLoss, .severeSpikes: return Image(systemName: "exclamationmark.triangle.fill")
        }
    }
}
