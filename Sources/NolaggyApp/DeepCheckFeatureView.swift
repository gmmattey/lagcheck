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
    @State private var showingBooster = false
    @State private var boosterCoordinator: ConnectionBoosterCoordinator

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
        _coordinator = State(initialValue: MeasurementTransportFactory.deepCheckCoordinator(historyRepository: historyRepository))
        _boosterCoordinator = State(initialValue: ConnectionBoosterCoordinator(service: GeminiConnectionBoosterService()))
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
        .sheet(isPresented: $showingBooster) {
            if case let .result(result, _) = presentation {
                let req = ConnectionBoosterRequest(
                    gameName: gameName,
                    platform: resolvedContext.context.platform,
                    networkKind: resolvedContext.context.equipmentConnection ?? .wifi,
                    p50Milliseconds: result.metrics.rest.p50Milliseconds ?? 0.0,
                    jitterMilliseconds: result.metrics.rest.jitterMilliseconds ?? 0.0,
                    packetLossRate: result.metrics.rest.packetLossPercentage / 100.0,
                    loadImpactMilliseconds: result.metrics.loadImpact?.increaseMilliseconds
                )
                ConnectionBoosterSheet(request: req, coordinator: boosterCoordinator)
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
        DeepCheckResultView(
            result: result,
            availability: availability,
            profileID: resolvedContext.profileID,
            gameName: gameName,
            showDetails: { showingDetails = true },
            showBooster: { showingBooster = true },
            retry: restart,
            exit: cancelOrDismiss
        )
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

private struct ObservedDeepMetrics {
    let samples: [ProbeSample]
    var currentRTT: String? { samples.last?.roundTripMilliseconds.map { "\(Int($0.rounded())) ms" } }
}
