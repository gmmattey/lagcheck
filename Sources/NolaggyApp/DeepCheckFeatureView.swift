import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

struct DeepCheckFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var presentation: Presentation = .intro
    @State private var samples: [ProbeSample] = []
    @State private var restSamples: [ProbeSample] = []
    @State private var coordinator: DeepCheckSessionCoordinator
    @State private var showingDetails = false
    @State private var showingBooster = false
    @State private var boosterCoordinator: ConnectionBoosterCoordinator
    @State private var hasCellularConsent = false

    private let resolvedContext: ResolvedMeasurementContext
    /// Nome localizado do jogo, resolvido pelo catálogo em quem inicia esta
    /// tela — o Deep Check nunca deve hardcodar ou inferir o jogo sozinho.
    private let gameName: String
    private let historyRepository: any MeasurementHistoryRepository
    private let usesFixture: Bool
    private let autoStart: Bool

    init(
        resolvedContext: ResolvedMeasurementContext,
        gameName: String,
        historyRepository: any MeasurementHistoryRepository = NoopMeasurementHistoryRepository(),
        autoStart: Bool = true
    ) {
        self.resolvedContext = resolvedContext
        self.gameName = gameName
        self.historyRepository = historyRepository
        self.autoStart = autoStart
        usesFixture = UITestFixtures.isEnabled("-ui-fixture-deep-result") || UITestFixtures.isEnabled("-ui-fixture-deep-inconclusive")
        _coordinator = State(initialValue: MeasurementTransportFactory.deepCheckCoordinator(historyRepository: historyRepository))
        _boosterCoordinator = State(initialValue: ConnectionBoosterCoordinator(service: GeminiConnectionBoosterService()))
        if UITestFixtures.isEnabled("-ui-fixture-deep-inconclusive") {
            _presentation = State(initialValue: .inconclusive)
        } else if usesFixture {
            _presentation = State(initialValue: .result(UITestFixtures.validDeepResult, .measured))
        } else if autoStart {
            _presentation = State(initialValue: .measuring(.rest))
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
                case .cellularConsent:
                    cellularConsentView
                case let .measuring(phase):
                    measuring(phase)
                case let .result(result, availability):
                    resultView(result, availability: availability)
                case .inconclusive:
                    inconclusiveResultView
                case .cancelled:
                    terminal(kind: .cancelled)
                }
            }
            .background(NolaggyScreenBackground())
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if autoStart && !usesFixture {
                start()
            }
        }
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
                let isWiFi = (resolvedContext.context.equipmentConnection ?? .wifi) == .wifi
                let telemetry = WiFiLocalTelemetry(
                    gatewayRTTMedianMs: result.metrics.rest.p50Milliseconds,
                    gatewayJitterMs: result.metrics.rest.jitterMilliseconds,
                    tailRatioP95P50: result.metrics.rest.p95ToP50Ratio,
                    loadDeltaP50Ms: result.metrics.loadImpact?.increaseMilliseconds,
                    validSampleCount: result.metrics.rest.validResponseCount,
                    plannedSampleCount: result.metrics.rest.validResponseCount,
                    isWiFi: isWiFi
                )
                let wifiBandEstimate = WiFiBandEvaluator.evaluate(telemetry: telemetry).diagnostic

                let req = ConnectionBoosterRequest(
                    gameName: gameName,
                    platform: resolvedContext.context.platform,
                    networkKind: resolvedContext.context.equipmentConnection ?? .wifi,
                    p50Milliseconds: result.metrics.rest.p50Milliseconds ?? 0.0,
                    jitterMilliseconds: result.metrics.rest.jitterMilliseconds ?? 0.0,
                    packetLossRate: result.metrics.rest.packetLossPercentage / 100.0,
                    loadImpactMilliseconds: result.metrics.loadImpact?.increaseMilliseconds,
                    wifiBandEstimate: wifiBandEstimate
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
                PrimaryButton(title: "deep_check.intro.start", action: { start() })
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

    private var cellularConsentView: some View {
        CellularDataConsentSheet(
            onConfirm: {
                hasCellularConsent = true
                presentation = .measuring(.rest)
                start(withConsent: true)
            },
            onQuickCheckOnly: {
                dismiss()
            },
            onCancel: {
                dismiss()
            }
        )
    }

    private var friendlyRegion: String {
        let ident = locale.identifier.lowercased()
        let lang = ident.hasPrefix("pt") ? "pt-BR" : (ident.hasPrefix("es") ? "es" : "en")
        return GlobalProbeRegistry.friendlyLabel(for: resolvedContext.regionID, languageCode: lang)
    }

    private func measuring(_ phase: DeepCheckPhase) -> some View {
        let isWiFi = (resolvedContext.context.equipmentConnection ?? .wifi) == .wifi

        return VStack(spacing: NLSpacing.lg) {
            titleHeader
            Spacer(minLength: NLSpacing.xs)

            MeasurementLiveTrail(
                isWiFi: isWiFi,
                destinationName: friendlyRegion,
                sampleCount: samples.count,
                isUnderStress: phase == .load,
                isPhaseRest: phase == .rest,
                phaseTitle: phase == .rest ? "deep_check.phase.rest" : "deep_check.phase.load",
                phaseSubtitle: LocalizedStringKey(gameName)
            )

            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
    }

    private func resultView(_ result: DeepCheckResult, availability: DeepCheckLoadAvailability) -> some View {
        CheckCompletoResultView(
            result: result,
            profileID: resolvedContext.profileID,
            gameName: gameName,
            platform: resolvedContext.context.platform,
            regionFriendlyName: friendlyRegion,
            isWiFi: (resolvedContext.context.equipmentConnection ?? .wifi) == .wifi,
            natSnapshot: nil,
            showDetails: { showingDetails = true },
            showBooster: { showingBooster = true },
            retry: restart,
            exit: cancelOrDismiss
        )
    }

    private var inconclusiveResultView: some View {
        CheckCompletoResultView(
            result: nil,
            profileID: resolvedContext.profileID,
            gameName: gameName,
            platform: resolvedContext.context.platform,
            regionFriendlyName: friendlyRegion,
            isWiFi: (resolvedContext.context.equipmentConnection ?? .wifi) == .wifi,
            natSnapshot: nil,
            retry: restart,
            exit: cancelOrDismiss
        )
    }

    private func terminal(kind: StatusMessage.Kind) -> some View {
        VStack(spacing: NLSpacing.xl) {
            titleHeader
            Spacer()
            StatusMessage(
                kind: kind,
                message: kind == .inconclusive ? "deep_check.inconclusive.message" : "deep_check.cancelled.message",
                actionTitle: "deep_check.result.retry",
                action: restart
            )
            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
    }

    private var titleHeader: some View {
        NolaggyBackHeader(action: cancelOrDismiss, accessibilityIdentifier: "deep-check-back")
    }

    private func start(withConsent: Bool = false) {
        Task { @MainActor in
            let probePlan = QuickCheckPlan(endpoint: MeasurementEndpoint(
                host: resolvedContext.destination.host,
                port: resolvedContext.destination.port,
                protocolKind: resolvedContext.destination.protocolKind
            ))
            let plan = DeepCheckPlan(restProbePlan: probePlan, loadProbePlan: probePlan, loadRequest: LoadRequest(url: DeepCheckLoadEndpoint.pilot))
            do {
                _ = try await coordinator.start(
                    resolvedContext: resolvedContext,
                    plan: plan,
                    hasCellularConsent: withConsent || hasCellularConsent
                )
                await refreshState()
                await waitForTerminalState()
            } catch DeepCheckSessionError.requiresCellularConsent {
                presentation = .cellularConsent
            } catch DeepCheckSessionError.requiresWiFi {
                presentation = .requiresWiFi
            } catch {
                presentation = .cancelled
            }
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
        case .requiresCellularConsent: presentation = .cellularConsent
        case let .measuring(_, phase): presentation = .measuring(phase)
        case let .completed(_, .completed(result), availability): presentation = .result(result, availability)
        case .completed: presentation = .inconclusive
        case .cancelled: presentation = .cancelled
        }
    }

    private func restart() {
        samples = []
        restSamples = []
        if autoStart {
            presentation = .measuring(.rest)
            start(withConsent: hasCellularConsent)
        } else {
            presentation = .intro
        }
    }

    private func cancelOrDismiss() {
        Task { @MainActor in
            if let session = await coordinator.currentSession() { await coordinator.cancel(id: session.id) }
            dismiss()
        }
    }

    private enum Presentation {
        case intro
        case requiresWiFi
        case cellularConsent
        case measuring(DeepCheckPhase)
        case result(DeepCheckResult, DeepCheckLoadAvailability)
        case inconclusive
        case cancelled
    }
}
