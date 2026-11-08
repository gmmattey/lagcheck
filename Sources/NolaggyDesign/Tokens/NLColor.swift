import SwiftUI

/// Tokens de cor oficiais do LagCheck Design System.
/// Fundo profundo quase preto, superfícies grafite, bordas finas de 1px.
/// Roxo Gamer (#7C3AED) é reservado para ação, seleção, foco e progresso.
/// Coral Solar (#FF5A36) é reservado estritamente para atenção, erro ou ações destrutivas.
public enum NLColor {
    // MARK: - Dark Surfaces (DESIGN.md / colors_and_type.css)
    /// Fundo profundo quase preto (#0B0D10 / oklch(0.158 0.011 260))
    public static let deep = Color(red: 11 / 255, green: 13 / 255, blue: 16 / 255)
    /// Palco de canvas profundo (#060709 / oklch(0.09 0.009 260))
    public static let stage = Color(red: 6 / 255, green: 7 / 255, blue: 9 / 255)
    /// Superfície grafite para cards e contêineres (#15181E / oklch(0.205 0.012 260))
    public static let surface = Color(red: 21 / 255, green: 24 / 255, blue: 30 / 255)
    /// Painéis e superfícies elevadas (#1E232B / oklch(0.23 0.014 260))
    public static let panel = Color(red: 30 / 255, green: 35 / 255, blue: 43 / 255)

    // Aliases para compatibilidade de componentes existentes
    public static let backgroundBase = deep
    public static let backgroundRaised = surface
    public static let backgroundOverlay = panel
    public static let controlOverlay = Color.white.opacity(0.06)
    public static let settingsSurface = surface

    // MARK: - Hairline Borders (1px contínuo, DESIGN.md)
    public static let borderHairline = Color.white.opacity(0.08)
    public static let borderSubtle = Color.white.opacity(0.10)
    public static let borderStrong = Color.white.opacity(0.16)
    public static let borderFocus = gamerPurple

    // MARK: - Dark Competitive Typography Colors
    /// Texto primário de alto contraste (#F4F5F7 / oklch(0.955 0.006 260))
    public static let textPrimary = Color(red: 244 / 255, green: 245 / 255, blue: 247 / 255)
    /// Texto secundário neutro (#8A93A0 / oklch(0.675 0.014 260))
    public static let textSecondary = Color(red: 138 / 255, green: 147 / 255, blue: 160 / 255)
    /// Texto terciário / labels auxiliares (#606873, igual ao Android e ao Windows; Decisão 117)
    public static let textTertiary = Color(red: 96 / 255, green: 104 / 255, blue: 115 / 255)
    public static let textDisabled = Color(red: 55 / 255, green: 62 / 255, blue: 72 / 255)
    public static let textOnAccent = Color.white
    public static let textLink = gamerPurple

    // MARK: - Roxo Gamer: Ação, Seleção, Foco e Progresso (#7C3AED / oklch(0.585 0.214 299))
    /// Roxo Gamer assinatura (#7C3AED) — cor oficial de ação primária, seleção e foco
    public static let gamerPurple = Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255)
    public static let gamerPurpleStrong = Color(red: 109 / 255, green: 40 / 255, blue: 217 / 255)
    public static let gamerPurpleLight = Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255)
    public static let gamerPurpleDeep = Color(red: 91 / 255, green: 33 / 255, blue: 182 / 255)

    public static let gamerPurpleGradient = LinearGradient(
        colors: [gamerPurpleDeep, gamerPurple, gamerPurpleLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let accentPrimary = gamerPurple
    public static let accentPrimaryStrong = gamerPurpleStrong
    public static let accentPrimaryHover = gamerPurpleLight
    public static let accentPrimarySubtle = gamerPurple.opacity(0.15)

    // MARK: - Coral Solar: Atenção, Erro ou Ações Destrutivas (#FF5A36 / oklch(0.684 0.196 35))
    /// Coral Solar (#FF5A36) — reservado estritamente para atenção, erro ou ações destrutivas
    public static let coralSolar = Color(red: 255 / 255, green: 90 / 255, blue: 54 / 255)
    public static let coralSolarRed = Color(red: 255 / 255, green: 56 / 255, blue: 35 / 255)
    public static let coralSolarAmber = Color(red: 255 / 255, green: 171 / 255, blue: 46 / 255)
    public static let coralSolarStrong = Color(red: 235 / 255, green: 77 / 255, blue: 38 / 255)
    public static let attention = coralSolar

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

    // MARK: - Semantic Verdict Colors (DESIGN.md)
    /// Verde semântico (#22C55E / oklch(0.76 0.15 150)) — restrito ao veredito READY / favorável
    public static let semanticReady = Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255)
    /// Âmbar semântico (#F59E0B / oklch(0.76 0.15 80)) — veredito CAUTION / Atenção
    public static let semanticCaution = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)
    /// Vermelho/Coral semântico (#FF5A36 / oklch(0.684 0.196 35)) — veredito NOT READY / Evitar partida
    public static let semanticNotReady = coralSolar
    /// Neutro semântico (#8A93A0) — veredito INCONCLUSIVE
    public static let semanticNeutral = textSecondary

    // Aliases para legado e conveniência
    public static let hairline = borderHairline
    public static let readyGreen = semanticReady
    public static let cautionYellow = semanticCaution
    public static let notReadyRed = semanticNotReady
    public static let scoreExcellent = semanticReady
    public static let scoreExcellentSubtle = semanticReady.opacity(0.16)
    public static let scoreUnstable = semanticCaution
    public static let scoreUnstableSubtle = semanticCaution.opacity(0.16)
    public static let scoreLagRisk = coralSolar
    public static let scoreLagRiskSubtle = coralSolar.opacity(0.16)
    public static let scoreNeutral = textSecondary
    public static let scoreNeutralSubtle = textSecondary.opacity(0.16)
}

/// Cores de marca de terceiros. Não fazem parte da paleta do LagCheck: são exceções
/// documentadas (design-system/tokens/platforms.json, Decisão 117) e ficam só aqui,
/// nunca soltas em telas. Espelham `LagCheckBrandColors` do Android.
public enum NLBrandColor {
    public static let whatsapp = Color(red: 37 / 255, green: 211 / 255, blue: 102 / 255)
    public static let telegram = Color(red: 38 / 255, green: 165 / 255, blue: 228 / 255)
    public static let instagram = Color(red: 228 / 255, green: 64 / 255, blue: 95 / 255)
    public static let discord = Color(red: 88 / 255, green: 101 / 255, blue: 242 / 255)
    public static let x = Color.black
    public static let tiktok = Color.black
}
