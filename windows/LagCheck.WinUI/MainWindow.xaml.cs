using Microsoft.UI;
using Microsoft.UI.Xaml;
using Windows.Graphics;

namespace LagCheck.WinUI;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        AppWindow.Resize(new SizeInt32(1120, 740));
        var bar = AppWindow.TitleBar;
        bar.BackgroundColor = ColorHelper.FromArgb(255, 6, 7, 9);
        bar.ForegroundColor = ColorHelper.FromArgb(255, 244, 245, 247);
        bar.ButtonBackgroundColor = ColorHelper.FromArgb(255, 6, 7, 9);
        bar.ButtonForegroundColor = ColorHelper.FromArgb(255, 244, 245, 247);
    }
}
