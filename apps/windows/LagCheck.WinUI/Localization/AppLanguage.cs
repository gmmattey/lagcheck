namespace LagCheck.WinUI.Localization;

/// <summary>Supported application languages for LagCheck on Windows.</summary>
public enum AppLanguage
{
    System,
    PtBr,
    En,
    Es
}

public static class AppLanguageExtensions
{
    public static string Code(this AppLanguage language) => language switch
    {
        AppLanguage.PtBr => "pt-BR",
        AppLanguage.En => "en",
        AppLanguage.Es => "es",
        _ => "system"
    };

    public static AppLanguage FromCode(string? code) => code?.Trim().ToLowerInvariant() switch
    {
        "pt" or "pt-br" or "pt_br" => AppLanguage.PtBr,
        "en" or "en-us" or "en_us" => AppLanguage.En,
        "es" or "es-es" or "es_es" => AppLanguage.Es,
        _ => AppLanguage.System
    };

    public static string DisplayName(this AppLanguage language) => language switch
    {
        AppLanguage.System => LocalizationService.Instance.Translate("Sistema (Padrão)"),
        AppLanguage.PtBr => "Português (Brasil)",
        AppLanguage.En => "English",
        AppLanguage.Es => "Español",
        _ => "Sistema (Padrão)"
    };
}
