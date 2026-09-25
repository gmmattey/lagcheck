import SwiftUI

/// Tokens de cor oficiais do LagCheck — Dark Competitive UI (Decisões 50 e 51).
/// Fundo profundo quase preto, superfícies grafite, bordas finas e Coral Solar exclusivo para ação primária.
public enum NLColor {
    // MARK: - Dark Competitive Background Surfaces (Decisão 51)
    /// Fundo profundo quase preto (#0B0D10)
    public static let deep = Color(red: 11 / 255, green: 13 / 255, blue: 16 / 255)
    /// Superfície grafite para cards e contêineres (#15181E)
    public static let surface = Color(red: 21 / 255, green: 24 / 255, blue: 30 / 255)
    /// Painéis escuros elevados (#1E232B)
    public static let panel = Color(red: 30 / 255, green: 35 / 255, blue: 43 / 255)

    // Aliases para compatibilidade de componentes existentes
    public static let backgroundBase = deep
    public static let backgroundRaised = surface
    public static let backgroundOverlay = panel
    public static let controlOverlay = Color.white.opacity(0.06)
    public static let settingsSurface = surface

    // MARK: - Hairline Borders (1px contínuo, Decisão 51)
    public static let borderHairline = Color.white.opacity(0.08)
    public static let borderSubtle = Color.white.opacity(0.08)
    public static let borderStrong = Color.white.opacity(0.14)
    public static let borderFocus = coralSolar

    // MARK: - Dark Competitive Typography Colors
    /// Texto primário de alto contraste (#F4F5F7)
    public static let textPrimary = Color(red: 244 / 255, green: 245 / 255, blue: 247 / 255)
    /// Texto secundário neutro (#8A93A0)
    public static let textSecondary = Color(red: 138 / 255, green: 147 / 255, blue: 160 / 255)
    /// Texto terciário / labels auxiliares (#555E6C)
    public static let textTertiary = Color(red: 85 / 255, green: 94 / 255, blue: 108 / 255)
    public static let textDisabled = Color(red: 55 / 255, green: 62 / 255, blue: 72 / 255)
    public static let textOnAccent = Color.white
    public static let textLink = coralSolar

    // MARK: - Coral Solar Action Accent (Decisões 25 e 51)
    /// Coral Solar assinatura (#FF5A36) — ÚNICA cor de ação primária
    public static let coralSolar = Color(red: 255 / 255, green: 90 / 255, blue: 54 / 255)
    public static let coralSolarRed = Color(red: 255 / 255, green: 56 / 255, blue: 35 / 255)
    public static let coralSolarAmber = Color(red: 255 / 255, green: 171 / 255, blue: 46 / 255)
    public static let coralSolarStrong = Color(red: 235 / 255, green: 77 / 255, blue: 38 / 255)

    public static let coralSolarGradient = LinearGradient(
        colors: [coralSolarRed, coralSolar, coralSolarAmber],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    public static let coralSolarHorizontalGradient = LinearGradient(
        colors: [coralSolarRed, coralSolar, coralSolarAmber],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let accentPrimary = coralSolar
    public static let accentPrimaryStrong = coralSolarStrong
    public static let accentPrimarySubtle = coralSolar.opacity(0.15)

    // MARK: - Semantic Verdict Colors (Decisão 51 — Verde RESTobserver ao veredito .ready)
    /// Verde semântico (#22C55E) — restrito ao veredito READY (NUNCA cor de ação)
    public static let semanticReady = Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255)
    /// Âmbar semântico (#F59E0B) — veredito CAUTION / Atenção
    public static let semanticCaution = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)
    /// Vermelho semântico (#EF4444) — veredito NOT READY / Evitar partida
    public static let semanticNotReady = Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255)
    /// Neutro semântico (#8A93A0) — veredito INCONCLUSIVE
    public static let semanticNeutral = textSecondary

    // Aliases para legado
    public static let scoreExcellent = semanticReady
    public static let scoreExcellentSubtle = semanticReady.opacity(0.16)
    public static let scoreUnstable = semanticCaution
    public static let scoreUnstableSubtle = semanticCaution.opacity(0.16)
    public static let scoreLagRisk = semanticNotReady
    public static let scoreLagRiskSubtle = semanticNotReady.opacity(0.16)
    public static let scoreNeutral = textSecondary
    public static let scoreNeutralSubtle = textSecondary.opacity(0.16)
}
