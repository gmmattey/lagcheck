namespace LagCheck.WinUI.Windowing;

using System;
using Microsoft.UI.Windowing;
using Windows.Graphics;

public static class WindowMode
{
    private static readonly WindowPrefsStore _prefsStore = new();
    private static Microsoft.UI.Xaml.Window? _window;
    private static AppWindow? _appWindow;
    private static RectInt32? _savedBounds;
    private static bool _lastFullScreen;

    public static bool IsFullScreen
    {
        get
        {
            try
            {
                return _appWindow?.Presenter?.Kind == AppWindowPresenterKind.FullScreen;
            }
            catch
            {
                return false;
            }
        }
    }

    public static bool StartFullScreen
    {
        get
        {
            try
            {
                return _prefsStore.Load().StartFullScreen;
            }
            catch
            {
                return false;
            }
        }
        set
        {
            try
            {
                var prefs = _prefsStore.Load();
                if (prefs.StartFullScreen != value)
                {
                    prefs.StartFullScreen = value;
                    _prefsStore.Save(prefs);
                }
            }
            catch
            {
                // Tolerante a erro
            }
        }
    }

    public static event Action? FullScreenChanged;

    internal static void Attach(Microsoft.UI.Xaml.Window window)
    {
        _window = window;
        _appWindow = window.AppWindow;
        if (_appWindow is not null)
        {
            try
            {
                var pos = _appWindow.Position;
                var size = _appWindow.Size;
                if (size.Width > 0 && size.Height > 0)
                {
                    _savedBounds = new RectInt32(pos.X, pos.Y, size.Width, size.Height);
                }
                else
                {
                    _savedBounds = new RectInt32(100, 100, 1120, 740);
                }
                _lastFullScreen = _appWindow.Presenter?.Kind == AppWindowPresenterKind.FullScreen;
            }
            catch
            {
                _savedBounds = new RectInt32(100, 100, 1120, 740);
            }

            _appWindow.Changed -= OnAppWindowChanged;
            _appWindow.Changed += OnAppWindowChanged;
        }
    }

    private static void OnAppWindowChanged(AppWindow sender, AppWindowChangedEventArgs args)
    {
        try
        {
            var isFs = sender.Presenter?.Kind == AppWindowPresenterKind.FullScreen;
            if (isFs != _lastFullScreen)
            {
                _lastFullScreen = isFs;
                FullScreenChanged?.Invoke();
            }
        }
        catch
        {
            // Proteção contra falhas no evento de mudança
        }
    }

    public static void SetFullScreen(bool on)
    {
        if (_appWindow is null) return;
        try
        {
            if (on)
            {
                if (_appWindow.Presenter?.Kind != AppWindowPresenterKind.FullScreen)
                {
                    var pos = _appWindow.Position;
                    var size = _appWindow.Size;
                    if (size.Width > 0 && size.Height > 0)
                    {
                        _savedBounds = new RectInt32(pos.X, pos.Y, size.Width, size.Height);
                    }
                    _appWindow.SetPresenter(AppWindowPresenterKind.FullScreen);
                }
            }
            else
            {
                if (_appWindow.Presenter?.Kind == AppWindowPresenterKind.FullScreen)
                {
                    _appWindow.SetPresenter(AppWindowPresenterKind.Overlapped);
                    if (_savedBounds is { Width: > 0, Height: > 0 } bounds)
                    {
                        _appWindow.MoveAndResize(bounds);
                    }
                }
            }

            var currentFs = _appWindow.Presenter?.Kind == AppWindowPresenterKind.FullScreen;
            if (currentFs != _lastFullScreen)
            {
                _lastFullScreen = currentFs;
                FullScreenChanged?.Invoke();
            }
        }
        catch
        {
            // Tudo em try/catch
        }
    }
}
