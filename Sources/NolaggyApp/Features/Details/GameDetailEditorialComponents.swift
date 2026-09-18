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
                Label(LocalizedStringKey("game_detail.requirements.platform_title"), systemImage: "cpu")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                Spacer()
                Text(platformName)
                    .font(NLTypography.captionStrong)
                    .foregroundStyle(NLColor.accentPrimary)
            }

            Divider().overlay(NLColor.borderSubtle)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NLSpacing.sm) {
                specItem(label: "game_detail.requirements.minimum_os", value: requirement.minimumOS, icon: "gearshape")
                specItem(label: "game_detail.requirements.storage", value: requirement.formattedStorage, icon: "internaldrive")
                specItem(label: "game_detail.requirements.ram", value: requirement.formattedRAM, icon: "memorychip")
                if let fps = requirement.targetFramerate {
                    specItem(label: "game_detail.requirements.framerate", value: "\(fps) FPS", icon: "speedometer")
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

    private func specItem(label: LocalizedStringKey, value: String, icon: String) -> some View {
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
                Label(LocalizedStringKey("game_detail.network_demands.title"), systemImage: "point.3.connected.trianglepath.dotted")
                    .font(NLTypography.bodyEmphasis)
                    .foregroundStyle(NLColor.textPrimary)
                Spacer()
                if let fit = connectionFit {
                    Text(LocalizedStringKey(fit.labelKey))
                        .font(NLTypography.captionStrong)
                        .foregroundStyle(fit.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(fit.color.opacity(0.15), in: Capsule())
                }
            }

            Divider().overlay(NLColor.borderSubtle)

            HStack(spacing: NLSpacing.md) {
                demandItem(title: "game_detail.network_demands.optimal_ping", value: "<\(Int(demands.optimalPingMs)) ms")
                demandItem(title: "game_detail.network_demands.acceptable_ping", value: "<\(Int(demands.acceptablePingMs)) ms")
                demandItem(title: "game_detail.network_demands.max_jitter", value: "<\(Int(demands.maxJitterMs)) ms")
                demandItem(title: "game_detail.network_demands.packet_loss", value: demands.packetLossTolerancePct == 0 ? "0%" : "<\(demands.packetLossTolerancePct)%")
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

    private func demandItem(title: LocalizedStringKey, value: String) -> some View {
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

    private var connectionFit: (labelKey: String, color: Color)? {
        guard let metrics = observedMetrics, let p50 = metrics.p50Milliseconds else { return nil }
        let jitter = metrics.jitterMilliseconds ?? 0
        if p50 <= demands.optimalPingMs && jitter <= demands.maxJitterMs {
            return ("game_detail.fit.excellent", NLColor.scoreExcellent)
        } else if p50 <= demands.acceptablePingMs {
            return ("game_detail.fit.acceptable", NLColor.scoreUnstable)
        } else {
            return ("game_detail.fit.suboptimal", NLColor.scoreLagRisk)
        }
    }

    private var fitDescription: String? {
        guard let metrics = observedMetrics, let p50 = metrics.p50Milliseconds else { return nil }
        let latencyFormatted = "\(Int(p50)) ms"
        if p50 <= demands.optimalPingMs {
            return String(format: NSLocalizedString("game_detail.fit.excellent_desc %@", comment: ""), latencyFormatted)
        } else if p50 <= demands.acceptablePingMs {
            return String(format: NSLocalizedString("game_detail.fit.acceptable_desc %@", comment: ""), latencyFormatted)
        } else {
            return String(format: NSLocalizedString("game_detail.fit.suboptimal_desc %@", comment: ""), latencyFormatted)
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
                    Text(LocalizedStringKey(titleKey))
                        .font(NLTypography.bodyEmphasis)
                        .foregroundStyle(NLColor.textPrimary)
                    Text(LocalizedStringKey(messageKey))
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

    private var titleKey: String {
        if snapshot.cgnatStatus.isImpacted {
            return "nat_banner.cgnat.title"
        } else if snapshot.doubleNATStatus.isImpacted {
            return "nat_banner.double_nat.title"
        } else if snapshot.natType.isMultiplayerRestricted {
            return "nat_banner.strict.title"
        }
        return "nat_banner.default.title"
    }

    private var messageKey: String {
        if snapshot.cgnatStatus.isImpacted {
            return "nat_banner.cgnat.message"
        } else if snapshot.doubleNATStatus.isImpacted {
            return "nat_banner.double_nat.message"
        } else {
            return "nat_banner.strict.message"
        }
    }
}
