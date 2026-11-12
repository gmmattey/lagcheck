using Microsoft.UI;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Windows.Graphics;

namespace LagCheck.WinUI;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        AppWindow.Resize(new SizeInt32(1120, 740));

        // Integração total da barra de título à janela do aplicativo (ExtendsContentIntoTitleBar)
        ExtendsContentIntoTitleBar = true;

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
    }
}
