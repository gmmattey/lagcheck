import SwiftUI
import StoreKit
import NolaggyDomain
import NolaggyDesign
import NolaggyApplication
import NolaggyInfrastructure

/// Ponto de entrada do App Clip instantâneo do LagCheck (Decisão 76).
/// Abre em menos de 2s a partir de links no Discord/Safari para medição direta de rota real.
@main
struct LagCheckClipApp: App {
    @State private var targetGameID: String? = nil
    
    var body: some Scene {
        WindowGroup {
            LagCheckClipView(targetGameID: targetGameID)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let webpageURL = activity.webpageURL else { return }
                    if let deepLink = DeepLinkParser.parse(url: webpageURL),
                       case let .quickCheck(gameID, _, _) = deepLink {
                        targetGameID = gameID
                    }
                }
                .onOpenURL { url in
                    if let deepLink = DeepLinkParser.parse(url: url),
                       case let .quickCheck(gameID, _, _) = deepLink {
                        targetGameID = gameID
                    }
                }
        }
    }
}

/// Interface esportiva Dark Competitive UI para a tela única do App Clip.
struct LagCheckClipView: View {
    let targetGameID: String?
    
    @State private var isMeasuring = false
    @State private var verdict: GameReadinessVerdict? = nil
    @State private var rttMedian: Double? = nil
    @State private var jitter: Double? = nil
    @State private var loss: Double = 0.0
    @State private var showAppStoreOverlay = false
    @State private var currentMeasurementTask: Task<Void, Never>? = nil
    @State private var activeSessionToken: UUID = UUID()
    
    var body: some View {
        ZStack {
            NLColor.deep.ignoresSafeArea()
            
            VStack(spacing: NLSpacing.lg) {
                // Topo da marca
                HStack {
                    Text("lagcheck")
                        .font(NLTypography.screenTitle)
                        .foregroundStyle(NLColor.textPrimary)
                    
                    Spacer()
                    
                    Text("APP CLIP")
                        .font(NLTypography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(NLColor.accentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(NLColor.accentPrimary.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, NLSpacing.md)
                .padding(.top, NLSpacing.md)
                
                Spacer()
                
                // Card de Telemetria e Veredito
                VStack(spacing: NLSpacing.md) {
                    Text(gameDisplayName.uppercased())
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                        .tracking(1.5)
                    
                    if let verdict = verdict {
                        VerdictIndicatorBadge(verdict: verdict, size: 28)
                        
                        Text(verdictHeadline(for: verdict))
                            .font(NLTypography.headline)
                            .foregroundStyle(colorForVerdict(verdict))
                            .multilineTextAlignment(.center)
                        
                        // Métricas do teste
                        HStack(spacing: NLSpacing.lg) {
                            metricColumn(label: "PING", value: String(format: "%.0f ms", rttMedian ?? 0))
                            metricColumn(label: "JITTER", value: String(format: "%.1f ms", jitter ?? 0))
                            metricColumn(label: "PERDA", value: String(format: "%.0f%%", loss))
                        }
                        .padding(.top, NLSpacing.sm)
                    } else if isMeasuring {
                        VStack(spacing: NLSpacing.sm) {
                            ProgressView()
                                .tint(NLColor.accentPrimary)
                                .scaleEffect(1.2)
                            
                            Text("MEDINDO ROTA REAL...")
                                .font(NLTypography.bodyEmphasis)
                                .foregroundStyle(NLColor.textSecondary)
                        }
                    } else {
                        VStack(spacing: NLSpacing.sm) {
                            Image(systemName: "bolt.horizontal.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(NLColor.accentPrimary)
                            
                            Text("PRONTO PRA RANKED?")
                                .font(NLTypography.headline)
                                .foregroundStyle(NLColor.textPrimary)
                            
                            Text("Cheque sua rota antes da partida em 1 toque.")
                                .font(NLTypography.caption)
                                .foregroundStyle(NLColor.textSecondary)
                        }
                    }
                }
                .padding(NLSpacing.lg)
                .frame(maxWidth: .infinity)
                .background(NLColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: NLRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: NLRadius.lg, style: .continuous)
                        .stroke(NLColor.borderSubtle, lineWidth: 1)
                )
                .padding(.horizontal, NLSpacing.md)
                
                Spacer()
                
                // Ação Primária ou Banner de Conversão
                VStack(spacing: NLSpacing.sm) {
                    if verdict != nil {
                        Button(action: {
                            triggerMeasurement()
                        }) {
                            Text("TESTAR NOVAMENTE")
                                .font(NLTypography.bodyEmphasis)
                                .foregroundStyle(NLColor.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(NLColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous)
                                        .stroke(NLColor.borderStrong, lineWidth: 1)
                                )
                        }
                        
                        // Botão nativo acionando o App Clip Overlay oficial da Apple
                        Button(action: {
                            showAppStoreOverlay = true
                        }) {
                            HStack(spacing: NLSpacing.xs) {
                                Image(systemName: "arrow.down.app.fill")
                                Text("BAIXAR APP COMPLETO")
                            }
                            .font(NLTypography.ctaButton)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(NLColor.gamerPurple)
                            .clipShape(RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous))
                        }
                        
                        Text("Histórico de partidas, teste de bufferbloat e widgets na tela de bloqueio.")
                            .font(NLTypography.technicalEvidence)
                            .foregroundStyle(NLColor.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, NLSpacing.xxs)
                    } else {
                        Button(action: {
                            triggerMeasurement()
                        }) {
                            Text("INICIAR CHECK")
                                .font(NLTypography.ctaButton)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(NLColor.gamerPurple)
                                .clipShape(RoundedRectangle(cornerRadius: NLRadius.md, style: .continuous))
                        }
                        .disabled(isMeasuring)
                    }
                }
                .padding(.horizontal, NLSpacing.md)
                .padding(.bottom, NLSpacing.lg)
            }
        }
        .preferredColorScheme(.dark)
        .appStoreOverlay(isPresented: $showAppStoreOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
        .task(id: targetGameID) {
            triggerMeasurement()
        }
    }
    
    private func triggerMeasurement() {
        currentMeasurementTask?.cancel()
        let newSessionToken = UUID()
        activeSessionToken = newSessionToken
        
        currentMeasurementTask = Task { @MainActor in
            await runClipCheck(sessionToken: newSessionToken)
        }
    }
    
    private var gameDisplayName: String {
        guard let id = targetGameID else { return "Rota Regional de Referência" }
        if let basePayload = bundledCatalog,
           let game = basePayload.games.first(where: { $0.id == id }) {
            return game.name
        }
        return id.replacingOccurrences(of: "-", with: " ").capitalized
    }
    
    private var bundledCatalog: RemoteCatalogPayload? {
        guard let data = DebugCatalogBase.envelopeData() else { return nil }
        return try? RemoteCatalogVerifier.verifyAndDecode(envelopeData: data)
    }
    
    private func metricColumn(label: String, value: String) -> some View {
        VStack(spacing: NLSpacing.xxs) {
            Text(label)
                .font(NLTypography.metricsLabel)
                .tracking(NLTypography.metricsLabelTracking)
                .foregroundStyle(NLColor.textTertiary)
            Text(value)
                .font(NLTypography.monospaceMetrics)
                .foregroundStyle(NLColor.textPrimary)
        }
    }
    
    private func verdictHeadline(for verdict: GameReadinessVerdict) -> String {
        verdict.defaultHeadline
    }
    
    private func colorForVerdict(_ verdict: GameReadinessVerdict) -> Color {
        switch verdict {
        case .ready: return NLColor.semanticReady
        case .caution: return NLColor.semanticCaution
        case .notReady: return NLColor.semanticNotReady
        case .inconclusive: return NLColor.semanticNeutral
        }
    }
    
    private func runClipCheck(sessionToken: UUID) async {
        guard !Task.isCancelled, activeSessionToken == sessionToken else { return }
        
        // Reset do veredito e métricas anteriores para refletir a nova medição
        withAnimation {
            self.verdict = nil
            self.rttMedian = nil
            self.jitter = nil
            self.loss = 0.0
        }
        isMeasuring = true
        
        let catalog = bundledCatalog
        var destination: ProbeDestination? = nil
        var profile: QualityProfileID = .battleRoyaleCompetitive
        let sessionContext: GameContext
        
        if let gameID = targetGameID {
            // 1. O link especificou um jogo: resolve estritamente a rota desse jogo
            let rawContext = GameContext(gameID: gameID, market: "BR", platform: .iphone)
            sessionContext = rawContext
            
            if let catalog = catalog {
                let resolution = try? RemoteCatalogVerifier.resolve(rawContext, in: catalog)
                if case let .available(resolved) = resolution {
                    destination = resolved.destination
                    profile = resolved.profileID
                } else if let catalogGame = catalog.games.first(where: { $0.id == gameID }),
                          let firstContext = catalogGame.contexts.first(where: { $0.availability == .available }),
                          let fallbackPlatform = firstContext.platforms.first {
                    // Resolução de plataforma suportada pelo catálogo para o jogo pedido (ex: Valorant no PC)
                    let platformContext = GameContext(gameID: gameID, market: firstContext.market, platform: fallbackPlatform)
                    if case let .available(resolved) = try? RemoteCatalogVerifier.resolve(platformContext, in: catalog) {
                        destination = resolved.destination
                        profile = resolved.profileID
                    }
                }
            }
            
            // Integridade Diagnóstica (Decisão 50/76): Se o jogo pedido não existe no catálogo,
            // NUNCA meça Fortnite em silêncio. Emita .inconclusive honestamente.
            if destination == nil {
                guard !Task.isCancelled, activeSessionToken == sessionToken else { return }
                withAnimation {
                    self.verdict = .inconclusive
                    self.isMeasuring = false
                }
                return
            }
        } else {
            // 2. Sem jogo especificado na URL: mede a Rota Regional de Referência neutra oficial
            let genericContext = GameContext.genericGaming(market: "BR", platform: .iphone)
            sessionContext = genericContext
            if let catalog = catalog,
               case let .available(resolved) = try? RemoteCatalogVerifier.resolve(genericContext, in: catalog) {
                destination = resolved.destination
                profile = resolved.profileID
            }
        }
        
        guard let validDestination = destination else {
            guard !Task.isCancelled, activeSessionToken == sessionToken else { return }
            withAnimation {
                self.verdict = .inconclusive
                self.isMeasuring = false
            }
            return
        }
        
        let endpoint = MeasurementEndpoint(
            host: validDestination.host,
            port: validDestination.port,
            protocolKind: validDestination.protocolKind
        )
        let plan = QuickCheckPlan(endpoint: endpoint)
        let session = MeasurementSession(
            id: UUID(),
            context: sessionContext
        )
        
        #if !targetEnvironment(simulator)
        let transport = NWConnectionMeasurementTransport()
        let samples = await transport.collect(session: session, plan: plan) { _ in }
        #else
        // Em simulador sem hardware físico de rede, nunca gera dados inventados (Decisão 64 / AGENTS.md).
        // Emite amostras vazias/inconclusivas de transporte de forma honesta.
        let samples: [ProbeSample] = (0..<ProbeAcceptancePolicy.plannedProbeCount).map {
            ProbeSample(sequence: $0, outcome: .transportError)
        }
        #endif
        
        guard !Task.isCancelled, activeSessionToken == sessionToken else { return }
        
        let evaluationResult = DeepCheckEvaluator.evaluate(
            restSamples: samples,
            loadSamples: nil,
            profile: profile
        )
        
        guard !Task.isCancelled, activeSessionToken == sessionToken else { return }
        
        switch evaluationResult {
        case let .completed(deepCheckResult):
            let evaluation = GameReadinessEvaluator.evaluate(
                deepCheckResult: deepCheckResult,
                profile: profile
            )
            guard !Task.isCancelled, activeSessionToken == sessionToken else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.rttMedian = deepCheckResult.restResult.metrics.p50Milliseconds
                self.jitter = deepCheckResult.restResult.metrics.jitterMilliseconds
                self.loss = deepCheckResult.restResult.metrics.packetLossPercentage
                self.verdict = evaluation.verdict
                self.isMeasuring = false
            }
        case .inconclusive:
            guard !Task.isCancelled, activeSessionToken == sessionToken else { return }
            withAnimation {
                self.verdict = .inconclusive
                self.isMeasuring = false
            }
        }
    }
}
