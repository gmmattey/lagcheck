import SwiftUI
import UIKit
import OSLog
@preconcurrency import GoogleMobileAds
@preconcurrency import UserMessagingPlatform
import NolaggyDesign

private enum IOSAdPlacement {
    case home, history, games, result

    var unitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/3986624511"
        #else
        switch self {
        case .home: "ca-app-pub-5542349230926522/4055030074"
        case .history: "ca-app-pub-5542349230926522/4883886853"
        case .games: "ca-app-pub-5542349230926522/2936380361"
        case .result: "ca-app-pub-5542349230926522/7813302529"
        }
        #endif
    }
}

/// Registro local e sem dado pessoal do motivo de um anúncio não aparecer. Só é exibido em builds de TestFlight
/// (Ajustes); fora disso fica silencioso. Não altera medição, consentimento nem o layout dos anúncios.
@MainActor
final class IOSAdDiagnostics: ObservableObject {
    static let shared = IOSAdDiagnostics()
    private let logger = Logger(subsystem: "com.lagcheck.app", category: "ads")

    /// TestFlight e builds de teste usam `sandboxReceipt`; a App Store usa `receipt`.
    static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    @Published private(set) var entries: [String: String] = [:]

    var report: String {
        entries.keys.sorted().map { "\($0): \(entries[$0] ?? "-")" }.joined(separator: "\n")
    }

    func record(_ key: String, _ value: String) {
        entries[key] = value
        logger.notice("\(key, privacy: .public): \(value, privacy: .public)")
    }
}

@MainActor
final class IOSAdConsent: ObservableObject {
    static let shared = IOSAdConsent()

    @Published private(set) var canRequestAds = false
    @Published private(set) var privacyOptionsRequired = false

    private(set) var isEnabled: Bool
    private enum ConsentFlow: Equatable { case idle, updating, privacyOptions }
    private var flow: ConsentFlow = .idle
    private var pendingRefresh = false
    private var pendingPrivacyOptions = false
    private var startedMobileAds = false

    private init() {
        isEnabled = Bundle.main.object(forInfoDictionaryKey: "LagCheckAdsEnabled") as? String == "YES"
            && ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1"
            && !ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("-ui-fixture-") })
    }

    func updateForLaunchOrForeground() {
        guard isEnabled else { return }
        guard flow == .idle else {
            pendingRefresh = true
            return
        }
        flow = .updating
        // The previous UMP state is never promoted by our own cache.
        canRequestAds = false
        ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
                do {
                    try await ConsentForm.loadAndPresentIfRequired(from: nil)
                } catch {
                    // UMP may retain a valid prior decision. Its own gate remains authoritative.
                }
                self.finishConsentFlow()
            }
        }
    }

    func showPrivacyOptions() async {
        guard isEnabled, privacyOptionsRequired else { return }
        guard flow == .idle else {
            if flow == .updating { pendingPrivacyOptions = true }
            return
        }
        flow = .privacyOptions
        canRequestAds = false
        await presentPrivacyOptions()
    }

    private func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            // A failed form does not grant consent.
        }
        finishConsentFlow()
    }

    private func finishConsentFlow() {
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        if pendingPrivacyOptions && privacyOptionsRequired {
            pendingPrivacyOptions = false
            flow = .privacyOptions
            canRequestAds = false
            Task { await presentPrivacyOptions() }
            return
        }
        pendingPrivacyOptions = false
        if pendingRefresh {
            pendingRefresh = false
            flow = .idle
            updateForLaunchOrForeground()
            return
        }
        flow = .idle
        let permitted = isEnabled && ConsentInformation.shared.canRequestAds
        IOSAdDiagnostics.shared.record(
            "consent",
            "enabled=\(isEnabled) canRequestAds=\(ConsentInformation.shared.canRequestAds) status=\(ConsentInformation.shared.consentStatus.rawValue) privacyOptions=\(privacyOptionsRequired)"
        )
        if permitted && !startedMobileAds {
            startedMobileAds = true
            MobileAds.shared.start()
        }
        canRequestAds = permitted
    }
}

@MainActor
private final class IOSNativeAdLoader: NSObject, ObservableObject, NativeAdLoaderDelegate {
    @Published private(set) var ad: NativeAd?
    private var loader: AdLoader?

    private var label = ""

    func load(unitID: String, label: String) {
        guard loader == nil, ad == nil else { return }
        self.label = label
        IOSAdDiagnostics.shared.record("ad-\(label)", "pedindo anúncio")
        let next = AdLoader(adUnitID: unitID, rootViewController: nil, adTypes: [.native], options: nil)
        next.delegate = self
        loader = next
        next.load(Request())
    }

    func discard() {
        loader?.delegate = nil
        loader = nil
        ad = nil
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard loader === adLoader else { return }
        ad = nativeAd
        loader = nil
        IOSAdDiagnostics.shared.record("ad-\(label)", "carregado")
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        guard loader === adLoader else { return }
        loader = nil
        ad = nil
        let nsError = error as NSError
        IOSAdDiagnostics.shared.record("ad-\(label)", "erro \(nsError.domain) \(nsError.code): \(nsError.localizedDescription)")
    }
}

/// Only the four authorized screens instantiate this view. A missing ad has no layout.
struct NativeAdSlot: View {
    enum Placement { case home, history, games, result }

    let placement: Placement
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var consent = IOSAdConsent.shared
    @StateObject private var loader = IOSNativeAdLoader()

    private var unitID: String {
        switch placement {
        case .home: IOSAdPlacement.home.unitID
        case .history: IOSAdPlacement.history.unitID
        case .games: IOSAdPlacement.games.unitID
        case .result: IOSAdPlacement.result.unitID
        }
    }

    var body: some View {
        Group {
            if consent.canRequestAds, scenePhase == .active, let ad = loader.ad {
                NativeAdContent(ad: ad)
                    .accessibilityIdentifier("native-ad-\(String(describing: placement))")
                    .padding(.top, placement == .result ? NLSpacing.xl : 0)
                    .padding(.bottom, placement == .home ? NLSpacing.xl : 0)
            }
        }
        .task(id: consent.canRequestAds && scenePhase == .active) {
            guard consent.canRequestAds, scenePhase == .active else {
                loader.discard()
                return
            }
            loader.load(unitID: unitID, label: String(describing: placement))
        }
        .onDisappear { loader.discard() }
    }
}

private struct NativeAdContent: UIViewRepresentable {
    let ad: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let view = NativeAdView()
        view.backgroundColor = UIColor(NLColor.surface)
        view.layer.cornerRadius = 14
        view.layer.borderColor = UIColor(NLColor.borderStrong).cgColor
        view.layer.borderWidth = 1
        view.clipsToBounds = true

        let badge = UILabel()
        badge.text = AppLocalization.string("ads.label", comment: "Advertisement attribution")
        badge.textColor = .white
        badge.backgroundColor = UIColor(NLColor.panel)
        badge.layer.borderColor = UIColor(NLColor.borderStrong).cgColor
        badge.layer.borderWidth = 1
        badge.font = .preferredFont(forTextStyle: .caption2)
        badge.adjustsFontForContentSizeCategory = true
        badge.textAlignment = .center
        badge.isAccessibilityElement = true
        badge.accessibilityTraits = .staticText
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
        badge.heightAnchor.constraint(greaterThanOrEqualToConstant: 23).isActive = true

        let headline = UILabel()
        headline.font = .preferredFont(forTextStyle: .headline)
        headline.textColor = UIColor(NLColor.textPrimary)
        headline.numberOfLines = 0
        headline.adjustsFontForContentSizeCategory = true
        view.headlineView = headline

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.layer.cornerRadius = 7
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 40).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 40).isActive = true
        view.iconView = icon

        let body = UILabel()
        body.font = .preferredFont(forTextStyle: .subheadline)
        body.textColor = UIColor(NLColor.textSecondary)
        body.numberOfLines = 0
        body.adjustsFontForContentSizeCategory = true
        view.bodyView = body

        let advertiser = UILabel()
        advertiser.font = .preferredFont(forTextStyle: .caption1)
        advertiser.textColor = UIColor(NLColor.textSecondary)
        advertiser.numberOfLines = 0
        advertiser.adjustsFontForContentSizeCategory = true
        view.advertiserView = advertiser

        let media = MediaView()
        media.contentMode = .scaleAspectFit
        media.translatesAutoresizingMaskIntoConstraints = false
        media.heightAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true
        view.mediaView = media

        let cta = UILabel()
        cta.font = .preferredFont(forTextStyle: .callout)
        cta.adjustsFontForContentSizeCategory = true
        cta.textColor = UIColor(NLColor.textPrimary)
        cta.backgroundColor = UIColor(NLColor.panel)
        cta.layer.borderColor = UIColor(NLColor.borderStrong).cgColor
        cta.layer.borderWidth = 1
        cta.textAlignment = .center
        cta.numberOfLines = 0
        cta.layer.cornerRadius = 8
        cta.clipsToBounds = true
        cta.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        view.callToActionView = cta

        let top = UIStackView(arrangedSubviews: [badge, icon, headline])
        top.axis = .horizontal
        top.alignment = .center
        top.spacing = 8
        // The top trailing corner remains clear for the SDK's AdChoices overlay.
        let stack = UIStackView(arrangedSubviews: [top, advertiser, body, media, cta])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
        return view
    }

    func updateUIView(_ view: NativeAdView, context: Context) {
        (view.headlineView as? UILabel)?.text = ad.headline
        (view.bodyView as? UILabel)?.text = ad.body
        view.bodyView?.isHidden = ad.body == nil
        (view.advertiserView as? UILabel)?.text = ad.advertiser
        view.advertiserView?.isHidden = ad.advertiser == nil
        (view.iconView as? UIImageView)?.image = ad.icon?.image
        view.iconView?.isHidden = ad.icon == nil
        view.mediaView?.mediaContent = ad.mediaContent
        view.mediaView?.isHidden = ad.mediaContent.aspectRatio <= 0
        (view.callToActionView as? UILabel)?.text = ad.callToAction
        view.callToActionView?.isHidden = ad.callToAction == nil
        view.nativeAd = ad
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: NativeAdView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width - 32
        return uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}
