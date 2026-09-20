import SwiftUI
import NolaggyDesign

/// Sheet canônica de consentimento de franquia de dados móveis (Decisão 36).
/// Exibida antes do início do Check Completo em conexões de rede móvel (celular).
struct CellularDataConsentSheet: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: NLSpacing.xl) {
            Spacer()

            VStack(spacing: NLSpacing.md) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(NLColor.accentPrimary)
                    .frame(width: 80, height: 80)
                    .background(NLColor.accentPrimarySubtle, in: Circle())
                    .accessibilityHidden(true)

                Text("deep_check.cellular_consent.title")
                    .font(NLTypography.headline)
                    .foregroundStyle(NLColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("deep_check.cellular_consent.message")
                    .font(NLTypography.body)
                    .foregroundStyle(NLColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("deep_check.cellular_consent.limit")
                    .font(NLTypography.footnote)
                    .foregroundStyle(NLColor.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, NLSpacing.lg)

            Spacer()

            VStack(spacing: NLSpacing.sm) {
                PrimaryButton(
                    title: "deep_check.cellular_consent.confirm",
                    action: onConfirm
                )
                .accessibilityIdentifier("cellular-consent-confirm")

                Button(action: onCancel) {
                    Text("deep_check.cellular_consent.cancel")
                        .font(NLTypography.callout)
                        .foregroundStyle(NLColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: NLSizing.touchTarget)
                }
                .accessibilityIdentifier("cellular-consent-cancel")
            }
        }
        .padding(.horizontal, NLSpacing.screenMarginHorizontal)
        .padding(.vertical, NLSpacing.lg)
        .background(NolaggyScreenBackground())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
