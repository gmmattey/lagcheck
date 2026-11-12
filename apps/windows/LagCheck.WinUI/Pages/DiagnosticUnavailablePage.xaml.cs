using LagCheck.WinUI.Localization;
using Microsoft.UI.Xaml.Controls;

namespace LagCheck.WinUI.Pages;

public sealed partial class DiagnosticUnavailablePage : Page
{
    public DiagnosticUnavailablePage()
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
        TitleText.Text = Strings.Tr("Diagnóstico indisponível");
        DescText.Text = Strings.Tr("O motor compartilhado ainda não está conectado a esta interface. Nenhuma medição foi iniciada e nenhum resultado foi criado.");
    }
}
