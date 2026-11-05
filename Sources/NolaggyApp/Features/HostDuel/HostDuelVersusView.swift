import SwiftUI
import NolaggyDomain
import NolaggyDesign

/// Tela de Confronto do Duelo de Host (Decisão 112).
/// Design Dark Competitive UI com profundidade tonal de camadas (sem linhas em cards).
public struct HostDuelVersusView: View {
    public let challenger: HostDuelPayload
    public let opponent: HostDuelPayload
    public let gameTitle: String
    public let onDismiss: () -> Void

    @State private var copiedNotice: Bool = false
    @State private var activeShareDestination: ShareDestination? = nil

    private enum ShareDestination: Identifiable {
        case text(String)
        case image(UIImage)
        var id: String {
            switch self {
            case .text: return "text"
            case .image: return "image"
            }
        }
    }

    public init(
        challenger: HostDuelPayload,
        opponent: HostDuelPayload,
        gameTitle: String,
        onDismiss: @escaping () -> Void
    ) {
        self.challenger = challenger
        self.opponent = opponent
        self.gameTitle = gameTitle
        self.onDismiss = onDismiss
    }

    public var body: some View {
        let resolution = HostDuelResolver.resolve(
            challenger: challenger,
            opponent: opponent
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Top Bar
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(NLColor.gamerPurple)
                            .frame(width: 6, height: 6)
                        Text("\(gameTitle.uppercased()) • DUELO DE HOST")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(NLColor.textTertiary)
                            .tracking(0.8)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Text("Fechar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(NLColor.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 12)

                // Veredito Gamer de Batalha
                VStack(alignment: .leading, spacing: 6) {
                    Text("VEREDITO DO LOBBY")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(NLColor.scoreExcellent)
                        .tracking(1.2)

                    Text(resolution.headline)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)

                    Text(resolution.subheadline)
                        .font(NLTypography.callout)
                        .foregroundStyle(NLColor.textSecondary)
                        .padding(.top, 2)
                }
                .padding(.top, 28)

                // Arena Versus (Profundidade e Elevação, Zero Linhas de Bordas)
                VStack(spacing: 12) {
                    if resolution.winner == .opponent {
                        playerFighterCard(payload: opponent, isWinner: true, defaultLabel: "Você")
                        playerFighterCard(payload: challenger, isWinner: false, defaultLabel: "Desafiante")
                    } else {
                        playerFighterCard(payload: challenger, isWinner: resolution.winner == .challenger, defaultLabel: "Desafiante")
                        playerFighterCard(payload: opponent, isWinner: false, defaultLabel: "Você")
                    }
                }
                .padding(.top, 24)

                // Nota de Expiração e Regra
                HStack {
                    let remainingMin = min(challenger.remainingSeconds(), opponent.remainingSeconds()) / 60
                    Text("Expira em \(max(1, remainingMin)) min")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(NLColor.textTertiary)

                    Spacer()

                    Text("Duelo 1v1 • Regra de host v1")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(NLColor.textTertiary)
                }
                .padding(.top, 16)
                .padding(.horizontal, 4)

                if copiedNotice {
                    Text("Veredito copiado para a área de transferência!")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(NLColor.scoreExcellent)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                }

                // Ações
                VStack(spacing: 10) {
                    Button(action: {
                        copyDiscordText(resolution: resolution)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("Copiar Veredito pro Discord")
                                .font(.system(size: 16, weight: .heavy))
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(NLColor.gamerPurple, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: NLColor.gamerPurple.opacity(0.35), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        shareVersusCardImage(resolution: resolution)
                    }) {
                        Text("Compartilhar Imagem do Placar")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(NLColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 28)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 36)
        }
        .background(NLColor.deep.ignoresSafeArea())
        .sheet(item: $activeShareDestination) { dest in
            switch dest {
            case let .text(txt):
                ShareSheet(items: [txt])
            case let .image(img):
                ShareSheet(items: [img])
            }
        }
    }

    // MARK: - Componente de Card com Profundidade
    private func playerFighterCard(payload: HostDuelPayload, isWinner: Bool, defaultLabel: String) -> some View {
        let name = payload.challengerNick.isEmpty ? defaultLabel : payload.challengerNick
        let initial = String(name.prefix(1)).uppercased()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Text(initial)
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                        .frame(width: 28, height: 28)
                        .background(isWinner ? NLColor.gamerPurple : Color.white.opacity(0.1), in: Circle())

                    Text(name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(NLColor.textPrimary)
                }

                Spacer()

                Text(isWinner ? "HOST DA SALA" : verdictSub(payload.verdict))
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(isWinner ? NLColor.scoreExcellent : NLColor.textSecondary)
                    .tracking(0.5)
            }

            HStack(alignment: .lastTextBaseline) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(Int(round(payload.p50Ms)))")
                        .font(.system(size: 38, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                    Text("ms")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NLColor.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(payload.packetLossPercent, specifier: "%.1f")% perda")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(payload.packetLossPercent > 0.5 ? NLColor.cautionYellow : NLColor.textSecondary)
                    Text("\(Int(round(payload.jitterMs))) ms jitter")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(NLColor.textSecondary)
                }
            }
        }
        .padding(18)
        .background(
            isWinner ? NLColor.panel : NLColor.surface,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(
            color: Color.black.opacity(isWinner ? 0.45 : 0.25),
            radius: isWinner ? 16 : 8,
            x: 0,
            y: isWinner ? 8 : 4
        )
        .opacity(isWinner ? 1.0 : 0.85)
    }

    private func verdictSub(_ verdict: GameReadinessVerdict) -> String {
        switch verdict {
        case .ready: return "PRONTO"
        case .caution: return "OSCILANDO"
        case .notReady: return "EVITAR"
        case .inconclusive: return "INCONCLUSIVO"
        }
    }

    private func copyDiscordText(resolution: HostDuelResolution) {
        let cName = challenger.challengerNick.isEmpty ? "Desafiante" : challenger.challengerNick
        let oName = opponent.challengerNick.isEmpty ? "Duo" : opponent.challengerNick
        let cPing = Int(round(challenger.p50Ms))
        let oPing = Int(round(opponent.p50Ms))
        let cLoss = Int(round(challenger.packetLossPercent))
        let oLoss = Int(round(opponent.packetLossPercent))

        let text = """
        ⚔️ [DUELO DE HOST - \(gameTitle.uppercased())]
        👑 \(resolution.headline)
        • \(cName): \(cPing)ms (\(cLoss)% perda)
        • \(oName): \(oPing)ms (\(oLoss)% perda)
        \(resolution.subheadline)
        https://lagcheck.signallq.com/vs
        """

        UIPasteboard.general.string = text
        copiedNotice = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            copiedNotice = false
        }
    }

    @MainActor
    private func shareVersusCardImage(resolution: HostDuelResolution) {
        // Prepara visual de renderização
        let renderView = HostDuelVersusCardSnapshot(
            challenger: challenger,
            opponent: opponent,
            gameTitle: gameTitle,
            resolution: resolution
        )
        .frame(width: 360, height: 420)
        .background(NLColor.deep)

        let renderer = ImageRenderer(content: renderView)
        renderer.scale = UIScreen.main.scale
        if let uiImage = renderer.uiImage {
            activeShareDestination = .image(uiImage)
        }
    }
}

/// Snapshot estático e limpo para gerar imagem do placar
public struct HostDuelVersusCardSnapshot: View {
    public let challenger: HostDuelPayload
    public let opponent: HostDuelPayload
    public let gameTitle: String
    public let resolution: HostDuelResolution

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("LAGCHECK • DUELO DE HOST")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(NLColor.gamerPurple)
                Spacer()
                Text(gameTitle.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(NLColor.textSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(resolution.headline)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                Text(resolution.subheadline)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NLColor.textSecondary)
            }

            HStack(spacing: 12) {
                snapshotPlayer(payload: challenger, defaultName: "Desafiante", isWinner: resolution.winner == .challenger)
                snapshotPlayer(payload: opponent, defaultName: "Duo", isWinner: resolution.winner == .opponent)
            }

            HStack {
                Text("lagcheck.signallq.com")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(NLColor.textTertiary)
                Spacer()
                Text("Medição real sem ping falso")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(NLColor.textTertiary)
            }
        }
        .padding(20)
        .background(NLColor.deep)
    }

    private func snapshotPlayer(payload: HostDuelPayload, defaultName: String, isWinner: Bool) -> some View {
        let name = payload.challengerNick.isEmpty ? defaultName : payload.challengerNick
        return VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isWinner ? NLColor.scoreExcellent : NLColor.textPrimary)

            Text("\(Int(round(payload.p50Ms))) ms")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundStyle(Color.white)

            Text("\(payload.packetLossPercent, specifier: "%.1f")% perda · \(Int(round(payload.jitterMs)))ms")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(NLColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(isWinner ? NLColor.panel : NLColor.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}
