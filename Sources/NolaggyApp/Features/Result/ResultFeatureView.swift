import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Tela de resultado da medição: a conclusão vem antes das
/// métricas, seguida de causa e recomendação já interpretadas pelo domínio.
extension QuickCheckFeatureView {
    func resultView(result: QualityResult) -> some View {
        let profile = selectedRegionalContext?.profileID ?? .battleRoyaleCompetitive
        let interpretation = ResultInterpreter.interpret(result, profile: profile)
        let headline = AppLocalization.string(interpretation.headlineKey.rawValue, comment: "")
        let scoreAccessibilityDescription = String(
            format: AppLocalization.string("quick_check.result.score_accessibility", comment: ""),
            interpretation.score,
            headline
        )
        let isWiFi = selectedRegionalContext?.observedPhoneNetwork == .wifi
        let isLocalHealthy = interpretation.primaryCauseKey != .highJitter
        let isDestinationHealthy = interpretation.scoreBand == .excellent || interpretation.scoreBand == .great
        let wifiStatusText = isWiFi
            ? (isLocalHealthy
                ? AppLocalization.string("result.route_trail.wifi_healthy", comment: "")
                : AppLocalization.string("result.route_trail.wifi_unstable", comment: ""))
            : AppLocalization.string("result.route_trail.cellular_active", comment: "")
        let destinationStatus = String(
            format: AppLocalization.string("result.route_trail.destination_responding %@", comment: ""),
            milliseconds(interpretation.metrics.p50Milliseconds)
        )
        let scoreColor = scoreToneColor(for: interpretation.scoreBand)

        return ScrollView {
            VStack(spacing: NLSpacing.xl) {
                // 1. Hero Editorial (Veredito Imediato do HIG)
                VStack(spacing: NLSpacing.sm) {
                    // Pílula semântica com o Score e Classificação
                    HStack(spacing: NLSpacing.xs) {
                        Text("\(interpretation.score)")
                            .font(.system(size: 17, weight: .heavy, design: .default))
                            .monospacedDigit()
                        Text("·")
                            .font(.system(size: 15, weight: .bold))
                        Text(localized(interpretation.headlineKey.rawValue))
                            .font(NLTypography.caption.weight(.bold))
                            .textCase(.uppercase)
                    }
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, NLSpacing.sm)
                    .padding(.vertical, NLSpacing.xxs)
                    .background(scoreColor.opacity(0.12), in: Capsule())
                    .overlay { Capsule().stroke(scoreColor.opacity(0.3), lineWidth: 0.5) }

                    // Conclusão assertiva
                    Text(localized(interpretation.conclusionKey.rawValue))
                        .font(NLTypography.verdictHeadline)
                        .foregroundStyle(NLColor.textPrimary)
                        .multilineTextAlignment(.center)

                    // Explicação amigável
                    Text(localized(interpretation.explanationKey.rawValue))
                        .font(NLTypography.callout)
                        .foregroundStyle(NLColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, NLSpacing.sm)

                    // Contexto da partida
                    Text("\(selectedGameName) · iPhone · \(selectedRegionFriendlyName)")
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textTertiary)
                        .padding(.top, NLSpacing.xxs)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(scoreAccessibilityDescription)

                // 2. Atestado da Rota (Trilha Consolidada HIG)
                RouteTrailSummaryCard(
                    isWiFi: isWiFi,
                    wifiStatusText: wifiStatusText,
                    isLocalHealthy: isLocalHealthy,
                    destinationName: selectedRegionFriendlyName,
                    destinationKind: selectedRegionalContext?.strategy == .dedicatedServer ? .dedicatedServer : .regionalReference,
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
                                value: milliseconds(interpretation.metrics.p50Milliseconds),
                                unit: "ms",
                                isCause: interpretation.primaryCauseKey == .highLatency,
                                causeColor: insightColor(for: interpretation.primaryCauseKey)
                            )
                            metricCard(
                                title: "result.metric.jitter",
                                value: milliseconds(interpretation.metrics.jitterMilliseconds),
                                unit: "ms",
                                isCause: interpretation.primaryCauseKey == .highJitter,
                                causeColor: insightColor(for: interpretation.primaryCauseKey)
                            )
                        }
                        HStack(spacing: NLSpacing.sm) {
                            metricCard(
                                title: "result.metric.loss",
                                value: percentage(interpretation.metrics.packetLossPercentage),
                                unit: nil,
                                isCause: interpretation.primaryCauseKey == .packetLoss,
                                causeColor: insightColor(for: interpretation.primaryCauseKey)
                            )
                            metricCard(
                                title: "result.metric.spikes",
                                value: String(interpretation.metrics.spikeCount),
                                unit: nil,
                                isCause: interpretation.primaryCauseKey == .severeSpikes,
                                causeColor: insightColor(for: interpretation.primaryCauseKey)
                            )
                        }
                    }
                }

                // 4. Banner de Diagnóstico (Insight)
                InsightBanner(
                    tone: insightTone(for: interpretation.primaryCauseKey),
                    message: localized(interpretation.insightKey.rawValue),
                    icon: insightIcon(for: interpretation.primaryCauseKey)
                )

                // 5. Barra de Ações (Action Bar HIG)
                VStack(spacing: NLSpacing.sm) {
                    PrimaryButton(title: "quick_check.result.retry", action: restart)
                        .accessibilityIdentifier("measurement-retry")

                    HStack(spacing: NLSpacing.sm) {
                        secondaryResultAction("result.action.details", identifier: "measurement-details") { showingDetails = true }
                        secondaryResultAction("result.action.optimize", identifier: "measurement-booster") { showingDetails = true }
                    }
                }
                .padding(.top, NLSpacing.xs)

                NativeAdSlot(placement: .result)
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NolaggyBackButton(action: back, accessibilityIdentifier: "measurement-back")
                }
            }
        }
    }

    private func metricCard(title: LocalizedStringKey, value: String, unit: String?, isCause: Bool, causeColor: Color) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(NLTypography.metricsNumberLarge)
                    .foregroundStyle(isCause ? causeColor : NLColor.textPrimary)
                if let unit {
                    Text(unit)
                        .font(NLTypography.caption.weight(.bold))
                        .foregroundStyle(isCause ? causeColor : NLColor.textTertiary)
                }
            }
            Text(title)
                .font(NLTypography.metricsLabel)
                .tracking(NLTypography.metricsLabelTracking)
                .textCase(.uppercase)
                .foregroundStyle(NLColor.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                .stroke(isCause ? causeColor.opacity(0.5) : NLColor.borderSubtle, lineWidth: isCause ? 1.0 : 0.5)
        }
    }

    private func scoreToneColor(for band: ResultClass) -> Color {
        switch band {
        case .excellent, .great:
            return NLColor.scoreExcellent
        case .unstable:
            return NLColor.scoreUnstable
        case .lagRisk:
            return NLColor.coralSolarRed
        }
    }

    func secondaryResultAction(_ title: LocalizedStringKey, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(NLTypography.callout.weight(.semibold))
                .foregroundStyle(NLColor.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: NLSizing.touchTarget)
                .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: NLRadius.button, style: .continuous).stroke(NLColor.borderSubtle, lineWidth: 0.5) }
        }
        .accessibilityIdentifier(identifier)
    }

    func scoreClassification(for resultClass: ResultClass) -> NLScoreClassification {
        switch resultClass {
        case .excellent: .excellent
        case .great: .great
        case .unstable: .unstable
        case .lagRisk: .lagRisk
        }
    }

    func insightTone(for cause: ResultPrimaryCauseKey) -> InsightBanner.Tone {
        switch cause {
        case .stableConnection: .positive
        case .packetLoss, .highLatency, .severeSpikes, .highJitter, .loadDegradation, .loadInstability, .tailLatency, .outOfOrder: .risk
        }
    }

    func insightIcon(for cause: ResultPrimaryCauseKey) -> Image {
        switch cause {
        case .stableConnection: Image(systemName: "checkmark.circle")
        case .packetLoss, .highLatency, .severeSpikes, .highJitter, .loadDegradation, .loadInstability, .tailLatency, .outOfOrder: Image(systemName: "exclamationmark.triangle")
        }
    }

    func insightColor(for cause: ResultPrimaryCauseKey) -> Color {
        switch cause {
        case .stableConnection: NLColor.scoreExcellent
        case .packetLoss, .highLatency, .severeSpikes, .highJitter, .loadDegradation, .loadInstability, .tailLatency, .outOfOrder: NLColor.scoreLagRisk
        }
    }
}
