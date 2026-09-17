import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

struct DeepCheckFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @State private var presentation: Presentation = .intro
    @State private var samples: [ProbeSample] = []
    @State private var restSamples: [ProbeSample] = []
    @State private var coordinator: DeepCheckSessionCoordinator
    @State private var showingDetails = false

    private let resolvedContext: ResolvedMeasurementContext
    /// Nome localizado do jogo, resolvido pelo catálogo em quem inicia esta
    /// tela — o Deep Check nunca deve hardcodar ou inferir o jogo sozinho.
    private let gameName: String
    private let historyRepository: any MeasurementHistoryRepository
    private let usesFixture: Bool

    init(
        resolvedContext: ResolvedMeasurementContext,
        gameName: String,
        historyRepository: any MeasurementHistoryRepository = NoopMeasurementHistoryRepository()
    ) {
        self.resolvedContext = resolvedContext
        self.gameName = gameName
        self.historyRepository = historyRepository
        usesFixture = UITestFixtures.isEnabled("-ui-fixture-deep-result")
        _coordinator = State(initialValue: DeepCheckTransportComposition.make(historyRepository: historyRepository))
        if usesFixture {
            _presentation = State(initialValue: .result(UITestFixtures.validDeepResult, .measured))
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch presentation {
                case .intro:
                    intro
                case .requiresWiFi:
                    requiresWiFi
                case let .measuring(phase):
                    measuring(phase)
                case let .result(result, availability):
                    resultView(result, availability: availability)
                case .inconclusive:
                    terminal(kind: .inconclusive)
                case .cancelled:
                    terminal(kind: .cancelled)
                }
            }
            .background(NolaggyScreenBackground())
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background else { return }
            Task { @MainActor in
                await coordinator.appDidEnterBackground()
                await refreshState()
            }
        }
        .sheet(isPresented: $showingDetails) {
            if case let .result(result, _) = presentation {
                DeepCheckDetailsView(result: result, resolvedContext: resolvedContext, gameName: gameName)
            }
        }
    }

    private var intro: some View {
        VStack(spacing: NLSpacing.xl) {
            titleHeader
            Spacer(minLength: NLSpacing.xs)
            VStack(spacing: NLSpacing.md) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(NLColor.accentPrimary)
                    .frame(width: 72, height: 72)
                    .background(NLColor.accentPrimarySubtle, in: Circle())
                    .accessibilityHidden(true)
                Text("deep_check.intro.title")
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                Text("deep_check.intro.message")
                    .font(NLTypography.body)
                    .foregroundStyle(NLColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("deep_check.intro.wifi")
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textTertiary)
            }
            .padding(.horizontal, NLSpacing.xl)
            Spacer()
            VStack(spacing: NLSpacing.sm) {
                PrimaryButton(title: "deep_check.intro.start", action: start)
                    .accessibilityIdentifier("deep-check-start")
                PrimaryButton(title: "deep_check.intro.not_now", style: .secondaryOutline, action: { dismiss() })
            }
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
        .padding(.vertical, NLSpacing.lg)
    }

    private var requiresWiFi: some View {
        VStack(spacing: NLSpacing.xl) {
            titleHeader
            Spacer()
            VStack(spacing: NLSpacing.md) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(NLColor.textSecondary)
                Text("deep_check.wifi.title").font(NLTypography.headline).foregroundStyle(NLColor.textPrimary)
                Text("deep_check.wifi.message")
                    .font(NLTypography.body).foregroundStyle(NLColor.textSecondary)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "deep_check.wifi.action", style: .secondaryOutline, action: { dismiss() })
            }
            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
    }

    private func measuring(_ phase: DeepCheckPhase) -> some View {
        VStack(spacing: NLSpacing.xl) {
            titleHeader
            Spacer(minLength: NLSpacing.xs)
            VStack(spacing: NLSpacing.sm) {
                Text(phase == .rest ? "deep_check.phase.rest_progress" : "deep_check.phase.load_progress")
                    .font(NLTypography.headline).foregroundStyle(NLColor.textPrimary).multilineTextAlignment(.center)
                phaseProgressIndicator(phase)
                measurementContext
                Text(String(format: NSLocalizedString("deep_check.phase.remaining", comment: ""), estimatedSecondsRemaining))
                    .font(NLTypography.footnote).foregroundStyle(NLColor.textSecondary)
            }
            MeasurementPulse(
                phase: phase == .rest ? .deepIdle : .deepLoad,
                phaseLabel: phase == .rest ? "deep_check.phase.rest" : "deep_check.phase.load",
                progress: Double(samples.count) / Double(ProbeAcceptancePolicy.plannedProbeCount),
                currentRTT: ObservedDeepMetrics(samples: samples).currentRTT,
                measuringLabel: "quick_check.measuring.waiting",
                currentRTTLabel: "deep_check.phase.current_rtt",
                phaseAccessibilityLabel: String(localized: phase == .rest ? "deep_check.phase.rest" : "deep_check.phase.load"),
                currentRTTAccessibilityLabel: String(localized: "deep_check.phase.current_rtt")
            )
            LatencyGraph(
                values: samples.sorted { $0.sequence < $1.sequence }.compactMap(\.roundTripMilliseconds),
                awaitingLabel: "quick_check.measuring.awaiting_samples",
                accessibilityLabel: String(localized: phase == .rest ? "deep_check.phase.rest_message" : "deep_check.phase.load_message"),
                comparisonValues: restSamples.sorted { $0.sequence < $1.sequence }.compactMap(\.roundTripMilliseconds)
            )
            if phase == .load {
                HStack(spacing: NLSpacing.md) {
                    Label("deep_check.graph.rest", systemImage: "minus")
                    Label("deep_check.graph.load", systemImage: "line.diagonal")
                }
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textTertiary)
                .accessibilityElement(children: .combine)
            }
            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
    }

    private func resultView(_ result: DeepCheckResult, availability: DeepCheckLoadAvailability) -> some View {
        let interpretation = ResultInterpreter.interpret(result.restResult, profile: resolvedContext.profileID)
        return ScrollView {
            VStack(spacing: NLSpacing.lg) {
                titleHeader
                NolaggyScore(
                    outcome: .revealed(score: interpretation.score, classification: scoreClassification(interpretation.scoreBand)),
                    style: .standard,
                    classificationLabel: LocalizedStringKey(String(format: NSLocalizedString("deep_check.result.rest", comment: ""), NSLocalizedString(interpretation.headlineKey.rawValue, comment: ""))),
                    accessibilityDescription: String(format: NSLocalizedString("deep_check.result.rest", comment: ""), "Nolaggy Score \(interpretation.score)")
                )
                measurementContext
                impactCard(result.metrics.loadImpact, availability: availability)
                if result.metrics.load != nil {
                    comparisonRows(result.metrics)
                }
                PrimaryButton(title: "deep_check.result.details", action: { showingDetails = true })
                PrimaryButton(title: "deep_check.result.retry", style: .secondaryOutline, action: restart)
            }
            .padding(.horizontal, NLSpacing.screenMarginHorizontal)
            .padding(.vertical, NLSpacing.lg)
        }
    }

    @ViewBuilder
    private func impactCard(_ impact: DeepCheckLoadImpact?, availability: DeepCheckLoadAvailability) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xs) {
            Label(impact.map(impactTitle) ?? "deep_check.result.load_unavailable_title", systemImage: impact.map(impactIcon) ?? "exclamationmark.circle")
                .font(NLTypography.bodyEmphasis).foregroundStyle(impact.map(impactColor) ?? NLColor.textPrimary)
            if let impact {
                Text(impactExplanation(impact)).font(NLTypography.footnote).foregroundStyle(NLColor.textSecondary).fixedSize(horizontal: false, vertical: true)
                Text(String(format: NSLocalizedString("deep_check.result.impact_value", comment: ""), Int(impact.increaseMilliseconds.rounded())))
                    .font(NLTypography.headline).foregroundStyle(NLColor.accentPrimary)
            } else if availability == .loadUnavailable {
                Text("deep_check.result.load_unavailable").font(NLTypography.footnote).foregroundStyle(NLColor.textSecondary)
            } else {
                Text("deep_check.result.comparison_unavailable").font(NLTypography.footnote).foregroundStyle(NLColor.textSecondary)
            }
        }
        .padding(NLSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
    }

    private func comparisonRows(_ metrics: DeepCheckMetrics) -> some View {
        VStack(spacing: 1) {
            comparisonRow("quick_check.result.ping", rest: metrics.rest.p50Milliseconds, load: metrics.load?.p50Milliseconds)
            Divider().overlay(NLColor.borderSubtle)
            comparisonRow("quick_check.result.jitter", rest: metrics.rest.jitterMilliseconds, load: metrics.load?.jitterMilliseconds)
        }
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
        .overlay { RoundedRectangle(cornerRadius: NLRadius.card).stroke(NLColor.borderSubtle, lineWidth: NLStroke.hairline) }
    }

    /// Reforço visual compacto de "fase 1 de 2" — o texto do título já diz isso
    /// por extenso (e é o que o VoiceOver lê); os pontos são só um reforço
    /// visual rápido, por isso ficam ocultos do leitor de tela.
    private func phaseProgressIndicator(_ phase: DeepCheckPhase) -> some View {
        HStack(spacing: NLSpacing.xs) {
            Circle().fill(NLColor.accentPrimary).frame(width: 6, height: 6)
            Rectangle()
                .fill(phase == .load ? NLColor.accentPrimary : NLColor.borderSubtle)
                .frame(width: 20, height: 2)
            Circle()
                .fill(phase == .load ? NLColor.accentPrimary : NLColor.borderSubtle)
                .frame(width: 6, height: 6)
        }
        .accessibilityHidden(true)
    }

    private var measurementContext: some View {
        VStack(spacing: NLSpacing.xxs) {
            Text(String(format: NSLocalizedString("deep_check.measurement.title %@", comment: ""), gameName))
                .font(NLTypography.callout.weight(.semibold)).foregroundStyle(NLColor.textPrimary)
            Label("deep_check.measurement.context", systemImage: "mappin.and.ellipse")
                .font(NLTypography.footnote).foregroundStyle(NLColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func comparisonRow(_ label: LocalizedStringKey, rest: Double?, load: Double?) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
            Text(label).font(NLTypography.bodyEmphasis).foregroundStyle(NLColor.textPrimary)
            ViewThatFits(in: .horizontal) {
                HStack { value("deep_check.result.rest_value", rest); Spacer(); value("deep_check.result.load_value", load) }
                VStack(alignment: .leading, spacing: NLSpacing.xs) { value("deep_check.result.rest_value", rest); value("deep_check.result.load_value", load) }
            }
        }
        .padding(NLSpacing.cardPadding)
    }

    private func value(_ label: LocalizedStringKey, _ milliseconds: Double?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(NLTypography.caption).foregroundStyle(NLColor.textTertiary)
            Text(milliseconds.map { "\(Int($0.rounded())) ms" } ?? "—").font(NLTypography.callout).foregroundStyle(NLColor.textSecondary)
        }
    }

    private func terminal(kind: StatusMessage.Kind) -> some View {
        VStack(spacing: NLSpacing.xl) {
            titleHeader
            Spacer()
            StatusMessage(kind: kind, message: kind == .inconclusive ? "deep_check.inconclusive.message" : "deep_check.cancelled.message", actionTitle: "deep_check.result.retry", action: restart)
            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
    }

    private var titleHeader: some View {
        NolaggyBackHeader(action: cancelOrDismiss, accessibilityIdentifier: "deep-check-back")
    }

    private func start() {
        Task { @MainActor in
            let probePlan = QuickCheckPlan(endpoint: MeasurementEndpoint(host: resolvedContext.destination.host, port: resolvedContext.destination.port))
            let plan = DeepCheckPlan(restProbePlan: probePlan, loadProbePlan: probePlan, loadRequest: LoadRequest(url: DeepCheckLoadEndpoint.pilot))
            do {
                _ = try await coordinator.start(resolvedContext: resolvedContext, plan: plan)
                await refreshState()
                await waitForTerminalState()
            } catch DeepCheckSessionError.requiresWiFi {
                presentation = .requiresWiFi
            } catch { }
        }
    }

    private func waitForTerminalState() async {
        while true {
            if let progress = await coordinator.measurementProgress() {
                samples = progress.receivedSamples
                restSamples = progress.restSamples
            }
            await refreshState()
            guard case .measuring = presentation else { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func refreshState() async {
        switch await coordinator.sessionState() {
        case .idle: break
        case .requiresWiFi: presentation = .requiresWiFi
        case let .measuring(_, phase): presentation = .measuring(phase)
        case let .completed(_, .completed(result), availability): presentation = .result(result, availability)
        case .completed: presentation = .inconclusive
        case .cancelled: presentation = .cancelled
        }
    }

    private func restart() { samples = []; restSamples = []; presentation = .intro }
    private func cancelOrDismiss() {
        Task { @MainActor in
            if let session = await coordinator.currentSession() { await coordinator.cancel(id: session.id) }
            dismiss()
        }
    }
    private func scoreClassification(_ value: ResultClass) -> NLScoreClassification {
        switch value { case .excellent: .excellent; case .great: .great; case .unstable: .unstable; case .lagRisk: .lagRisk }
    }

    private func impactTitle(_ impact: DeepCheckLoadImpact) -> LocalizedStringKey {
        impact.classification == .material ? "deep_check.result.impact_material" : "deep_check.result.impact"
    }

    private func impactExplanation(_ impact: DeepCheckLoadImpact) -> LocalizedStringKey {
        impact.classification == .material ? "deep_check.result.impact_material_explanation" : "deep_check.result.impact_explanation"
    }

    private func impactIcon(_ impact: DeepCheckLoadImpact) -> String {
        impact.classification == .material ? "exclamationmark.triangle" : "arrow.left.arrow.right"
    }

    private func impactColor(_ impact: DeepCheckLoadImpact) -> Color {
        impact.classification == .material ? NLColor.scoreLagRisk : NLColor.textPrimary
    }

    private var estimatedSecondsRemaining: Int {
        let phaseRemaining = max(0, ProbeAcceptancePolicy.sendWindowSeconds - Double(samples.count) / 2)
        return Int((phaseRemaining + (presentationIsRest ? ProbeAcceptancePolicy.sendWindowSeconds : 0)).rounded(.up))
    }

    private var presentationIsRest: Bool {
        if case .measuring(.rest) = presentation { return true }
        return false
    }

    private enum Presentation { case intro, requiresWiFi, measuring(DeepCheckPhase), result(DeepCheckResult, DeepCheckLoadAvailability), inconclusive, cancelled }
}

private struct DeepCheckDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let result: DeepCheckResult
    let resolvedContext: ResolvedMeasurementContext
    let gameName: String
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NLSpacing.lg) {
                    VStack(spacing: NLSpacing.xxs) {
                        Text(String(format: NSLocalizedString("deep_check.measurement.title %@", comment: ""), gameName))
                            .font(NLTypography.callout.weight(.semibold)).foregroundStyle(NLColor.textPrimary)
                        Label("deep_check.measurement.context", systemImage: "mappin.and.ellipse")
                            .font(NLTypography.footnote).foregroundStyle(NLColor.textTertiary)
                    }
                    if let impact = result.metrics.loadImpact {
                        VStack(alignment: .leading, spacing: NLSpacing.xs) {
                            Label(impact.classification == .material ? "deep_check.result.impact_material" : "deep_check.result.impact", systemImage: impact.classification == .material ? "exclamationmark.triangle" : "arrow.left.arrow.right")
                                .font(NLTypography.bodyEmphasis)
                                .foregroundStyle(impact.classification == .material ? NLColor.scoreLagRisk : NLColor.textPrimary)
                            Text(impact.classification == .material ? "deep_check.result.impact_material_explanation" : "deep_check.result.impact_explanation").font(NLTypography.footnote).foregroundStyle(NLColor.textSecondary)
                            Text(String(format: NSLocalizedString("deep_check.result.impact_value", comment: ""), Int(impact.increaseMilliseconds.rounded())))
                                .font(NLTypography.headline).foregroundStyle(NLColor.accentPrimary)
                        }
                        .padding(NLSpacing.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
                    }
                    detailSection("deep_check.result.rest_value", metrics: result.metrics.rest)
                    if let load = result.metrics.load { detailSection("deep_check.result.load_value", metrics: load) }
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal).padding(.vertical, NLSpacing.lg)
            }
            .background(NolaggyScreenBackground())
            .navigationTitle(Text("deep_check.result.details"))
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NolaggyBackButton(action: { dismiss() }, accessibilityIdentifier: "deep-check-details-back")
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    private func detailSection(_ title: LocalizedStringKey, metrics: QualityMetrics) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            Text(title).font(NLTypography.headline).foregroundStyle(NLColor.textPrimary)
            MetricRow(label: "details.p50", value: formatted(metrics.p50Milliseconds), unit: "ms", style: .detailed)
            MetricRow(label: "details.p95", value: formatted(metrics.p95Milliseconds), unit: "ms", style: .detailed)
            MetricRow(label: "details.p99", value: formatted(metrics.p99Milliseconds), unit: "ms", style: .detailed)
            MetricRow(label: "quick_check.result.jitter", value: formatted(metrics.jitterMilliseconds), unit: "ms", style: .detailed)
            MetricRow(label: "quick_check.result.loss", value: "\(Int(metrics.packetLossPercentage.rounded()))", unit: "%", style: .detailed)
            MetricRow(label: "quick_check.result.spikes", value: String(metrics.spikeCount), style: .detailed)
            MetricRow(label: "details.worst_spike", value: formatted(metrics.worstSpikeMilliseconds), unit: "ms", style: .detailed)
        }
        .padding(NLSpacing.cardPadding).background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }
    private func formatted(_ value: Double?) -> String { value.map { String(Int($0.rounded())) } ?? "—" }
}

private struct ObservedDeepMetrics {
    let samples: [ProbeSample]
    var currentRTT: String? { samples.last?.roundTripMilliseconds.map { "\(Int($0.rounded())) ms" } }
}

private enum DeepCheckTransportComposition {
    static func make(historyRepository: any MeasurementHistoryRepository) -> DeepCheckSessionCoordinator {
        #if !targetEnvironment(simulator)
        DeepCheckSessionCoordinator(transport: NWConnectionMeasurementTransport(), loadTransport: URLSessionLoadTransport(), pathObserver: NWPathMonitorNetworkPathObserver(), wifiAvailability: NWPathWiFiAvailability(), historyRepository: historyRepository)
        #else
        DeepCheckSessionCoordinator(transport: NoopMeasurementTransport(), loadTransport: NoopLoadTransport(), pathObserver: NoopNetworkPathObserver(), wifiAvailability: NoopWiFiAvailability(), historyRepository: historyRepository)
        #endif
    }
}
