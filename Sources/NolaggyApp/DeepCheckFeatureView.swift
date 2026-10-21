import SwiftUI
import StoreKit
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

struct DeepCheckFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.requestReview) private var requestReview
    @State private var presentation: Presentation = .intro
    @State private var samples: [ProbeSample] = []
    @State private var restSamples: [ProbeSample] = []
    @State private var coordinator: DeepCheckSessionCoordinator
    @State private var showingDetails = false
    @State private var showingBooster = false
    @State private var boosterCoordinator: ConnectionBoosterCoordinator
    @State private var hasCellularConsent = false
    @State private var measurementStartTime: Date?
    @State private var hasTrackedTerminalEvent = false
    @State private var reviewPromptTask: Task<Void, Never>?
    @State private var displayProgress: Double = 0.04

    @State private var activeContext: ResolvedMeasurementContext
    /// Nome localizado do jogo, resolvido pelo catálogo em quem inicia esta
    /// tela — o Deep Check nunca deve hardcodar ou inferir o jogo sozinho.
    private let gameName: String
    private let historyRepository: any MeasurementHistoryRepository
    private let analyticsTracker: any AnalyticsTracker
    private let reviewPromptCoordinator: ReviewPromptCoordinator
    private let usesFixture: Bool
    private let autoStart: Bool
    private let onMeasurementCompleted: (([ProbeSample], MeasurementHistoryEntry?) -> Void)?

    init(
        resolvedContext: ResolvedMeasurementContext,
        gameName: String,
        historyRepository: any MeasurementHistoryRepository = NoopMeasurementHistoryRepository(),
        analyticsTracker: any AnalyticsTracker = NoopAnalyticsTracker(),
        reviewPromptCoordinator: ReviewPromptCoordinator = ReviewPromptCoordinator(),
        autoStart: Bool = true,
        onMeasurementCompleted: (([ProbeSample], MeasurementHistoryEntry?) -> Void)? = nil
    ) {
        _activeContext = State(initialValue: resolvedContext)
        self.gameName = gameName
        self.historyRepository = historyRepository
        self.analyticsTracker = analyticsTracker
        self.reviewPromptCoordinator = reviewPromptCoordinator
        self.autoStart = autoStart
        self.onMeasurementCompleted = onMeasurementCompleted
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
                        .id("deep-check-measuring-view")
                case let .result(result, availability):
                    resultView(result, availability: availability)
                case .inconclusive:
                    inconclusiveResultView
                case .cancelled:
                    terminal(kind: .cancelled)
                }
            }
            .background(NolaggyScreenBackground())
            .navigationBarBackButtonHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if autoStart && !usesFixture {
                start()
            }
        }
        .onChange(of: isMeasurementHapticsActive) { _, isActive in
            if !isActive {
                MeasurementHaptics.stop()
            }
        }
        .onChange(of: scenePhase, initial: false) { _, phase in
            if phase == .background {
                reviewPromptTask?.cancel()
                reviewPromptTask = nil
            }
            guard phase == .background else { return }
            Task { @MainActor in
                await coordinator.appDidEnterBackground()
                await refreshState()
            }
        }
        .onDisappear {
            reviewPromptTask?.cancel()
            reviewPromptTask = nil
        }
        .sheet(isPresented: $showingDetails) {
            if case let .result(result, _) = presentation {
                let evaluation = GameReadinessEvaluator.evaluate(
                    deepCheckResult: result,
                    profile: activeContext.profileID
                )
                TechnicalDetailsView(
                    result: result,
                    evaluation: evaluation,
                    gameName: gameName,
                    regionName: friendlyRegion,
                    onDismiss: { showingDetails = false }
                )
            }
        }
        .sheet(isPresented: $showingBooster) {
            if case let .result(result, _) = presentation,
               let observedPhoneNetwork = activeContext.observedPhoneNetwork {
                let isWiFi = observedPhoneNetwork == .wifi
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
                    platform: activeContext.context.platform,
                    networkKind: observedPhoneNetwork,
                    p50Milliseconds: result.metrics.rest.p50Milliseconds ?? 0.0,
                    jitterMilliseconds: result.metrics.rest.jitterMilliseconds ?? 0.0,
                    packetLossRate: result.metrics.rest.packetLossPercentage / 100.0,
                    loadImpactMilliseconds: result.metrics.loadImpact?.increaseMilliseconds,
                    wifiBandEstimate: wifiBandEstimate,
                    locale: locale.identifier
                )
                ConnectionBoosterSheet(request: req, coordinator: boosterCoordinator)
            } else {
                EmptyView()
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
            onCancel: {
                dismiss()
            }
        )
    }

    private var friendlyRegion: String {
        let ident = locale.identifier.lowercased()
        let lang = ident.hasPrefix("pt") ? "pt-BR" : (ident.hasPrefix("es") ? "es" : "en")
        return GlobalProbeRegistry.friendlyLabel(for: activeContext.regionID, languageCode: lang)
    }

    private func measuring(_ phase: DeepCheckPhase) -> some View {
        let isWiFi = activeContext.observedPhoneNetwork == .wifi

        return VStack(spacing: NLSpacing.lg) {
            titleHeader
            Spacer(minLength: NLSpacing.xs)

            MeasurementLiveTrail(
                isWiFi: isWiFi,
                destinationName: friendlyRegion,
                currentRTT: samples.last?.roundTripMilliseconds,
                progress: displayProgress,
                sampleCount: samples.count,
                isUnderStress: phase == .load,
                isPhaseRest: phase == .rest,
                isHapticsEnabled: isMeasurementHapticsActive,
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
            profileID: activeContext.profileID,
            gameID: activeContext.context.gameID,
            gameName: gameName,
            platform: activeContext.context.platform,
            regionFriendlyName: friendlyRegion,
            destinationKind: destinationKind,
            isWiFi: activeContext.observedPhoneNetwork == .wifi,
            showDetails: { showingDetails = true },
            showBooster: { showingBooster = true },
            retry: restart,
            exit: cancelOrDismiss
        )
        .onAppear {
            let evaluation = GameReadinessEvaluator.evaluate(
                deepCheckResult: result,
                profile: activeContext.profileID
            )
            analyticsTracker.track(.resultViewed(
                gameID: activeContext.context.gameID,
                platform: activeContext.context.platform.rawValue,
                resultClass: evaluation.verdict.rawValue
            ))
        }
    }

    private var inconclusiveResultView: some View {
        CheckCompletoResultView(
            result: nil,
            profileID: activeContext.profileID,
            gameID: activeContext.context.gameID,
            gameName: gameName,
            platform: activeContext.context.platform,
            regionFriendlyName: friendlyRegion,
            destinationKind: destinationKind,
            isWiFi: activeContext.observedPhoneNetwork == .wifi,
            retry: restart,
            exit: cancelOrDismiss
        )
        .onAppear {
            analyticsTracker.track(.resultViewed(
                gameID: activeContext.context.gameID,
                platform: activeContext.context.platform.rawValue,
                resultClass: GameReadinessVerdict.inconclusive.rawValue
            ))
        }
    }

    private var destinationKind: RouteDestinationKind {
        activeContext.strategy == .dedicatedServer ? .dedicatedServer : .regionalReference
    }

    private func terminal(kind: StatusMessage.Kind) -> some View {
        VStack(spacing: 0) {
            titleHeader
            Spacer()
            VStack(spacing: 12) {
                Text(LocalizedStringKey("check.alert.network_changed.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(NLColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(LocalizedStringKey("check.alert.network_changed.message"))
                    .font(.system(size: 14))
                    .foregroundStyle(NLColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                Button(action: restart) {
                    Text(LocalizedStringKey("check.alert.retry"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(NLColor.textPrimary)
                        .padding(.horizontal, 19)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(NLColor.borderStrong, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("retry-check")
            }
            Spacer()
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
    }

    private var titleHeader: some View {
        HStack {
            Button(action: cancelOrDismiss) {
                Text(LocalizedStringKey("check.cancel"))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(NLColor.textSecondary)
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("deep-check-back")

            Spacer()

            Text(gameName)
                .font(NLTypography.monospaceMetrics)
                .foregroundStyle(NLColor.textTertiary)
        }
        .frame(height: 52)
    }

    private var isResultPresentation: Bool {
        switch presentation {
        case .result, .inconclusive:
            true
        default:
            false
        }
    }

    private var isMeasurementHapticsActive: Bool {
        if case .measuring = presentation {
            return true
        }
        return false
    }

    private func start(withConsent: Bool = false) {
        Task { @MainActor in
            let probePlan = QuickCheckPlan(endpoint: MeasurementEndpoint(
                host: activeContext.destination.host,
                port: activeContext.destination.port,
                protocolKind: activeContext.destination.protocolKind
            ))
            let plan = DeepCheckPlan(restProbePlan: probePlan, loadProbePlan: probePlan, loadRequest: LoadRequest(url: DeepCheckLoadEndpoint.pilot))
            do {
                let session = try await coordinator.start(
                    resolvedContext: activeContext,
                    plan: plan,
                    hasCellularConsent: withConsent || hasCellularConsent
                )
                activeContext = session.resolvedContext
                measurementStartTime = Date()
                hasTrackedTerminalEvent = false
                let networkType = activeContext.observedPhoneNetwork?.rawValue ?? "unknown"
                analyticsTracker.track(.lagcheckStarted(
                    gameID: activeContext.context.gameID,
                    platform: activeContext.context.platform.rawValue,
                    networkType: networkType,
                    regionID: activeContext.regionID
                ))
                await refreshState()
                await waitForTerminalState()
            } catch DeepCheckSessionError.requiresCellularConsent {
                presentation = .cellularConsent
            } catch DeepCheckSessionError.requiresWiFi {
                presentation = .requiresWiFi
            } catch {
                presentation = .cancelled
                if !hasTrackedTerminalEvent {
                    hasTrackedTerminalEvent = true
                    analyticsTracker.track(.lagcheckCancelled(
                        gameID: activeContext.context.gameID,
                        platform: activeContext.context.platform.rawValue,
                        networkType: activeContext.observedPhoneNetwork?.rawValue ?? "unknown",
                        regionID: activeContext.regionID,
                        reason: "error"
                    ))
                }
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
            updateDisplayProgress()
            guard case .measuring = presentation else {
                displayProgress = 1.0
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func updateDisplayProgress() {
        let count = Double(samples.count)
        let maxPerPhase = 30.0
        let target: Double
        let cap: Double

        switch presentation {
        case .measuring(.rest):
            target = min(0.48, max(0.04, (count / maxPerPhase) * 0.48))
            cap = 0.49
        case .measuring(.load):
            target = min(0.97, max(0.50, 0.50 + (count / maxPerPhase) * 0.47))
            cap = 0.98
        case .result, .inconclusive:
            displayProgress = 1.0
            return
        default:
            return
        }

        if displayProgress < target {
            displayProgress = min(target, displayProgress + max(0.008, (target - displayProgress) * 0.35))
        } else if displayProgress < cap {
            displayProgress = min(cap, displayProgress + 0.0018)
        }
    }

    private func refreshState() async {
        switch await coordinator.sessionState() {
        case .idle: break
        case .requiresWiFi: presentation = .requiresWiFi
        case .requiresCellularConsent: presentation = .cellularConsent
        case let .measuring(_, phase): presentation = .measuring(phase)
        case let .completed(_, .completed(result), availability):
            presentation = .result(result, availability)
            let entry = MeasurementHistoryEntry.completedDeepCheck(resolvedContext: activeContext, result: result)
            let completedSamples = samples.isEmpty ? restSamples : samples
            onMeasurementCompleted?(completedSamples, entry)

            // Decisão 75 (Fase 2 / Item 6): Gravação do snapshot real para Widgets iOS 17
            // Apenas grava quando o veredito for conclusivo e houver medição de latência válida
            if let verdict = entry.readinessVerdict, verdict != .inconclusive,
               let p50 = result.restResult.metrics.p50Milliseconds, p50 > 0 {
                let widgetSnapshot = WidgetTelemetrySnapshot(
                    gameID: activeContext.context.gameID,
                    gameName: gameName,
                    regionLabel: friendlyRegion,
                    verdict: verdict,
                    rttMedianMs: p50,
                    jitterMs: result.restResult.metrics.jitterMilliseconds ?? 0.0,
                    packetLossPercentage: result.restResult.metrics.packetLossPercentage,
                    bufferbloatGrade: result.metrics.loadImpact?.bufferbloatGrade.rawValue,
                    platform: activeContext.context.platform,
                    declaredExternalLink: activeContext.context.declaredExternalLink,
                    capturedAt: Date()
                )
                if WidgetArtworkSnapshotWriter.saveArtwork(forGameID: activeContext.context.gameID) {
                    SharedAppGroupStore.shared.saveLatestSnapshot(widgetSnapshot)
                } else {
                    SharedAppGroupStore.shared.clearSnapshot()
                }
                WidgetArtworkSnapshotWriter.refreshWidget()
            } else {
                SharedAppGroupStore.shared.clearSnapshot()
                WidgetArtworkSnapshotWriter.refreshWidget()
            }

            if !hasTrackedTerminalEvent {
                hasTrackedTerminalEvent = true

                // Decisão 77: Sistema Unificado de Avaliação In-App (Apple StoreKit)
                // Disparo de delight oportuno: executado estritamente 1 vez por sessão concluída (idempotência),
                // apenas em veredito .ready, 3 checks acumulados e cancelável se a tela for fechada ou entrar em background
                if let verdict = entry.readinessVerdict, verdict == .ready {
                    if reviewPromptCoordinator.recordMeasurementCompleted(verdict: verdict) {
                        reviewPromptTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(1500))
                            guard !Task.isCancelled, scenePhase == .active else { return }
                            reviewPromptCoordinator.recordPromptPresented()
                            requestReview()
                        }
                    }
                }

                let duration = measurementStartTime.map { Date().timeIntervalSince($0) } ?? 0.0
                analyticsTracker.track(.lagcheckCompleted(
                    gameID: activeContext.context.gameID,
                    platform: activeContext.context.platform.rawValue,
                    networkType: activeContext.observedPhoneNetwork?.rawValue ?? "unknown",
                    regionID: activeContext.regionID,
                    resultClass: result.restResult.resultClass.rawValue,
                    durationSeconds: duration
                ))
            }

        case .completed:
            presentation = .inconclusive
            if !hasTrackedTerminalEvent {
                hasTrackedTerminalEvent = true
                analyticsTracker.track(.lagcheckInconclusive(
                    gameID: activeContext.context.gameID,
                    platform: activeContext.context.platform.rawValue,
                    networkType: activeContext.observedPhoneNetwork?.rawValue ?? "unknown",
                    regionID: activeContext.regionID,
                    reason: "insufficient_samples"
                ))
            }
        case .cancelled:
            presentation = .cancelled
            if !hasTrackedTerminalEvent {
                hasTrackedTerminalEvent = true
                analyticsTracker.track(.lagcheckCancelled(
                    gameID: activeContext.context.gameID,
                    platform: activeContext.context.platform.rawValue,
                    networkType: activeContext.observedPhoneNetwork?.rawValue ?? "unknown",
                    regionID: activeContext.regionID,
                    reason: "cancelled"
                ))
            }
        }
    }

    private func restart() {
        analyticsTracker.track(.retestStarted(
            gameID: activeContext.context.gameID,
            platform: activeContext.context.platform.rawValue
        ))
        samples = []
        restSamples = []
        hasTrackedTerminalEvent = false
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
