import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

/// O detalhe começa pela decisão que muda o significado da medição: onde a
/// pessoa joga e, para equipamento externo, como ele se conecta à rede.
struct GameDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let game: CatalogMeasurementJourney.Game
    let scoreState: GameRowView.ScoreState
    let evaluation: MeasurementEvaluation?
    let resolvedContext: ResolvedMeasurementContext?
    let supportedPlatforms: [Platform]
    var gameHistory: [MeasurementHistoryEntry] = []
    var analyticsTracker: any AnalyticsTracker = NoopAnalyticsTracker()
    let onStartDeepCheck: (Platform, ExternalEquipmentLink?) -> Void
    let onOpenHistory: () -> Void

    @State private var selectedPlatform: Platform = .iphone
    @State private var selectedExternalLink: ExternalEquipmentLink? = nil
    @State private var platformHealth: PlatformHealth? = nil
    private let healthClient = DirectPlatformHealthClient()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // A arte contextualiza o título sem disputar atenção com a decisão.
                GameDetailCinemaHeroBanner(game: game)

                VStack(alignment: .leading, spacing: NLSpacing.lg) {
                    GameDetailMeasurementContextCard(
                        supportedPlatforms: supportedPlatforms,
                        selectedPlatform: $selectedPlatform,
                        selectedExternalLink: $selectedExternalLink
                    )

                    GameDetailMeasurementScope(
                        platform: selectedPlatform,
                        externalLink: selectedExternalLink
                    )

                    PrimaryButton(
                        title: "home.cta.start_lagcheck",
                        icon: Image(systemName: "play.fill"),
                        isEnabled: !requiresEquipmentConnection,
                        accessibilityIdentifier: "start-game-deep-check",
                        action: startDeepCheck
                    )
                    .opacity(requiresEquipmentConnection ? 0.45 : 1)
                    .accessibilityHint(Text(requiresEquipmentConnection ? "game_detail.context.connection_required" : "game_detail.context.start_hint"))

                    supplementaryInformation
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                .padding(.top, NLSpacing.sm)
                .padding(.bottom, NLSpacing.xxl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(NLColor.deep.ignoresSafeArea())
        .tint(.white)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .onAppear {
            guard !supportedPlatforms.contains(selectedPlatform) else { return }
            selectedPlatform = supportedPlatforms.first ?? .iphone
        }
        .onChange(of: selectedPlatform, initial: false) { _, platform in
            analyticsTracker.track(.platformSelected(platform: platform.rawValue))
            if platform == .iphone {
                selectedExternalLink = nil
            }
        }
        .task(id: selectedPlatform) {
            if selectedPlatform == .playstation || selectedPlatform == .xbox || selectedPlatform == .nintendo {
                let health = await healthClient.checkHealth(for: selectedPlatform, market: game.context.market)
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.platformHealth = health
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.platformHealth = nil
                }
            }
        }
    }

    private var observedMetrics: QualityMetrics? {
        guard let evaluation else { return nil }
        switch evaluation {
        case let .completed(result):
            return result.metrics
        case let .inconclusive(_, diagnostics):
            return diagnostics
        }
    }

    private var wifiBandDiagnostic: WiFiBandDiagnosticResult? {
        guard resolvedContext?.observedPhoneNetwork == .wifi, let metrics = observedMetrics else { return nil }
        let telemetry = WiFiLocalTelemetry(
            gatewayRTTMedianMs: metrics.p50Milliseconds,
            gatewayJitterMs: metrics.jitterMilliseconds,
            tailRatioP95P50: metrics.p95ToP50Ratio,
            validSampleCount: metrics.validResponseCount,
            plannedSampleCount: metrics.validResponseCount,
            isWiFi: true
        )
        let result = WiFiBandEvaluator.evaluate(telemetry: telemetry)
        return result.diagnostic.isSuspectOrConfirmed24GHz ? result : nil
    }

    private var requiresEquipmentConnection: Bool {
        selectedPlatform != .iphone && selectedExternalLink == nil
    }

    /// Histórico e observações verificáveis não disputam a decisão de medir.
    /// Dados editoriais de terceiros ficam fora desta versão até serem auditados.
    @ViewBuilder
    private var supplementaryInformation: some View {
        if !gameHistory.isEmpty || wifiBandDiagnostic != nil || platformHealth?.isIssueReported == true {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: NLSpacing.lg) {
                    if !gameHistory.isEmpty {
                        GameDetailExclusiveHistoryCard(
                            entries: gameHistory,
                            selectedPlatform: selectedPlatform,
                            selectedExternalLink: selectedExternalLink,
                            onOpenHistory: onOpenHistory
                        )
                    }

                    if wifiBandDiagnostic != nil || platformHealth?.isIssueReported == true {
                        GameDetailNetworkInformationAccordion(
                            platformHealth: platformHealth,
                            wifiBandDiagnostic: wifiBandDiagnostic,
                            onStartDeepCheck: { startDeepCheck() }
                        )
                    }
                }
                .padding(.top, NLSpacing.sm)
            } label: {
                Label("game_detail.more_information", systemImage: "info.circle")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
            }
            .tint(NLColor.textSecondary)
            .accessibilityIdentifier("game-detail-more-information")
        }
    }

    private func startDeepCheck() {
        guard !requiresEquipmentConnection else { return }
        analyticsTracker.track(.platformSelected(platform: selectedPlatform.rawValue))
        onStartDeepCheck(selectedPlatform, selectedExternalLink)
    }
}
