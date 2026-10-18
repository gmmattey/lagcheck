import SwiftUI
import NolaggyDesign
import NolaggyDomain

/// Formato que a pessoa escolhe antes de tocar numa rede.
public enum ShareMediaFormat: String, CaseIterable, Identifiable, Sendable {
    case link
    case story
    case video

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .link: return "Link"
        case .story: return "Stories"
        case .video: return "Vídeo"
        }
    }
}

/// Redes sociais suportadas com identidade de marca autêntica.
public enum ShareSocialNetwork: String, CaseIterable, Identifiable, Sendable {
    case whatsapp
    case telegram
    case tiktok
    case x
    case instagram
    case discord
    case more

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .whatsapp: return "WhatsApp"
        case .telegram: return "Telegram"
        case .tiktok: return "TikTok"
        case .x: return "X"
        case .instagram: return "Instagram"
        case .discord: return "Discord"
        case .more: return "Mais"
        }
    }

    public var brandColor: Color {
        switch self {
        case .whatsapp: return Color(red: 37 / 255, green: 211 / 255, blue: 102 / 255)
        case .telegram: return Color(red: 38 / 255, green: 165 / 255, blue: 228 / 255)
        case .tiktok: return Color.black
        case .x: return Color.black
        case .instagram: return Color(red: 228 / 255, green: 64 / 255, blue: 95 / 255)
        case .discord: return Color(red: 88 / 255, green: 101 / 255, blue: 242 / 255)
        case .more: return Color(red: 30 / 255, green: 35 / 255, blue: 43 / 255)
        }
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

/// Folha modal "Compartilhar": escolhe o formato (link 1200×630, Stories 1080×1920 ou vídeo 9:16 de 14 s)
/// e envia para a rede selecionada ou seletor nativo do sistema.
/// Paridade 1:1 estrita com ShareMediaSheet.kt do Android (Decisões 81 e 103).
public struct ShareMediaSheetView: View {
    public let scene: ShareMediaScene
    public let preparedLinkCardURL: URL?
    public let highlightedNetwork: ShareSocialNetwork?
    public let onDismiss: () -> Void

    @State private var format: ShareMediaFormat = .link
    @State private var previewImage: UIImage? = nil
    @State private var isWorking = false
    @State private var workingNetwork: ShareSocialNetwork? = nil
    @State private var progress: Float = 0
    @State private var errorMessage: String? = nil
    @State private var activeShareItems: [Any]? = nil
    @State private var cancellation = ShareCancellationState()

    public init(
        scene: ShareMediaScene,
        preparedLinkCardURL: URL?,
        highlightedNetwork: ShareSocialNetwork? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.scene = scene
        self.preparedLinkCardURL = preparedLinkCardURL
        self.highlightedNetwork = highlightedNetwork
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Seletor de Formato (Segmented: Link | Stories | Vídeo)
                Picker("Formato", selection: $format) {
                    ForEach(ShareMediaFormat.allCases) { f in
                        Text(f.label).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .onChange(of: format) { _, newFormat in
                    updatePreview(for: newFormat)
                }

                // Área de Prévia Dinâmica
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(NLColor.surface)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(NLColor.borderSubtle, lineWidth: 1))

                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        ProgressView()
                            .tint(NLColor.gamerPurple)
                    }

                    if format == .video {
                        VStack {
                            Spacer()
                            HStack {
                                Label("14 s", systemImage: "play.circle.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.black.opacity(0.65), in: Capsule())
                                Spacer()
                            }
                            .padding(12)
                        }
                    }
                }
                .frame(maxWidth: 320)
                .frame(height: format == .link ? 168 : 280)
                .animation(.easeInOut(duration: 0.25), value: format)
                .padding(.horizontal, 20)

                // Progresso do Render de Vídeo (se ativo)
                if isWorking {
                    VStack(spacing: 6) {
                        ProgressView(value: progress, total: 1.0)
                            .tint(NLColor.gamerPurple)
                        Text(format == .video ? "Gerando vídeo 14 s (\(Int(progress * 100))%)…" : "Preparando card…")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(NLColor.textSecondary)
                    }
                    .padding(.horizontal, 28)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(NLColor.coralSolar)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                Spacer(minLength: 8)

                // Barra de Redes Sociais
                VStack(alignment: .leading, spacing: 10) {
                    Text("Compartilhar com:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(NLColor.textTertiary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        ForEach([ShareSocialNetwork.whatsapp, .telegram, .tiktok, .x, .instagram, .discord, .more]) { net in
                            Button {
                                handleShare(to: net)
                            } label: {
                                socialIcon(for: net)
                            }
                            .buttonStyle(.plain)
                            .disabled(isWorking)
                            .accessibilityLabel(net.label)
                            .accessibilityIdentifier("share-sheet-network-\(net.rawValue)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .background(NLColor.deep.ignoresSafeArea())
            .navigationTitle("Compartilhar resultado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") {
                        cancellation.cancel()
                        onDismiss()
                    }
                    .foregroundStyle(NLColor.textSecondary)
                }
            }
            .sheet(isPresented: Binding(get: { activeShareItems != nil }, set: { if !$0 { activeShareItems = nil } })) {
                if let items = activeShareItems {
                    ShareSheet(items: items)
                }
            }
            .onAppear {
                updatePreview(for: format)
            }
        }
    }

    private func updatePreview(for targetFormat: ShareMediaFormat) {
        if targetFormat == .link, let preparedLinkCardURL,
           let image = UIImage(contentsOfFile: preparedLinkCardURL.path) {
            previewImage = image
            return
        }

        let currentScene = self.scene
        Task {
            let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                let images = ShareMediaImages.load(scene: currentScene, withTiles: false)
                let kind: ShareMediaRenderer.Kind = (targetFormat == .link) ? .preview : .story
                guard let data = ShareMediaRenderer.jpeg(kind: kind, scene: currentScene, images: images) else {
                    return nil
                }
                return UIImage(data: data)
            }.value

            if let image {
                self.previewImage = image
            }
        }
    }

    private func handleShare(to network: ShareSocialNetwork) {
        guard !isWorking else { return }
        isWorking = true
        workingNetwork = network
        progress = 0
        errorMessage = nil
        cancellation.reset()

        let selectedFormat = self.format
        let currentScene = self.scene
        let linkCardURL = self.preparedLinkCardURL
        let localeTag = AppLocalization.locale.identifier
        let currentCancellation = self.cancellation
        let caption = "Testei minha conexão para jogar \(currentScene.gameName) no Lagcheck. Teste a sua: https://lagcheck.signallq.com"

        Task {
            switch selectedFormat {
            case .link:
                let url = await Task.detached(priority: .userInitiated) { () -> URL? in
                    if let linkCardURL, FileManager.default.fileExists(atPath: linkCardURL.path) {
                        return linkCardURL
                    }
                    let snapshot = PreparedShareCardSnapshot.from(
                        scene: currentScene,
                        localeTag: localeTag,
                        measurementIdentity: UUID().uuidString
                    )
                    return PreparedShareCard.prepare(snapshot: snapshot)
                }.value

                self.isWorking = false
                guard let url else {
                    self.errorMessage = "Não foi possível gerar o card de link."
                    return
                }
                self.deliverShare(fileURL: url, caption: caption, network: network)

            case .story:
                let tempURL = await Task.detached(priority: .userInitiated) { () -> URL? in
                    let images = ShareMediaImages.load(scene: currentScene, withTiles: false)
                    guard let data = ShareMediaRenderer.jpeg(kind: .story, scene: currentScene, images: images) else {
                        return nil
                    }
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("lagcheck-story-\(UUID().uuidString).jpg")
                    try? data.write(to: url)
                    return url
                }.value

                self.isWorking = false
                guard let tempURL, FileManager.default.fileExists(atPath: tempURL.path) else {
                    self.errorMessage = "Não foi possível gerar a imagem para Stories."
                    return
                }
                self.deliverShare(fileURL: tempURL, caption: caption, network: network)

            case .video:
                do {
                    let images = await Task.detached(priority: .userInitiated) {
                        ShareMediaImages.load(scene: currentScene, withTiles: true)
                    }.value

                    let videoURL = try await ShareVideoRenderer.render(
                        scene: currentScene,
                        images: images,
                        isCancelled: { currentCancellation.isCancelled },
                        onProgress: { prog in
                            Task { @MainActor in
                                self.progress = prog
                            }
                        }
                    )
                    self.isWorking = false
                    self.deliverShare(fileURL: videoURL, caption: caption, network: network)
                } catch {
                    self.isWorking = false
                    if !(error is ShareVideoRenderer.CancelledError) {
                        self.errorMessage = "Falha ao gerar vídeo: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    @MainActor
    private func deliverShare(fileURL: URL, caption: String, network: ShareSocialNetwork) {
        if network == .discord {
            if let image = UIImage(contentsOfFile: fileURL.path) {
                UIPasteboard.general.image = image
            }
            activeShareItems = [fileURL, caption]
        } else if network == .whatsapp {
            activeShareItems = [fileURL, caption]
        } else {
            activeShareItems = [fileURL, caption]
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
            case .more:
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}
