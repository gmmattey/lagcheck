import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Folha técnica secundária ("Entender minha conexão / Ver detalhes técnicos").
/// Apresenta o Score numérico (0–100), percentis P50/P95/P99, impacto sob carga e telemetria profunda,
/// desonerando a tela principal de resultado (Mockup 05 · Dark Competitive UI).
public struct TechnicalDetailsView: View {
    public let result: DeepCheckResult?
    public let evaluation: GameReadinessEvaluation
    public let gameName: String
    public let regionName: String
    public let measuredAt: Date?
    public let confidence: MeasurementConfidence?
    public let trace: FinalDeepCheckTrace?
    public let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        result: DeepCheckResult?,
        evaluation: GameReadinessEvaluation,
        gameName: String,
        regionName: String,
        measuredAt: Date? = nil,
        confidence: MeasurementConfidence? = nil,
        trace: FinalDeepCheckTrace? = nil,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.result = result
        self.evaluation = evaluation
        self.gameName = gameName
        self.regionName = regionName
        self.measuredAt = measuredAt
        self.confidence = confidence
        self.trace = trace
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Barra superior de ações e Título alinhado à esquerda
                NolaggyNamedScreenHeader(
                    title: LocalizedStringKey("technical_details.title"),
                    trailing: {
                        Button(action: {
                            onDismiss()
                            dismiss()
                        }) {
                            Text(LocalizedStringKey("technical_details.close"))
                                .font(NLTypography.bodyEmphasis)
                                .foregroundStyle(NLColor.textSecondary)
                                .frame(height: 44)
                        }
                        .accessibilityIdentifier("technical-details-close")
                    }
                )

                if let result, evaluation.verdict != .inconclusive {
                    // 1. Resumo do veredito compacto
                    compactVerdictSection(evaluation: evaluation)
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)

                    // 2. Score Numérico e Grade 2x2
                    scoreAndMetricsSection(result: result, evaluation: evaluation)
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)

                    // 3. Gráfico de Latência durante o Check
                    latencyChartSection
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)

                    // 4. Origem da evidência
                    evidenceOriginSection(evaluation: evaluation)
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)

                    // 5. O que encontramos
                    findingsSection(evaluation: evaluation)
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)

                    // 6. Nota técnica
                    technicalNoteSection
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                } else {
                    inconclusiveSection
                        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                }

                Spacer(minLength: NLSpacing.xl)
            }
        }
        .background(NLColor.deep.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    // MARK: - 1. Veredito Compacto
    private func compactVerdictSection(evaluation: GameReadinessEvaluation) -> some View {
        let verdict = evaluation.verdict
        let label = AppLocalization.string(evaluation.headlineKey, comment: "").uppercased()

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VerdictIndicatorBadge(verdict: verdict, size: 12)
                Text(verbatim: label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(colorForVerdict(verdict))
            }

            Text(verbatim: contextLabel)
                .font(NLTypography.monospaceMetrics)
                .foregroundStyle(NLColor.textTertiary)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(NLColor.borderStrong, lineWidth: 1)
        )
    }

    private var contextLabel: String {
        let measured = measuredAt.map { $0.formatted(date: .abbreviated, time: .shortened) }
        return [gameName, regionName, measured].compactMap { $0 }.joined(separator: " · ")
    }

    private func verdictSymbol(for verdict: GameReadinessVerdict) -> String {
        switch verdict {
        case .ready: return "●"
        case .caution, .notReady: return "▲"
        case .inconclusive: return "—"
        }
    }

    private func colorForVerdict(_ verdict: GameReadinessVerdict) -> Color {
        switch verdict {
        case .ready: return NLColor.semanticReady
        case .caution: return NLColor.semanticCaution
        case .notReady: return NLColor.semanticNotReady
        case .inconclusive: return NLColor.textTertiary
        }
    }

    // MARK: - 2. Score e Grade 2x2
    private func scoreAndMetricsSection(result: DeepCheckResult, evaluation: GameReadinessEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("technical_details.score_heading"))
                        .font(NLTypography.captionMonoUppercase)
                        .foregroundStyle(NLColor.textTertiary)

                    Text(LocalizedStringKey("technical_details.quality_score"))
                        .font(.system(size: 13))
                        .foregroundStyle(NLColor.textSecondary)
                }

                Spacer()

                if let score = evaluation.score {
                    Text(verbatim: "\(score)")
                        .font(NLTypography.monospaceDetailScore)
                        .foregroundStyle(NLColor.textPrimary)
                        .accessibilityIdentifier("check-completo-score")
                } else {
                    Text(verbatim: "—")
                        .font(NLTypography.monospaceDetailScore)
                        .foregroundStyle(NLColor.textTertiary)
                        .accessibilityIdentifier("check-completo-score")
                }
            }

            // Grade 2x2
            let metrics = result.restResult.metrics
            LazyVGrid(
                columns: dynamicTypeSize.isAccessibilitySize
                    ? [GridItem(.flexible())]
                    : [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                spacing: 8
            ) {
                metricBox(title: LocalizedStringKey("technical_details.p50_label"), value: formatMs(metrics.p50Milliseconds))
                metricBox(title: LocalizedStringKey("game_readiness.telemetry.jitter"), value: formatMs(metrics.jitterMilliseconds))
                metricBox(title: LocalizedStringKey("game_readiness.telemetry.loss"), value: formatPercent(metrics.packetLossPercentage))
                metricBox(title: LocalizedStringKey("technical_details.p99_label"), value: formatMs(metrics.p99Milliseconds))
            }
        }
    }

    private func metricBox(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(NLColor.textTertiary)

            Text(verbatim: value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(NLColor.textPrimary)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(NLColor.borderStrong, lineWidth: 1)
        )
    }

    // MARK: - 3. Gráfico de Latência
    private var latencyChartSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(LocalizedStringKey("technical_details.percentiles_title"))
                .font(NLTypography.captionMonoUppercase)
                .foregroundStyle(NLColor.textTertiary)

            if let trace {
                let maximumRTT = max(
                    100,
                    ((trace.restSamples + trace.loadSamples).filter(\.isValidResponse).compactMap(\.roundTripMilliseconds).max() ?? 100) * 1.15
                )
                HStack(spacing: NLSpacing.sm) {
                    TracePhaseChart(samples: trace.restSamples, maximumRTT: maximumRTT, color: NLColor.semanticReady)
                    Divider().overlay(NLColor.borderStrong)
                    TracePhaseChart(samples: trace.loadSamples, maximumRTT: maximumRTT, color: NLColor.semanticReady)
                        .background(NLColor.panel.opacity(0.55))
                }
                .frame(height: 118)
                .padding(NLSpacing.sm)
                .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                        .stroke(NLColor.hairline, lineWidth: 1)
                }
                .accessibilityLabel(traceAccessibilityLabel)

                HStack {
                    Text(LocalizedStringKey("deep_check.graph.rest"))
                        .font(NLTypography.monospaceMetrics)
                        .foregroundStyle(NLColor.textTertiary)
                    Spacer()
                    Text(LocalizedStringKey("deep_check.graph.load"))
                        .font(NLTypography.monospaceMetrics)
                        .foregroundStyle(NLColor.textTertiary)
                }
            } else {
                Text(LocalizedStringKey("technical_details.chart_unavailable"))
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .padding(NLSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                            .stroke(NLColor.hairline, lineWidth: 1)
                    }
            }
        }
    }

    private var traceAccessibilityLabel: String {
        guard let metrics = evaluation.metrics, let load = metrics.load else {
            return AppLocalization.string("technical_details.chart_unavailable", comment: "")
        }
        let restLabel = AppLocalization.string("deep_check.graph.rest", comment: "")
        let loadLabel = AppLocalization.string("deep_check.graph.load", comment: "")
        let lossLabel = AppLocalization.string("game_readiness.telemetry.loss", comment: "").lowercased()
        let rest = "\(restLabel): \(formatMs(metrics.rest.p50Milliseconds)), \(formatPercent(metrics.rest.packetLossPercentage)) \(lossLabel)"
        let stressed = "\(loadLabel): \(formatMs(load.p50Milliseconds)), \(formatPercent(load.packetLossPercentage)) \(lossLabel)"
        return "\(rest). \(stressed)."
    }

    // MARK: - 4. Origem da Evidência
    private func evidenceOriginSection(evaluation: GameReadinessEvaluation) -> some View {
        let routeStatusText = AppLocalization.string("technical_details.status_measured", comment: "")
        let routeStatusColor = NLColor.textTertiary


        return VStack(alignment: .leading, spacing: 11) {
            Text(LocalizedStringKey("technical_details.evidence_origin"))
                .font(NLTypography.captionMonoUppercase)
                .foregroundStyle(NLColor.textTertiary)

            VStack(spacing: 8) {
                evidenceRow(
                    title: AppLocalization.string("technical_details.local_hop"),
                    statusText: AppLocalization.string("technical_details.unobservable"),
                    statusColor: NLColor.textTertiary,
                    detail: AppLocalization.string("technical_details.local_hop_unobservable_detail")
                )

                evidenceRow(
                    title: AppLocalization.string("technical_details.external_route"),
                    statusText: routeStatusText,
                    statusColor: routeStatusColor,
                    detail: String(format: AppLocalization.string(
                        evaluation.metrics?.load == nil
                            ? "technical_details.external_route_detail %@"
                            : "technical_details.external_route_detail_load %@"
                    ), regionName)
                )
            }
        }
    }

    private func evidenceRow(title: String, statusText: String, statusColor: Color, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)

                Spacer()

                Text(verbatim: statusText)
                    .font(NLTypography.monospaceMetrics)
                    .foregroundStyle(statusColor)
            }

            Text(verbatim: detail)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(NLColor.textTertiary)
                .lineSpacing(2)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(NLColor.borderStrong, lineWidth: 1)
        )
    }

    // MARK: - 5. O Que Encontramos
    private func findingsSection(evaluation: GameReadinessEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(LocalizedStringKey("technical_details.findings_title"))
                .font(NLTypography.captionMonoUppercase)
                .foregroundStyle(NLColor.textTertiary)

            VStack(spacing: 0) {
                ForEach(Array(evaluation.findings.enumerated()), id: \.offset) { index, finding in
                    findingRow(
                        title: AppLocalization.string(finding.labelKey, comment: ""),
                        detail: finding.detail,
                        color: colorForFindingSeverity(finding.severity),
                        isLast: index == evaluation.findings.count - 1
                    )
                }
            }
            .padding(.horizontal, NLSpacing.md)
            .background(NLColor.surface, in: RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: NLRadius.card, style: .continuous)
                    .stroke(NLColor.hairline, lineWidth: 1)
            }
        }
    }

    private func colorForFindingSeverity(_ severity: NetworkFinding.Severity) -> Color {
        switch severity {
        case .positive: return NLColor.semanticReady
        case .warning: return NLColor.semanticCaution
        case .negative: return NLColor.semanticNotReady
        case .neutral: return NLColor.textTertiary
        }
    }

    private func findingRow(title: String, detail: String?, color: Color, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Circle().fill(color).frame(width: 7, height: 7).padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: title).font(NLTypography.callout.weight(.semibold)).foregroundStyle(NLColor.textPrimary)
                if let detail, !detail.isEmpty {
                    Text(verbatim: detail).font(NLTypography.footnote).foregroundStyle(NLColor.textSecondary).lineSpacing(2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .overlay(isLast ? nil : Rectangle().fill(NLColor.borderStrong).frame(height: 1), alignment: .bottom)
    }

    // MARK: - 6. Nota Técnica
    private var technicalNoteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: confidenceText)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(NLColor.textPrimary)

            Text(verbatim: "\(GameReadinessEvaluator.version)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(NLColor.textTertiary)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(NLColor.borderStrong, lineWidth: 1)
        )
    }

    private var confidenceText: String {
        guard let confidence else { return "—" }
        return confidence == .high ? AppLocalization.string("technical_details.confidence_good") : AppLocalization.string("technical_details.confidence_medium")
    }

    private var inconclusiveSection: some View {
        VStack(spacing: NLSpacing.sm) {
            Text(LocalizedStringKey("technical_details.inconclusive_title"))
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)

            Text(LocalizedStringKey("technical_details.inconclusive_message"))
                .font(NLTypography.body)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(NLSpacing.cardPadding)
    }

    // MARK: - Formatadores
    private func formatMs(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded())) ms"
    }

    private func formatPercent(_ value: Double?) -> String {
        guard let value else { return "—" }
        if value <= 0.05 { return "0%" }
        let formatter = NumberFormatter()
        formatter.locale = AppLocalization.locale
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return "\(formatter.string(from: NSNumber(value: value)) ?? "\(value)")%"
    }

}

private struct TracePhaseChart: View {
    let samples: [ProbeSample]
    let maximumRTT: Double
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let samples = samples.sorted { $0.sequence < $1.sequence }
            let minSequence = samples.first?.sequence ?? 0
            let sequenceSpan = max((samples.last?.sequence ?? minSequence) - minSequence, 1)

            ZStack {
                Path { path in
                    for fraction in [0.25, 0.5, 0.75] {
                        path.move(to: CGPoint(x: 0, y: proxy.size.height * fraction))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height * fraction))
                    }
                }
                .stroke(NLColor.hairline, lineWidth: 1)

                Path { path in
                    var lastValidSequence: Int?
                    for sample in samples {
                        guard let rtt = sample.roundTripMilliseconds, sample.outcome == .received else {
                            lastValidSequence = nil
                            continue
                        }
                        let x = proxy.size.width * CGFloat(sample.sequence - minSequence) / CGFloat(sequenceSpan)
                        let normalized = min(max(rtt / maximumRTT, 0.04), 0.96)
                        let y = proxy.size.height * (1 - CGFloat(normalized))
                        if lastValidSequence == sample.sequence - 1 {
                            path.addLine(to: CGPoint(x: x, y: y))
                        } else {
                            path.move(to: CGPoint(x: x, y: y))
                        }
                        lastValidSequence = sample.sequence
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
