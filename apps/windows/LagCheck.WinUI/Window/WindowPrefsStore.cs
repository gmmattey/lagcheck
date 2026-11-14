namespace LagCheck.WinUI.Windowing;

using System;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;

public sealed class WindowPrefs
{
    [JsonPropertyName("startFullScreen")]
    public bool StartFullScreen { get; set; }
}

public sealed class WindowPrefsStore
{
    private readonly string _path;

    public WindowPrefsStore(string? path = null)
    {
        _path = path ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "LagCheck",
            "window_settings.json");
    }

    public WindowPrefs Load()
    {
        try
        {
            if (!File.Exists(_path)) return new WindowPrefs();
            var json = File.ReadAllText(_path);
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            return JsonSerializer.Deserialize<WindowPrefs>(json, options) ?? new WindowPrefs();
        }
        catch
        {
            return new WindowPrefs();
        }
    }

    public void Save(WindowPrefs prefs)
    {
        if (prefs is null) return;
        try
        {
            var dir = Path.GetDirectoryName(_path);
            if (!string.IsNullOrEmpty(dir))
            {
                Directory.CreateDirectory(dir);
            }
            var options = new JsonSerializerOptions { WriteIndented = false };
            var json = JsonSerializer.Serialize(prefs, options);
            File.WriteAllText(_path, json);
        }
        catch
        {
            // Erros de escrita ignorados silenciosamente (sem disco/permissão, mantém sessão atual).
        }
    }
}
