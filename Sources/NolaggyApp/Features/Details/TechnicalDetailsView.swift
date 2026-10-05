import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Folha técnica secundária ("Entender minha conexão / Ver detalhes técnicos").
/// Apresenta o Score numérico (0–100), percentis P50/P95/P99, impacto sob carga e telemetria profunda,
/// desonerando a tela principal de resultado (Mockup 05 · Dark Competitive UI).
public struct TechnicalDetailsView: View {
    public let result: DeepCheckResult?
    public let evaluation: GameReadinessEvaluation?
    public let gameName: String
    public let regionName: String
    public let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    public init(
        result: DeepCheckResult?,
        evaluation: GameReadinessEvaluation? = nil,
        profileID: QualityProfileID = .battleRoyaleCompetitive,
        gameName: String,
        regionName: String,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.result = result
        if let evaluation {
            self.evaluation = evaluation
        } else {
            self.evaluation = result.map { GameReadinessEvaluator.evaluate(deepCheckResult: $0, profile: profileID) }
        }
        self.gameName = gameName
        self.regionName = regionName
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

                if let result, let evaluation {
                    // 1. Resumo do veredito compacto
                    compactVerdictSection(evaluation: evaluation)
                        .padding(.horizontal, NLSpacing.md)

                    // 2. Score Numérico e Grade 2x2
                    scoreAndMetricsSection(result: result, evaluation: evaluation)
                        .padding(.horizontal, NLSpacing.md)

                    // 3. Gráfico de Latência durante o Check
                    latencyChartSection(result: result)
                        .padding(.horizontal, NLSpacing.md)

                    // 4. Origem da evidência
                    evidenceOriginSection(evaluation: evaluation)
                        .padding(.horizontal, NLSpacing.md)

                    // 5. O que encontramos
                    findingsSection(result: result)
                        .padding(.horizontal, NLSpacing.md)

                    // 6. Nota técnica
                    technicalNoteSection
                        .padding(.horizontal, NLSpacing.md)
                } else {
                    inconclusiveSection
                        .padding(.horizontal, NLSpacing.md)
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

            Text(verbatim: "\(gameName) · \(regionName) · \(Date().formatted(date: .abbreviated, time: .shortened))")
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
                    Text(verbatim: "SCORE")
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
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
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
    @ViewBuilder
    private func latencyChartSection(result: DeepCheckResult) -> some View {
        let restMetrics = result.metrics.rest
        let loadMetrics = result.metrics.load

        if let p50Rest = restMetrics.p50Milliseconds {
            let p95Rest = restMetrics.p95Milliseconds ?? p50Rest
            let p50Load = loadMetrics?.p50Milliseconds ?? p50Rest
            let p95Load = loadMetrics?.p95Milliseconds ?? p95Rest
            let p99Load = loadMetrics?.p99Milliseconds ?? p95Load
            let hasSpike = (restMetrics.spikeCount > 0) || ((loadMetrics?.spikeCount ?? 0) > 0)

            VStack(alignment: .leading, spacing: 11) {
                Text(LocalizedStringKey("technical_details.percentiles_title"))
                    .font(NLTypography.captionMonoUppercase)
                    .foregroundStyle(NLColor.textTertiary)

                VStack(spacing: 8) {
                    PercentileChartView(
                        p50Rest: p50Rest,
                        p95Rest: p95Rest,
                        p50Load: p50Load,
                        p95Load: p95Load,
                        p99Load: p99Load,
                        hasSpike: hasSpike
                    )
                    .frame(height: 118)
                    .background(NLColor.surface)
                    .overlay(
                        Rectangle()
                            .stroke(NLColor.borderStrong, lineWidth: 1)
                    )

                    HStack {
                        Text(LocalizedStringKey("deep_check.graph.rest"))
                            .font(NLTypography.monospaceMetrics)
                            .foregroundStyle(NLColor.textTertiary)

                        Spacer()

                        Text(LocalizedStringKey("deep_check.graph.load"))
                            .font(NLTypography.monospaceMetrics)
                            .foregroundStyle(NLColor.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - 4. Origem da Evidência
    private func evidenceOriginSection(evaluation: GameReadinessEvaluation) -> some View {
        let routeStatusText: String
        let routeStatusColor: Color
        switch evaluation.verdict {
        case .ready:
            routeStatusText = AppLocalization.string("technical_details.status_stable", comment: "")
            routeStatusColor = NLColor.semanticReady
        case .caution:
            routeStatusText = AppLocalization.string("game_readiness.verdict.caution", comment: "")
            routeStatusColor = NLColor.semanticCaution
        case .notReady:
            routeStatusText = AppLocalization.string("game_readiness.verdict.not_ready", comment: "")
            routeStatusColor = NLColor.semanticNotReady
        case .inconclusive:
            routeStatusText = AppLocalization.string("game_readiness.verdict.inconclusive", comment: "")
            routeStatusColor = NLColor.textTertiary
        }

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
                    detail: String(format: AppLocalization.string("technical_details.external_route_detail %@"), regionName)
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
    private func findingsSection(result: DeepCheckResult) -> some View {
        let jitter = result.restResult.metrics.jitterMilliseconds ?? 0
        let jitterInt = Int(jitter.rounded())
        let jitterText = jitter <= 5.0
            ? String(format: AppLocalization.string("technical_details.finding.jitter_stable %d"), jitterInt)
            : String(format: AppLocalization.string("technical_details.finding.jitter_observed %d"), jitterInt)

        let loadImpact = result.metrics.loadImpact?.increaseMilliseconds ?? 0
        let loadInt = Int(loadImpact.rounded())
        let loadText: String
        if loadImpact <= 15.0 {
            loadText = loadInt == 0
                ? AppLocalization.string("technical_details.finding.load_no_degradation")
                : String(format: AppLocalization.string("technical_details.finding.load_minimal_degradation %d"), loadInt)
        } else {
            loadText = String(format: AppLocalization.string("technical_details.finding.load_increase %d"), loadInt)
        }

        return VStack(alignment: .leading, spacing: 11) {
            Text(LocalizedStringKey("technical_details.findings_title"))
                .font(NLTypography.captionMonoUppercase)
                .foregroundStyle(NLColor.textTertiary)

            VStack(spacing: 0) {
                findingRow(title: AppLocalization.string("technical_details.finding.stability"), detail: jitterText, isLast: false)
                findingRow(title: AppLocalization.string("technical_details.finding.load_behavior"), detail: loadText, isLast: false)
                findingRow(
                    title: AppLocalization.string("technical_details.finding.tested_destination"),
                    detail: String(format: AppLocalization.string("technical_details.finding.tested_destination_detail %@"), regionName),
                    isLast: true
                )
            }
            .padding(.horizontal, NLSpacing.md)
            .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(NLColor.borderStrong, lineWidth: 1)
            )
        }
    }

    private func findingRow(title: String, detail: String, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Circle()
                .fill(NLColor.semanticReady)
                .frame(width: 7, height: 7)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)

                Text(verbatim: detail)
                    .font(.system(size: 12))
                    .foregroundStyle(NLColor.textSecondary)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .overlay(
            isLast ? nil : Rectangle().fill(NLColor.borderStrong).frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - 6. Nota Técnica
    private var technicalNoteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey("technical_details.confidence_good"))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(NLColor.textPrimary)

            Text(LocalizedStringKey("technical_details.test_duration_v1"))
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
        return String(format: "%.1f%%", value)
    }

}

struct PercentileChartView: View {
    let p50Rest: Double
    let p95Rest: Double
    let p50Load: Double
    let p95Load: Double
    let p99Load: Double
    let hasSpike: Bool

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let maxVal = max(100.0, max(p99Load, p95Rest) * 1.25)

            let yRestP50 = h * (1.0 - CGFloat(min(1.0, max(0.05, p50Rest / maxVal))))
            let yRestP95 = h * (1.0 - CGFloat(min(1.0, max(0.05, p95Rest / maxVal))))
            let yLoadP50 = h * (1.0 - CGFloat(min(1.0, max(0.05, p50Load / maxVal))))
            let yLoadP95 = h * (1.0 - CGFloat(min(1.0, max(0.05, p95Load / maxVal))))
            let yLoadP99 = h * (1.0 - CGFloat(min(1.0, max(0.05, p99Load / maxVal))))

            ZStack(alignment: .leading) {
                // Metade sob carga mais escura
                Rectangle()
                    .fill(NLColor.borderStrong.opacity(0.35))
                    .frame(width: w * 0.5)
                    .offset(x: w * 0.5)

                // Linhas de grade
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.25))
                    path.addLine(to: CGPoint(x: w, y: h * 0.25))
                    path.move(to: CGPoint(x: 0, y: h * 0.5))
                    path.addLine(to: CGPoint(x: w, y: h * 0.5))
                    path.move(to: CGPoint(x: 0, y: h * 0.75))
                    path.addLine(to: CGPoint(x: w, y: h * 0.75))
                }
                .stroke(NLColor.borderStrong.opacity(0.5), lineWidth: 1)

                // Curva de percentis calculada
                Path { path in
                    path.move(to: CGPoint(x: 0, y: yRestP50))
                    path.addLine(to: CGPoint(x: w * 0.25, y: yRestP50))
                    path.addLine(to: CGPoint(x: w * 0.45, y: yRestP95))
                    path.addLine(to: CGPoint(x: w * 0.55, y: yLoadP50))
                    path.addLine(to: CGPoint(x: w * 0.75, y: yLoadP99))
                    path.addLine(to: CGPoint(x: w * 0.88, y: yLoadP95))
                    path.addLine(to: CGPoint(x: w, y: yLoadP50))
                }
                .stroke(NLColor.semanticReady, lineWidth: 2)

                // Spike dot real
                if hasSpike {
                    Circle()
                        .fill(NLColor.coralSolar)
                        .frame(width: 7, height: 7)
                        .position(x: w * 0.75, y: yLoadP99)
                }
            }
        }
    }
}
