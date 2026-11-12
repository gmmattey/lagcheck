namespace LagCheck.WinUI.Localization;

/// <summary>Global convenience helper for string localization across WinUI 3 views and models.</summary>
public static class Strings
{
    public static string Tr(string key) => LocalizationService.Instance.Translate(key);
    public static string Format(string format, params object[] args) => LocalizationService.Instance.Format(format, args);
}
