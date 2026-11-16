import SwiftUI
import NolaggyDesign
import NolaggyDomain

struct StabilityChipOption: Identifiable, Equatable {
    let key: String?
    let label: String

    var id: String { key ?? "__all__" }
}

/// Linha de filtros sem contorno e com cantos contidos (8 pt), usando apenas profundidade.
struct StabilityChipRow: View {
    let options: [StabilityChipOption]
    let selectedKey: String?
    let onSelected: (String?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NLSpacing.space2) {
                ForEach(options) { option in
                    let isSelected = option.key == selectedKey
                    Button {
                        onSelected(option.key)
                    } label: {
                        Text(option.label)
                            .font(NLTypography.captionStrong)
                            .foregroundStyle(isSelected ? NLColor.textPrimary : NLColor.textSecondary)
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: NLRadius.sm, style: .continuous)
                                    .fill(isSelected ? NLColor.panel : NLColor.surface)
                            )
                            .shadow(
                                color: NLShadow.cardColor,
                                radius: isSelected ? 6 : 2,
                                x: 0,
                                y: isSelected ? 3 : 1
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

/// Bloco único de estabilidade de rede no Histórico (Decisão 143 / Dark Competitive UI).
/// Mantém um único container de superfície sem bordas nem cards aninhados.
struct StabilityEvolutionBlock: View {
    let summary: StabilitySummaryResponseDTO
    let isOverview: Bool

    @State private var selectedPointIndex: Int? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var activePointIndex: Int? {
        guard !summary.points.isEmpty else { return nil }
        if let selectedPointIndex, selectedPointIndex >= 0, selectedPointIndex < summary.points.count {
            return selectedPointIndex
        }
        return summary.points.count - 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.space4) {
            headerSection

            if summary.canDrawCurve {
                pingEvolutionChart
            } else {
                insufficientCurveView
            }

            if summary.hasSummary, let rings = summary.rings {
                Rectangle()
                    .fill(NLColor.borderHairline)
                    .frame(height: 1)

                ringsSection(rings)
            }

            if summary.inconclusiveCount > 0 {
                inconclusiveFooter
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous)
                .fill(NLColor.surface)
        )
        .shadow(color: NLShadow.cardColor, radius: 8, x: 0, y: 4)
        .onChange(of: summary.points.count) { _, _ in
            selectedPointIndex = nil
        }
    }

    // MARK: - Cabeçalho

    private var headerSection: some View {
        HStack(alignment: .top, spacing: NLSpacing.space3) {
            VStack(alignment: .leading, spacing: 4) {
                Text(headerKicker)
                    .font(NLTypography.metricsLabel)
                    .tracking(NLTypography.metricsLabelTracking)
                    .foregroundStyle(NLColor.textTertiary)
                    .lineLimit(1)

                Text(localizedHeadline(summary.headlineKey))
                    .font(NLTypography.heroGameTitle)
                    .foregroundStyle(NLColor.textPrimary)
                    .lineLimit(2)

                if let contextSubtitle = contextLine {
                    Text(contextSubtitle)
                        .font(NLTypography.statusLine)
                        .foregroundStyle(NLColor.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: NLSpacing.space2)

            if summary.hasSummary, let percentage = summary.stabilityPercentage {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(percentage)%")
                        .font(NLTypography.metricsNumber)
                        .foregroundStyle(color(forTone: summary.stabilityTone))
                    if let minPing = summary.minPingMs, let maxPing = summary.maxPingMs {
                        Text("\(Int(minPing.rounded()))–\(Int(maxPing.rounded())) ms")
                            .font(NLTypography.technicalEvidence)
                            .foregroundStyle(NLColor.textTertiary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var headerKicker: String {
        let baseKey = isOverview ? "history.stability.title_overview" : "history.stability.title_game"
        return AppLocalization.string(baseKey, comment: "")
    }

    private var contextLine: String? {
        var parts: [String] = []
        if let network = summary.summaryNetworkType {
            parts.append(localizedNetworkLabel(network))
        }
        if let region = summary.summaryRegionId, !region.isEmpty {
            parts.append(region)
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }

    // MARK: - Gráfico de Ping (com segmentação rigorosa)

    private var pingEvolutionChart: some View {
        VStack(alignment: .leading, spacing: NLSpacing.space2) {
            if let index = activePointIndex, summary.points.indices.contains(index) {
                pointReadout(summary.points[index])
            }

            GeometryReader { proxy in
                let size = proxy.size
                let positions = chartPositions(for: summary.points, in: size)
                let curveColor = chartLineColor

                Canvas { context, canvasSize in
                    let horizontalPadding: CGFloat = 8
                    let topPadding: CGFloat = 10
                    let bottomPadding: CGFloat = 10
                    let plotWidth = max(1, canvasSize.width - horizontalPadding * 2)
                    let plotHeight = max(1, canvasSize.height - topPadding - bottomPadding)

                    for fraction in [0.0, 0.5, 1.0] {
                        let y = topPadding + plotHeight * CGFloat(fraction)
                        var gridPath = Path()
                        gridPath.move(to: CGPoint(x: horizontalPadding, y: y))
                        gridPath.addLine(to: CGPoint(x: horizontalPadding + plotWidth, y: y))
                        context.stroke(
                            gridPath,
                            with: .color(Color.white.opacity(0.06)),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                        )
                    }

                    // Desenha traços apenas onde connectToPrevious é true (nunca cruza redes/regiões)
                    for idx in summary.points.indices {
                        guard idx > 0, summary.points[idx].connectToPrevious else { continue }
                        var seg = Path()
                        seg.move(to: positions[idx - 1])
                        seg.addLine(to: positions[idx])
                        context.stroke(
                            seg,
                            with: .color(curveColor.opacity(0.85)),
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                        )
                    }

                    for idx in summary.points.indices {
                        let center = positions[idx]
                        let isSelected = idx == activePointIndex
                        let dotColor = color(forVerdict: summary.points[idx].verdict)
                        let radius: CGFloat = isSelected ? 5.5 : 3.5

                        if isSelected {
                            let halo = Path(ellipseIn: CGRect(x: center.x - 9, y: center.y - 9, width: 18, height: 18))
                            context.fill(halo, with: .color(dotColor.opacity(0.22)))
                        }

                        let dot = Path(ellipseIn: CGRect(
                            x: center.x - radius,
                            y: center.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        ))
                        context.fill(dot, with: .color(dotColor))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture().onEnded { value in
                        let closest = nearestPointIndex(to: value.location, positions: positions)
                        if reduceMotion {
                            selectedPointIndex = closest
                        } else {
                            withAnimation(.easeOut(duration: 0.16)) {
                                selectedPointIndex = closest
                            }
                        }
                    }
                )
            }
            .frame(height: 112)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(chartAccessibilityText)
        }
    }

    private func pointReadout(_ point: StabilityPointDTO) -> some View {
        let date = Date(timeIntervalSince1970: Double(point.capturedAtEpochMs) / 1000.0)
        var parts: [String] = ["\(Int(point.pingMs.rounded())) ms"]
        if let jitter = point.jitterMs {
            parts.append("Jitter \(Int(jitter.rounded())) ms")
        }
        if let loss = point.packetLossPercentage {
            let lossText = loss <= 0.05 ? "0%" : String(format: "%.1f%%", loss)
            parts.append("\(lossText) \(AppLocalization.string("history.stability.ring.loss", comment: "").lowercased())")
        }
        if let network = point.networkType {
            parts.append(localizedNetworkLabel(network))
        }
        parts.append(date.formatted(date: .abbreviated, time: .shortened))

        return HStack(spacing: 6) {
            Circle()
                .fill(color(forVerdict: point.verdict))
                .frame(width: 7, height: 7)
            Text(parts.joined(separator: " · "))
                .font(NLTypography.monospaceMetrics)
                .foregroundStyle(NLColor.textSecondary)
                .lineLimit(2)
        }
    }

    // MARK: - Estado sem curva (< 3 checks comparáveis no mesmo segmento)

    private var insufficientCurveView: some View {
        VStack(alignment: .leading, spacing: NLSpacing.space2) {
            if let latest = summary.latest {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color(forVerdict: latest.verdict))
                        .frame(width: 8, height: 8)
                    Text("\(AppLocalization.string("history.stability.latest_check", comment: "")): \(Int(latest.pingMs.rounded())) ms")
                        .font(NLTypography.statusLine)
                        .foregroundStyle(NLColor.textPrimary)
                }
            }

            Text(LocalizedStringKey("history.stability.minimum_checks"))
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 4 Anéis de Telemetria

    private func ringsSection(_ rings: StabilityRingsDTO) -> some View {
        let useGrid = dynamicTypeSize.isAccessibilitySize
        return Group {
            if useGrid {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NLSpacing.space3) {
                    ringItems(rings)
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: NLSpacing.space2) {
                        ringItems(rings)
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NLSpacing.space3) {
                        ringItems(rings)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func ringItems(_ rings: StabilityRingsDTO) -> some View {
        StabilityRingGauge(
            label: AppLocalization.string("history.stability.ring.ping", comment: ""),
            metric: rings.ping,
            valueText: formatMs(rings.ping.value)
        )
        StabilityRingGauge(
            label: AppLocalization.string("history.stability.ring.jitter", comment: ""),
            metric: rings.jitter,
            valueText: formatMs(rings.jitter.value)
        )
        StabilityRingGauge(
            label: AppLocalization.string("history.stability.ring.loss", comment: ""),
            metric: rings.loss,
            valueText: formatLoss(rings.loss.value)
        )
        StabilityRingGauge(
            label: AppLocalization.string("history.stability.ring.load", comment: ""),
            metric: rings.load,
            valueText: formatSignedMs(rings.load.value)
        )
    }

    private var inconclusiveFooter: some View {
        let text: String = if summary.inconclusiveCount == 1 {
            AppLocalization.string("history.stability.inconclusive.singular", comment: "")
        } else {
            String(format: AppLocalization.string("history.stability.inconclusive.plural %d", comment: ""), summary.inconclusiveCount)
        }
        return Text(text)
            .font(NLTypography.footnote)
            .foregroundStyle(NLColor.textTertiary)
    }

    // MARK: - Helpers de geometria & formato

    private var chartLineColor: Color {
        if summary.hasMixedContexts {
            return NLColor.textSecondary
        }
        return color(forTone: summary.stabilityTone)
    }

    private func chartPositions(for points: [StabilityPointDTO], in size: CGSize) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let horizontalPadding: CGFloat = 8
        let verticalPadding: CGFloat = 12
        let plotWidth = max(1, size.width - horizontalPadding * 2)
        let plotHeight = max(1, size.height - verticalPadding * 2)

        let pings = points.map(\.pingMs)
        let minPing = pings.min() ?? 0
        let maxPing = pings.max() ?? 0
        let span = max(maxPing - minPing, 10.0)
        let baseline = max(0, minPing - span * 0.15)
        let top = maxPing + span * 0.15
        let effectiveSpan = max(top - baseline, 1.0)

        return points.enumerated().map { index, point in
            let xFraction: CGFloat = points.count == 1 ? 0.5 : CGFloat(index) / CGFloat(points.count - 1)
            let yNormalized = CGFloat((point.pingMs - baseline) / effectiveSpan)
            let x = horizontalPadding + xFraction * plotWidth
            let y = verticalPadding + (1.0 - min(max(yNormalized, 0), 1)) * plotHeight
            return CGPoint(x: x, y: y)
        }
    }

    private func nearestPointIndex(to location: CGPoint, positions: [CGPoint]) -> Int? {
        positions.enumerated().min { lhs, rhs in
            let d1 = hypot(lhs.element.x - location.x, lhs.element.y - location.y)
            let d2 = hypot(rhs.element.x - location.x, rhs.element.y - location.y)
            return d1 < d2
        }?.offset
    }

    private var chartAccessibilityText: String {
        let minStr = summary.minPingMs.map { "\(Int($0.rounded()))" } ?? "—"
        let maxStr = summary.maxPingMs.map { "\(Int($0.rounded()))" } ?? "—"
        let pctStr = summary.stabilityPercentage.map { "\($0)%" } ?? "—"
        let detail = "\(summary.points.count) checks, \(minStr)–\(maxStr) ms, \(pctStr)"
        return String(format: AppLocalization.string("history.stability.chart_a11y %@", comment: ""), detail)
    }

    private func formatMs(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded())) ms"
    }

    private func formatSignedMs(_ value: Double?) -> String {
        guard let value else { return "—" }
        let rounded = Int(value.rounded())
        return rounded >= 0 ? "+\(rounded) ms" : "\(rounded) ms"
    }

    private func formatLoss(_ value: Double?) -> String {
        guard let value else { return "—" }
        if value <= 0.05 { return "0%" }
        return String(format: "%.1f%%", value)
    }

    private func localizedHeadline(_ key: String) -> String {
        switch key {
        case "stability.headline.stable":
            return AppLocalization.string("history.stability.headline.stable", comment: "")
        case "stability.headline.never_ready":
            return AppLocalization.string("history.stability.headline.never_ready", comment: "")
        case "stability.headline.moderate":
            return AppLocalization.string("history.stability.headline.moderate", comment: "")
        case "stability.headline.unstable":
            return AppLocalization.string("history.stability.headline.unstable", comment: "")
        case "stability.headline.insufficient":
            return AppLocalization.string("history.stability.headline.insufficient", comment: "")
        default:
            return AppLocalization.string("history.stability.headline.empty", comment: "")
        }
    }
}

private struct StabilityRingGauge: View {
    let label: String
    let metric: StabilityRingMetricDTO
    let valueText: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(metric.fillRatio, 0), 1)))
                    .stroke(
                        color(forTone: metric.tone),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(valueText)
                    .font(NLTypography.statusLine)
                    .foregroundStyle(metric.value == nil ? NLColor.textTertiary : NLColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 4)
            }
            .frame(width: 58, height: 58)

            Text(label)
                .font(NLTypography.metricsLabel)
                .tracking(0.8)
                .foregroundStyle(NLColor.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(valueText)")
    }
}

private func color(forTone tone: String) -> Color {
    switch tone.uppercased() {
    case "OK": return NLColor.semanticReady
    case "WARN": return NLColor.semanticCaution
    case "BAD": return NLColor.semanticNotReady
    default: return NLColor.textSecondary
    }
}

private func color(forVerdict verdict: String) -> Color {
    switch verdict.uppercased() {
    case "READY": return NLColor.semanticReady
    case "CAUTION": return NLColor.semanticCaution
    case "NOT_READY": return NLColor.semanticNotReady
    default: return NLColor.textSecondary
    }
}

func localizedNetworkLabel(_ network: String) -> String {
    switch network.uppercased() {
    case "WIFI": return AppLocalization.string("history.filter.wifi", comment: "")
    case "CELLULAR": return AppLocalization.string("history.filter.cellular", comment: "")
    case "ETHERNET": return "Ethernet"
    default: return AppLocalization.string("history.network.other", comment: "")
    }
}
