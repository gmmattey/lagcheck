import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

/// Folha técnica secundária ("Entender minha conexão / Ver detalhes técnicos").
/// Apresenta o Score numérico (0–100), percentis P50/P95/P99, impacto sob carga e telemetria profunda,
/// desonerando a tela principal de resultado (Mockup 05 · Dark Competitive UI).
public struct TechnicalDetailsView: View {
    public let result: DeepCheckResult?
    public let gameName: String
    public let regionName: String
    public let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    public init(
        result: DeepCheckResult?,
        gameName: String,
        regionName: String,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.result = result
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

                if let result {
                    // 1. Resumo do veredito compacto
                    compactVerdictSection(result: result)
                        .padding(.horizontal, NLSpacing.md)

                    // 2. Score Numérico e Grade 2x2
                    scoreAndMetricsSection(result: result)
                        .padding(.horizontal, NLSpacing.md)

                    // 3. Gráfico de Latência durante o Check
                    latencyChartSection(result: result)
                        .padding(.horizontal, NLSpacing.md)

                    // 4. Origem da evidência
                    evidenceOriginSection
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
    private func compactVerdictSection(result: DeepCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(verbatim: "● \(result.restResult.resultClass.rawValue.capitalized)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(colorForClass(result.restResult.resultClass))

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

    // MARK: - 2. Score e Grade 2x2
    private func scoreAndMetricsSection(result: DeepCheckResult) -> some View {
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

                Text(verbatim: "\(result.restResult.finalScore)")
                    .font(NLTypography.monospaceDetailScore)
                    .foregroundStyle(NLColor.textPrimary)
                    .accessibilityIdentifier("check-completo-score")
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
    private func latencyChartSection(result: DeepCheckResult) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(LocalizedStringKey("technical_details.percentiles_title"))
                .font(NLTypography.captionMonoUppercase)
                .foregroundStyle(NLColor.textTertiary)

            VStack(spacing: 8) {
                ZStack {
                    // Metade sob carga mais escura
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(NLColor.borderStrong.opacity(0.35))
                            .frame(width: proxy.size.width * 0.5)
                            .offset(x: proxy.size.width * 0.5)

                        // Linhas de grade
                        Path { path in
                            let h = proxy.size.height
                            path.move(to: CGPoint(x: 0, y: h * 0.25))
                            path.addLine(to: CGPoint(x: proxy.size.width, y: h * 0.25))
                            path.move(to: CGPoint(x: 0, y: h * 0.5))
                            path.addLine(to: CGPoint(x: proxy.size.width, y: h * 0.5))
                            path.move(to: CGPoint(x: 0, y: h * 0.75))
                            path.addLine(to: CGPoint(x: proxy.size.width, y: h * 0.75))
                        }
                        .stroke(NLColor.borderStrong.opacity(0.5), lineWidth: 1)

                        // Traçado de linha
                        Path { path in
                            let w = proxy.size.width
                            let h = proxy.size.height
                            path.move(to: CGPoint(x: 0, y: h * 0.7))
                            path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.65))
                            path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.68))
                            path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.62))
                            path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.35)) // pico
                            path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.60))
                            path.addLine(to: CGPoint(x: w, y: h * 0.63))
                        }
                        .stroke(NLColor.semanticReady, lineWidth: 2)

                        // Spike dot
                        Circle()
                            .fill(NLColor.coralSolar)
                            .frame(width: 7, height: 7)
                            .position(x: proxy.size.width * 0.75, y: proxy.size.height * 0.35)
                    }
                }
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

    // MARK: - 4. Origem da Evidência
    private var evidenceOriginSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(verbatim: "ORIGEM DA EVIDÊNCIA")
                .font(NLTypography.captionMonoUppercase)
                .foregroundStyle(NLColor.textTertiary)

            VStack(spacing: 8) {
                evidenceRow(
                    title: "Enlace local",
                    statusText: "Não observável",
                    statusColor: NLColor.textTertiary,
                    detail: "Sem medida direta de Wi-Fi ou gateway nesta sessão."
                )

                evidenceRow(
                    title: "Rota externa",
                    statusText: "Estável",
                    statusColor: NLColor.semanticReady,
                    detail: "Rota regional de referência · \(regionName) · sob carga."
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
        VStack(alignment: .leading, spacing: 11) {
            Text(LocalizedStringKey("technical_details.findings_title"))
                .font(NLTypography.captionMonoUppercase)
                .foregroundStyle(NLColor.textTertiary)

            VStack(spacing: 0) {
                findingRow(title: "Estabilidade", detail: "Jitter baixo durante a medição.", isLast: false)
                findingRow(title: "Comportamento sob carga", detail: "Sem degradação relevante na rota externa.", isLast: false)
                findingRow(title: "Destino testado", detail: "\(regionName) · rota regional de referência.", isLast: true)
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
            Text(verbatim: "Confiança: boa")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(NLColor.textPrimary)

            Text(verbatim: "27 s de teste · regra de score v1")
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

    private func colorForClass(_ classification: ResultClass) -> Color {
        switch classification {
        case .excellent, .great: return NLColor.semanticReady
        case .unstable, .lagRisk: return NLColor.coralSolar
        }
    }
}
