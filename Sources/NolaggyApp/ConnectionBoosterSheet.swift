import SwiftUI
import NolaggyApplication
import NolaggyDesign
import NolaggyDomain

public struct ConnectionBoosterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var coordinator: ConnectionBoosterCoordinator
    private let request: ConnectionBoosterRequest
    
    public init(
        request: ConnectionBoosterRequest,
        coordinator: ConnectionBoosterCoordinator
    ) {
        self.request = request
        self._coordinator = State(initialValue: coordinator)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NLSpacing.lg) {
                    headerView
                    
                    switch coordinator.state {
                    case .idle, .loading:
                        BoosterSkeletonView()
                            .padding(.top, NLSpacing.xs)
                    case let .loaded(advice):
                        contentView(advice)
                    case let .failed(error):
                        errorView(error)
                    }
                }
                .padding(.horizontal, NLSpacing.screenMarginHorizontal)
                .padding(.vertical, NLSpacing.lg)
            }
            .background(NolaggyScreenBackground())
            .navigationTitle(String(localized: "booster.sheet.nav_title", defaultValue: "Como Melhorar"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.close", defaultValue: "Fechar")) {
                        dismiss()
                    }
                    .foregroundStyle(NLColor.textPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await coordinator.loadAdvice(for: request)
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: NLSpacing.xxs) {
            Text(String(format: NSLocalizedString("booster.header.title %@", comment: ""), request.gameName))
                .font(NLTypography.headline)
                .foregroundStyle(NLColor.textPrimary)
            
            Text(String(format: NSLocalizedString("booster.header.subtitle %@ %@", comment: ""), request.platform.rawValue.capitalized, request.networkKind.rawValue.uppercased()))
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textTertiary)
        }
    }
    
    private func contentView(_ advice: ConnectionBoosterAdvice) -> some View {
        VStack(alignment: .leading, spacing: NLSpacing.md) {
            if !advice.summary.isEmpty {
                Text(advice.summary)
                    .font(NLTypography.body)
                    .foregroundStyle(NLColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(spacing: NLSpacing.sm) {
                ForEach(advice.items) { item in
                    BoosterItemRow(
                        iconName: item.category.iconName,
                        title: item.title,
                        detail: item.detail
                    )
                }
            }
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: NLSpacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(NLColor.textSecondary)
                .padding(.top, NLSpacing.xl)
            
            Text("booster.error.title")
                .font(NLTypography.bodyEmphasis)
                .foregroundStyle(NLColor.textPrimary)
            
            Text("booster.error.message")
                .font(NLTypography.footnote)
                .foregroundStyle(NLColor.textSecondary)
                .multilineTextAlignment(.center)
            
            PrimaryButton(title: "common.retry", action: {
                Task {
                    await coordinator.retry(for: request)
                }
            })
            .padding(.top, NLSpacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, NLSpacing.md)
    }
}
