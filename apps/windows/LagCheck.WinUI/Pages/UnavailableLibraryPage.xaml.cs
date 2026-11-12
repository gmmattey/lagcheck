using LagCheck.WinUI.Localization;
using Microsoft.UI.Xaml.Controls;

namespace LagCheck.WinUI.Pages;

public sealed partial class UnavailableLibraryPage : Page
{
    public UnavailableLibraryPage()
    {
        InitializeComponent();
        LocalizeUI();
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        Unloaded += (_, _) => LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
    }

    private void OnLanguageChanged() => DispatcherQueue.TryEnqueue(LocalizeUI);

    private void LocalizeUI()
    {
        EyebrowText.Text = Strings.Tr("INTEGRAÇÃO LOCAL");
        TitleText.Text = Strings.Tr("Biblioteca em integração");
        DescText.Text = Strings.Tr("A leitura local dos jogos instalados ainda não foi conectada à interface WinUI. Nenhum jogo é exibido até a fonte real ficar disponível.");
    }
}
