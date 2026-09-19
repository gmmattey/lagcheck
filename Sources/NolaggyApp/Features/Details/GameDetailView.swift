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
    var gameHistory: [MeasurementHistoryEntry] = []
    let onStartDeepCheck: (Platform, ExternalEquipmentLink?) -> Void
    let onOpenHistory: () -> Void

    @State private var selectedPlatform: Platform = .iphone
    @State private var selectedExternalLink: ExternalEquipmentLink? = nil
    @State private var platformHealth: PlatformHealth? = nil
    @State private var natSnapshot: NATTopologySnapshot? = nil
    private let healthClient = DirectPlatformHealthClient()
    private let stunClient = StunProbeClient()

    private var editorial: RemoteCatalogGameEditorial? {
        GameEditorialRegistry.editorial(for: game.id)
    }

    private var supportedPlatforms: [Platform] {
        let allowed = RemoteCatalogVerifier.allowedPlatforms(for: game.id)
        let order: [Platform] = [.iphone, .playstation, .xbox, .nintendo, .pc]
        return order.filter { allowed.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // A arte contextualiza o título sem disputar atenção com a decisão.
                GameDetailCinemaHeroBanner(game: game, editorial: editorial)

                VStack(alignment: .leading, spacing: NLSpacing.md) {
                    GameDetailMeasurementContextCard(
                        supportedPlatforms: supportedPlatforms,
                        selectedPlatform: $selectedPlatform,
                        selectedExternalLink: $selectedExternalLink
                    )

                    GameDetailMeasurementScope(
                        platform: selectedPlatform,
                        externalLink: selectedExternalLink
                    )

                    Button(action: startDeepCheck) {
                        HStack(spacing: NLSpacing.xs) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text(LocalizedStringKey("home.cta.start_lagcheck"))
                                .font(NLTypography.bodyEmphasis)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(NLColor.accentPrimary, in: RoundedRectangle(cornerRadius: NLRadius.controlMedium))
                    }
                    .disabled(requiresEquipmentConnection)
                    .opacity(requiresEquipmentConnection ? 0.45 : 1)
                    .accessibilityIdentifier("start-game-deep-check")
                    .accessibilityHint(Text(requiresEquipmentConnection ? "game_detail.context.connection_required" : "game_detail.context.start_hint"))

                    // Sinopse Oficial Localizada
                    if let synopsis = editorial?.localizedSummary(localeIdentifier: AppLocalization.locale.identifier), !synopsis.isEmpty {
                        Text(synopsis)
                            .font(NLTypography.footnote)
                            .foregroundStyle(NLColor.textSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Grid de Avaliações Oficiais Auditadas (App Store & Metacritic)
                    if let editorial {
                        GameDetailRatingsGrid(editorial: editorial)
                    }

                    GameDetailExclusiveHistoryCard(
                        entries: gameHistory,
                        selectedPlatform: selectedPlatform,
                        selectedExternalLink: selectedExternalLink,
                        onOpenHistory: onOpenHistory
                    )

                    // Especificações Técnicas e Rede (Acordeão / Oculto por padrão)
                    GameDetailTechnicalSpecsAccordion(
                        editorial: editorial,
                        selectedPlatform: selectedPlatform,
                        observedMetrics: observedMetrics,
                        natSnapshot: natSnapshot,
                        platformHealth: platformHealth,
                        wifiBandDiagnostic: wifiBandDiagnostic,
                        onStartDeepCheck: { startDeepCheck() }
                    )
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                .padding(.top, NLSpacing.sm)
                .padding(.bottom, NLSpacing.xxl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.black.ignoresSafeArea())
        .tint(.white)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .onAppear {
            guard !supportedPlatforms.contains(selectedPlatform) else { return }
            selectedPlatform = supportedPlatforms.first ?? .iphone
        }
        .onChange(of: selectedPlatform) { _, platform in
            if platform == .iphone {
                selectedExternalLink = nil
            }
        }
        .task {
            // Sonda topologia de NAT em segundo plano de forma não-bloqueante
            let snapshot = await stunClient.probeTopology()
            withAnimation(.easeInOut(duration: 0.2)) {
                self.natSnapshot = snapshot
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

    private func startDeepCheck() {
        guard !requiresEquipmentConnection else { return }
        onStartDeepCheck(selectedPlatform, selectedExternalLink)
    }
}
