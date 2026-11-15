using System.Runtime.InteropServices;
using Microsoft.UI;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Windows.Graphics;
using LagCheck.WinUI.Windowing;

namespace LagCheck.WinUI;

public sealed partial class MainWindow : Window
{
    [DllImport("user32.dll")]
    private static extern uint GetDpiForWindow(nint hWnd);

    public MainWindow()
    {
        InitializeComponent();
        var workArea = DisplayArea.GetFromWindowId(AppWindow.Id, DisplayAreaFallback.Primary).WorkArea;
        var dpi = GetDpiForWindow(WinRT.Interop.WindowNative.GetWindowHandle(this));
        var scale = Math.Max(1.0, dpi / 96.0);
        var width = Math.Min(workArea.Width, (int)Math.Round(1600 * scale));
        var height = Math.Min(workArea.Height, (int)Math.Round(940 * scale));
        var restoredBounds = new RectInt32(
            workArea.X + Math.Max(0, (workArea.Width - width) / 2),
            workArea.Y + Math.Max(0, (workArea.Height - height) / 2),
            width,
            height);
        AppWindow.MoveAndResize(restoredBounds);
        WindowMode.SetRestoredBounds(restoredBounds);
        Title = "LagCheck";
        try
        {
            var icon = System.IO.Path.Combine(AppContext.BaseDirectory, "Assets", "lagcheck.ico");
            if (System.IO.File.Exists(icon)) AppWindow.SetIcon(icon);
        }
        catch
        {
            // Sem o .ico a janela só mantém o ícone genérico: nunca impede o app de abrir.
        }

        // Integração total da barra de título à janela do aplicativo (ExtendsContentIntoTitleBar)
        ExtendsContentIntoTitleBar = true;
        SetTitleBar(ShellRoot.TitleBarDragRegion);

        if (AppWindowTitleBar.IsCustomizationSupported())
        {
            var titleBar = AppWindow.TitleBar;
            titleBar.ExtendsContentIntoTitleBar = true;
            titleBar.PreferredHeightOption = TitleBarHeightOption.Standard;

            // Botões nativos de Fechar, Maximizar e Minimizar integrados de forma transparente
            titleBar.ButtonBackgroundColor = Colors.Transparent;
            titleBar.ButtonInactiveBackgroundColor = Colors.Transparent;
            titleBar.ButtonHoverBackgroundColor = ColorHelper.FromArgb(255, 32, 38, 51); // #202633
            titleBar.ButtonPressedBackgroundColor = ColorHelper.FromArgb(255, 23, 27, 36); // #171B24
            titleBar.ButtonForegroundColor = ColorHelper.FromArgb(255, 245, 247, 252); // #F5F7FC
            titleBar.ButtonHoverForegroundColor = Colors.White;
            titleBar.ButtonInactiveForegroundColor = ColorHelper.FromArgb(255, 104, 114, 133); // #687285
        }

        WindowMode.Attach(this);
        if (!WindowMode.StartFullScreen && AppWindow.Presenter is OverlappedPresenter overlapped)
        {
            overlapped.Maximize();
        }
        if (WindowMode.StartFullScreen)
        {
            try
            {
                WindowMode.SetFullScreen(true);
            }
            catch
            {
                // Se o presenter não puder ser trocado antes do Activate, o DispatcherQueue garante logo depois.
            }

            DispatcherQueue.TryEnqueue(() =>
            {
                if (WindowMode.StartFullScreen && !WindowMode.IsFullScreen)
                {
                    WindowMode.SetFullScreen(true);
                }
            });
        }
    }
}
