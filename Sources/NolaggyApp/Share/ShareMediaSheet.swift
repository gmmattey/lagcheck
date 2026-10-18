import SwiftUI
import UIKit
import NolaggyDesign
import NolaggyDomain

/// Redes do compartilhamento no resultado. WhatsApp, Telegram, X e Discord recebem o card horizontal (1200×630);
/// TikTok e Instagram recebem o vídeo vertical de 14 s (Decisão 104).
public enum ShareSocialNetwork: String, CaseIterable, Identifiable, Sendable {
    case whatsapp
    case telegram
    case x
    case tiktok
    case instagram
    case discord

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .whatsapp: return "WhatsApp"
        case .telegram: return "Telegram"
        case .x: return "X"
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .discord: return "Discord"
        }
    }

    public var sendsVideo: Bool { self == .tiktok || self == .instagram }

    public var brandColor: Color {
        switch self {
        case .whatsapp: return Color(red: 37 / 255, green: 211 / 255, blue: 102 / 255)
        case .telegram: return Color(red: 38 / 255, green: 165 / 255, blue: 228 / 255)
        case .x, .tiktok: return Color.black
        case .instagram: return Color(red: 228 / 255, green: 64 / 255, blue: 95 / 255)
        case .discord: return Color(red: 88 / 255, green: 101 / 255, blue: 242 / 255)
        }
    }
}

/// Legendas de divulgação. O card leva só o texto; o vídeo leva também as hashtags (copiadas para a área de transferência,
/// porque Instagram e TikTok ignoram o texto enviado junto com o arquivo).
public enum ShareCaption {
    public static func card(gameName: String) -> String {
        AppLocalization.format("share.caption.card %@", gameName)
    }

    public static func video(gameName: String) -> String {
        "\(card(gameName: gameName))\n\n\(hashtags(gameName: gameName))"
    }

    public static func hashtags(gameName: String) -> String {
        let game = gameName.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init).joined()
        let base = "#LagCheck #Gamer #Ping #Lag"
        return game.isEmpty ? base : "\(base) #\(game)"
    }
}

final class ShareCancellationState: @unchecked Sendable {
    private let lock = NSLock()
    private var _isCancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isCancelled
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        _isCancelled = true
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _isCancelled = false
    }
}

/// Ícones das redes abaixo do card do resultado. O card já está pronto quando a barra habilita; o toque abre o menu do
/// sistema na hora. Para TikTok e Instagram o vídeo é gerado antes, com pop-up de progresso e botão de cancelar.
public struct ShareNetworkBar: View {
    public let scene: ShareMediaScene
    public let linkCardURL: URL?
    public let onDeliver: ([Any]) -> Void

    @State private var generating = false
    @State private var progress: Float = 0
    @State private var cancellation = ShareCancellationState()
    @State private var cachedVideoURL: URL? = nil
    @State private var errorMessage: String? = nil
    @State private var copiedNotice = false

    public init(scene: ShareMediaScene, linkCardURL: URL?, onDeliver: @escaping ([Any]) -> Void) {
        self.scene = scene
        self.linkCardURL = linkCardURL
        self.onDeliver = onDeliver
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(ShareSocialNetwork.allCases) { net in
                    Button { tap(net) } label: { socialIcon(for: net).frame(maxWidth: .infinity) }
                        .buttonStyle(.plain)
                        .disabled(linkCardURL == nil || generating)
                        .opacity(linkCardURL == nil ? 0.4 : 1)
                        .accessibilityLabel(net.label)
                        .accessibilityIdentifier("share-network-\(net.rawValue)")
                }
            }
            if copiedNotice {
                Text(AppLocalization.string("share.caption.copied", comment: ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NLColor.textSecondary)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NLColor.coralSolar)
                    .multilineTextAlignment(.center)
            }
        }
        .fullScreenCover(isPresented: $generating) {
            ShareVideoProgressPopup(progress: progress) { cancellation.cancel() }
                .presentationBackground(.clear)
        }
        .transaction { if generating { $0.disablesAnimations = true } }
        .onChange(of: scene) { _, _ in cachedVideoURL = nil }
    }

    private func tap(_ network: ShareSocialNetwork) {
        errorMessage = nil
        if network.sendsVideo { shareVideo() } else { shareCard() }
    }

    private func shareCard() {
        guard let linkCardURL, let image = UIImage(contentsOfFile: linkCardURL.path) else {
            errorMessage = AppLocalization.string("share.card.failed", comment: "")
            return
        }
        onDeliver([image, ShareCaption.card(gameName: scene.gameName)])
    }

    private func shareVideo() {
        let caption = ShareCaption.video(gameName: scene.gameName)
        if let cachedVideoURL, FileManager.default.fileExists(atPath: cachedVideoURL.path) {
            deliverVideo(cachedVideoURL, caption: caption, delay: false)
            return
        }
        progress = 0
        cancellation.reset()
        generating = true
        let currentScene = scene
        let currentCancellation = cancellation
        Task {
            do {
                let images = await Task.detached(priority: .userInitiated) {
                    ShareMediaImages.load(scene: currentScene, withTiles: true)
                }.value
                let url = try await ShareVideoRenderer.render(
                    scene: currentScene,
                    images: images,
                    isCancelled: { currentCancellation.isCancelled },
                    onProgress: { value in Task { @MainActor in progress = value } }
                )
                cachedVideoURL = url
                deliverVideo(url, caption: caption, delay: true)
            } catch {
                generating = false
                if !(error is ShareVideoRenderer.CancelledError) {
                    errorMessage = AppLocalization.string("share.video.failed", comment: "")
                }
            }
        }
    }

    /// Fecha o pop-up e abre o menu do sistema com o vídeo pronto; a legenda com hashtags já fica copiada.
    @MainActor
    private func deliverVideo(_ url: URL, caption: String, delay: Bool) {
        UIPasteboard.general.string = caption
        copiedNotice = true
        generating = false
        Task {
            // O menu só abre depois que o pop-up termina de sair.
            if delay { try? await Task.sleep(nanoseconds: 450_000_000) }
            onDeliver([url])
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            copiedNotice = false
        }
    }

    private func socialIcon(for network: ShareSocialNetwork) -> some View {
        ZStack {
            Circle()
                .fill(network.brandColor)
                .frame(width: 44, height: 44)

            switch network {
            case .whatsapp:
                WhatsAppLogo(size: 20, color: .white)
            case .discord:
                DiscordLogo(size: 20, color: .white)
            case .telegram:
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            case .tiktok:
                Text("♪")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
            case .x:
                Text("𝕏")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
            case .instagram:
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

/// Pop-up com a porcentagem de geração do vídeo e o botão de cancelar.
struct ShareVideoProgressPopup: View {
    let progress: Float
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(AppLocalization.string("share.video.generating", comment: ""))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NLColor.textPrimary)
                Text(verbatim: "\(Int(progress * 100))%")
                    .font(.system(size: 34, weight: .heavy).monospacedDigit())
                    .foregroundStyle(NLColor.textPrimary)
                ProgressView(value: progress, total: 1.0)
                    .tint(NLColor.gamerPurple)
                Button(action: onCancel) {
                    Text(AppLocalization.string("share.video.cancel", comment: ""))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(NLColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(NLColor.panel, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("share-video-cancel")
            }
            .padding(24)
            .frame(maxWidth: 300)
            .background(NLColor.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(NLColor.borderSubtle, lineWidth: 1))
        }
        .accessibilityElement(children: .contain)
    }
}
