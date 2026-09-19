import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Banner de alerta sobre a disponibilidade operacional dos serviços da plataforma de console (PSN, Xbox Live).
/// Conforme Decisão 30, o banner é contextual, não-bloqueante e segue o padrão editorial Apple Games.
struct PlatformHealthBannerView: View {
    let health: PlatformHealth

    var body: some View {
        if health.isIssueReported {
            HStack(alignment: .top, spacing: NLSpacing.sm) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                    .background(accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: NLRadius.controlSmall))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: NLSpacing.xxs) {
                    HStack(alignment: .center) {
                        Text(bannerTitle)
                            .font(NLTypography.bodyEmphasis)
                            .foregroundStyle(NLColor.textPrimary)
                        Spacer()
                        if let badgeText {
                            Text(badgeText)
                                .font(NLTypography.captionStrong)
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(accentColor.opacity(0.18), in: Capsule())
                        }
                    }

                    Text(bannerMessage)
                        .font(NLTypography.footnote)
                        .foregroundStyle(NLColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)

                    if !health.affectedServices.isEmpty {
                        Text(String(format: AppLocalization.string("platform_health.affected_services %@", comment: ""), health.affectedServices.joined(separator: ", ")))
                            .font(NLTypography.caption)
                            .foregroundStyle(NLColor.textTertiary)
                            .padding(.top, NLSpacing.xxs)
                    }
                }
            }
            .padding(NLSpacing.cardPadding)
            .background(NLColor.backgroundRaised, in: RoundedRectangle(cornerRadius: NLRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: NLRadius.card)
                    .stroke(accentColor.opacity(0.3), lineWidth: NLStroke.hairline)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(bannerTitle). \(bannerMessage)")
        }
    }

    private var isMajorOutage: Bool {
        if case .majorOutage = health.status { return true }
        return false
    }

    private var accentColor: Color {
        isMajorOutage ? NLColor.coralSolar : NLColor.scoreUnstable
    }

    private var iconName: String {
        isMajorOutage ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill"
    }

    private var bannerTitle: String {
        let key = isMajorOutage ? "platform_health.outage.title %@" : "platform_health.degraded.title %@"
        return String(format: AppLocalization.string(key, comment: ""), health.serviceName)
    }

    private var bannerMessage: String {
        if let details = health.details, !details.isEmpty {
            return details
        }
        let key = isMajorOutage ? "platform_health.outage.message" : "platform_health.degraded.message"
        return AppLocalization.string(key, comment: "")
    }

    private var badgeText: String? {
        AppLocalization.string(isMajorOutage ? "platform_health.status.outage" : "platform_health.status.degraded")
    }
}
