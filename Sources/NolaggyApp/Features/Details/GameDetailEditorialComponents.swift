import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Linha horizontal com as avaliações oficiais auditadas (Decisão 31).
struct GameDetailRatingsRow: View {
    let editorial: RemoteCatalogGameEditorial

    var body: some View {
        HStack(spacing: NLSpacing.sm) {
            // Classificação indicativa oficial
            HStack(spacing: 4) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 11, weight: .semibold))
                Text(editorial.ageRating)
                    .font(NLTypography.captionStrong)
            }
            .foregroundStyle(NLColor.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(NLColor.backgroundRaised, in: Capsule())

            // Ano de lançamento
            Text(String(editorial.releaseYear))
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(NLColor.backgroundRaised, in: Capsule())

            Spacer()

            // Badges de Notas Oficiais Auditadas
            ForEach(editorial.ratings, id: \.source) { rating in
                HStack(spacing: 4) {
                    Text(rating.source.displayName)
                        .font(NLTypography.caption)
                        .foregroundStyle(NLColor.textTertiary)
                    Text(rating.formattedScore)
                        .font(NLTypography.captionStrong)
                        .foregroundStyle(NLColor.textPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(NLColor.backgroundRaised, in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Cartão de Requisitos de Sistema e Ficha Técnica da Plataforma Selecionada.
struct GameDetailRequirementsCard: View {
    let requirement: PlatformRequirement
    let platform: Platform

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Label("Requisitos da Plataforma", systemImage: "cpu")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                Spacer()
                Text(platformName)
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.accentPrimary)
            }

            Divider().overlay(NLColor.borderSubtle)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NLSpacing.sm) {
                specItem(label: "Sistema Mínimo", value: requirement.minimumOS, icon: "gearshape")
                specItem(label: "Armazenamento", value: requirement.formattedStorage, icon: "internaldrive")
                specItem(label: "Memória RAM", value: requirement.formattedRAM, icon: "memorychip")
                if let fps = requirement.targetFramerate {
                    specItem(label: "Taxa de Quadros", value: "\(fps) FPS", icon: "speedometer")
                }
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }

    private var platformName: String {
        switch platform {
        case .iphone: return "iPhone"
        case .playstation: return "PlayStation"
        case .xbox: return "Xbox"
        case .pc: return "PC"
        case .nintendo: return "Nintendo Switch"
        }
    }

    private func specItem(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(NLColor.textTertiary)
                Text(label)
                    .font(NLTypography.caption)
                    .foregroundStyle(NLColor.textTertiary)
            }
            Text(value)
                .font(NLTypography.callout)
                .foregroundStyle(NLColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Cartão de Tolerância e Requisitos Recomendados de Rede para o Jogo.
struct GameDetailNetworkDemandsCard: View {
    let demands: GameNetworkDemands
    let observedMetrics: QualityMetrics?

    var body: some View {
        VStack(alignment: .leading, spacing: NLSpacing.sm) {
            HStack {
                Label("Perfil de Rede Recomendado", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                Spacer()
                if let fit = connectionFit {
                    Text(fit.label)
                        .font(NLTypography.captionStrong)
                        .foregroundStyle(fit.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(fit.color.opacity(0.15), in: Capsule())
                }
            }

            Divider().overlay(NLColor.borderSubtle)

            HStack(spacing: NLSpacing.md) {
                demandItem(title: "Ping Ideal", value: "<\(Int(demands.optimalPingMs)) ms")
                demandItem(title: "Ping Máximo", value: "<\(Int(demands.acceptablePingMs)) ms")
                demandItem(title: "Jitter Tolerado", value: "<\(Int(demands.maxJitterMs)) ms")
                demandItem(title: "Perda Máx.", value: demands.packetLossTolerancePct == 0 ? "0%" : "<\(demands.packetLossTolerancePct)%")
            }

            if let message = fitDescription {
                Text(message)
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textSecondary)
                    .padding(.top, 2)
            }
        }
        .padding(NLSpacing.cardPadding)
        .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
    }

    private func demandItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(NLTypography.caption)
                .foregroundStyle(NLColor.textTertiary)
            Text(value)
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var connectionFit: (label: String, color: Color)? {
        guard let metrics = observedMetrics, let p50 = metrics.p50Milliseconds else { return nil }
        let jitter = metrics.jitterMilliseconds ?? 0
        if p50 <= demands.optimalPingMs && jitter <= demands.maxJitterMs {
            return ("Excelente Fit", NLColor.scoreExcellent)
        } else if p50 <= demands.acceptablePingMs {
            return ("Adequado", NLColor.scoreUnstable)
        } else {
            return ("Abaixo do Ideal", NLColor.scoreLagRisk)
        }
    }

    private var fitDescription: String? {
        guard let metrics = observedMetrics, let p50 = metrics.p50Milliseconds else { return nil }
        if p50 <= demands.optimalPingMs {
            return "Sua latência medida de \(Int(p50)) ms atende com folga ao requisito ideal deste jogo para gameplay responsivo."
        } else if p50 <= demands.acceptablePingMs {
            return "Sua latência de \(Int(p50)) ms está na faixa aceitável, mas pode apresentar pequenas desvantagens em partidas competitivas intensas."
        } else {
            return "Sua latência de \(Int(p50)) ms está acima da recomendada para este jogo, com risco perceptível de atraso em ações."
        }
    }
}

/// Banner contextual de diagnóstico de NAT e topologia de rede (Decisão 32).
struct GameDetailNATBanner: View {
    let snapshot: NATTopologySnapshot

    var body: some View {
        if snapshot.hasAnyMultiplayerIssue {
            HStack(alignment: .top, spacing: NLSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(NLColor.scoreUnstable)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(titleText)
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                    Text(messageText)
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textSecondary)
                }
            }
            .padding(NLSpacing.cardPadding)
            .background(NLColor.scoreUnstableSubtle, in: RoundedRectangle(cornerRadius: NLRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: NLRadius.card)
                    .stroke(NLColor.scoreUnstable.opacity(0.3), lineWidth: NLStroke.hairline)
            }
        }
    }

    private var titleText: String {
        if snapshot.cgnatStatus.isImpacted {
            return "Operadora com CGNAT Detectado"
        } else if snapshot.doubleNATStatus.isImpacted {
            return "Duplo Roteador Detectado (NAT Duplo)"
        } else if snapshot.natType.isMultiplayerRestricted {
            return "NAT Estrito (Tipo 3) Detectado"
        }
        return "Topologia de Rede"
    }

    private var messageText: String {
        if snapshot.cgnatStatus.isImpacted {
            return "Seu provedor utiliza CGNAT, o que pode bloquear conexões diretas em salas multijogador e chats de voz de consoles."
        } else if snapshot.doubleNATStatus.isImpacted {
            return "Dois roteadores estão ativos na sua casa ao mesmo tempo, causando conflito de portas. Recomendamos colocar um deles em modo Bridge."
        } else {
            return "Seu tipo de NAT é Estrito. Isso pode dificultar encontrar partidas no multiplayer e conectar com amigos em grupos de voz."
        }
    }
}
