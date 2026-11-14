using System;
using System.IO;
using LagCheck.WinUI.Windowing;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class WindowPrefsStoreTests : IDisposable
{
    private readonly string _directory = Path.Combine(Path.GetTempPath(), "LagCheck_WindowTests_" + Guid.NewGuid().ToString("N"));

    public void Dispose()
    {
        try
        {
            if (Directory.Exists(_directory))
            {
                Directory.Delete(_directory, recursive: true);
            }
        }
        catch
        {
            // Limpeza de testes descartável
        }
    }

    [Fact]
    public void Load_returns_default_false_when_file_does_not_exist()
    {
        var path = Path.Combine(_directory, "window_settings.json");
        var store = new WindowPrefsStore(path);

        var prefs = store.Load();

        Assert.NotNull(prefs);
        Assert.False(prefs.StartFullScreen);
    }

    [Fact]
    public void Save_and_Load_roundtrips_start_full_screen_preference()
    {
        var path = Path.Combine(_directory, "window_settings.json");
        var store = new WindowPrefsStore(path);

        store.Save(new WindowPrefs { StartFullScreen = true });
        var loadedTrue = store.Load();
        Assert.True(loadedTrue.StartFullScreen);

        store.Save(new WindowPrefs { StartFullScreen = false });
        var loadedFalse = store.Load();
        Assert.False(loadedFalse.StartFullScreen);
    }

    [Fact]
    public void Load_recovers_gracefully_with_default_false_when_json_is_corrupt()
    {
        Directory.CreateDirectory(_directory);
        var path = Path.Combine(_directory, "window_settings.json");
        File.WriteAllText(path, "{ corrupted json payload [[[ !@#$");

        var store = new WindowPrefsStore(path);
        var prefs = store.Load();

        Assert.NotNull(prefs);
        Assert.False(prefs.StartFullScreen);
    }

    [Fact]
    public void Save_creates_non_existent_directory_and_writes_file()
    {
        var nestedDir = Path.Combine(_directory, "sub", "deep", "config");
        var path = Path.Combine(nestedDir, "window_settings.json");
        var store = new WindowPrefsStore(path);

        Assert.False(Directory.Exists(nestedDir));

        store.Save(new WindowPrefs { StartFullScreen = true });

        Assert.True(File.Exists(path));
        var reloaded = new WindowPrefsStore(path).Load();
        Assert.True(reloaded.StartFullScreen);
    }

    [Fact]
    public void Load_returns_default_false_when_directory_does_not_exist()
    {
        var nonExistentDir = Path.Combine(_directory, "not_created");
        var path = Path.Combine(nonExistentDir, "window_settings.json");
        var store = new WindowPrefsStore(path);

        var prefs = store.Load();

        Assert.NotNull(prefs);
        Assert.False(prefs.StartFullScreen);
    }
}
