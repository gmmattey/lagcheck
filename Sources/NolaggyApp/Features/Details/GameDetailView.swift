import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain
import NolaggyInfrastructure

/// Tela de Detalhes do Jogo - Proposta Cinema Hero (Estilo Netflix).
/// Apresenta arte cinematográfica full-bleed, metadados Netflix, botão Iniciar LagCheck,
/// sinopse oficial, notas auditadas, plataformas suportadas, histórico exclusivo do jogo
/// e especificações técnicas sob demanda (acordeão expansível).
struct GameDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let game: CatalogMeasurementJourney.Game
    let scoreState: GameRowView.ScoreState
    let evaluation: MeasurementEvaluation?
    let resolvedContext: ResolvedMeasurementContext?
    let supportedPlatforms: [Platform]
    var gameHistory: [MeasurementHistoryEntry] = []
    let onStartDeepCheck: (Platform) -> Void

    @State private var selectedPlatform: Platform = .iphone
    @State private var platformHealth: PlatformHealth? = nil
    @State private var natSnapshot: NATTopologySnapshot? = nil
    @State private var showingPlatformSelection = false
    private let healthClient = DirectPlatformHealthClient()
    private let stunClient = StunProbeClient()

    private var editorial: RemoteCatalogGameEditorial? {
        GameEditorialRegistry.editorial(for: game.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Cinema Hero Banner (Arte Full-bleed + Gradiente + Metadados Netflix)
                GameDetailCinemaHeroBanner(gameName: game.name, editorial: editorial)

                // 2. Conteúdo Principal
                VStack(alignment: .leading, spacing: NLSpacing.md) {
                    // Botão de Ação Primária: Iniciar LagCheck (Pergunta a plataforma)
                    Button(action: { showingPlatformSelection = true }) {
                        HStack(spacing: NLSpacing.xs) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text(LocalizedStringKey("home.cta.start_lagcheck"))
                                .font(NLTypography.bodyEmphasis)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(NLColor.accentPrimary, in: RoundedRectangle(cornerRadius: NLRadius.controlMedium))
                    }
                    .accessibilityIdentifier("start-game-deep-check")

                    // Sinopse Oficial Localizada
                    if let synopsis = editorial?.localizedSummary(localeIdentifier: Locale.current.identifier), !synopsis.isEmpty {
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

                    // Plataformas Suportadas (Interativas com seleção)
                    if !supportedPlatforms.isEmpty {
                        GameDetailPlatformsRow(supportedPlatforms: supportedPlatforms, selectedPlatform: $selectedPlatform)
                    }

                    // Histórico Exclusivo deste Jogo
                    GameDetailExclusiveHistoryCard(entries: gameHistory, gameName: game.name)

                    // Especificações Técnicas e Rede (Acordeão / Oculto por padrão)
                    GameDetailTechnicalSpecsAccordion(
                        editorial: editorial,
                        selectedPlatform: selectedPlatform,
                        observedMetrics: observedMetrics,
                        natSnapshot: natSnapshot,
                        platformHealth: platformHealth,
                        wifiBandDiagnostic: wifiBandDiagnostic,
                        onStartDeepCheck: { showingPlatformSelection = true }
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
        .sheet(isPresented: $showingPlatformSelection) {
            PlatformSelectionSheet(
                gameName: game.name,
                supportedPlatforms: supportedPlatforms,
                initialPlatform: selectedPlatform,
                onSelectPlatform: { platform in
                    selectedPlatform = platform
                    onStartDeepCheck(platform)
                }
            )
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
        guard let metrics = observedMetrics else { return nil }
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
}
