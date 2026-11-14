using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.Localization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace LagCheck.WinUI.Pages;

/// <summary>
/// Galeria local: lista somente capturas que o launcher já expôs no PC do usuário.
/// Nenhum arquivo é criado, enviado ou indexado fora da biblioteca local.
/// </summary>
public sealed partial class GalleryPage : Page
{
    private LibraryViewModel _viewModel;
    private bool _isLoaded;
    private bool _hasLoadError;

    public GalleryPage()
    {
        InitializeComponent();
        _viewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        Localize();
        ShowEmpty();
    }

    private async void GalleryPage_Loaded(object sender, RoutedEventArgs e)
    {
        _isLoaded = true;
        LocalizationService.Instance.LanguageChanged += OnLanguageChanged;
        await LoadGalleryAsync();
    }

    private void GalleryPage_Unloaded(object sender, RoutedEventArgs e)
    {
        _isLoaded = false;
        LocalizationService.Instance.LanguageChanged -= OnLanguageChanged;
    }

    private async Task LoadGalleryAsync()
    {
        var retryingAfterError = _hasLoadError;
        _hasLoadError = false;
        if (retryingAfterError)
            _viewModel = new LibraryViewModel(LibraryPageServices.Bridge, LibraryPageServices.DiagnosticNavigator);
        LoadingRing.Visibility = Visibility.Visible;
        EmptyState.Visibility = Visibility.Collapsed;
        GalleryScroll.Visibility = Visibility.Collapsed;
        try
        {
            // A ponte é a fonte única para a biblioteca. Ela só informa caminhos que os
            // launchers locais já descobriram; esta página não procura nem copia arquivos.
            await _viewModel.LoadAsync();
            if (!_isLoaded) return;
            if (!_viewModel.LastOperationSucceeded)
            {
                _hasLoadError = true;
                ShowLoadError();
                return;
            }

            BuildGallery(_viewModel.AllGames);
        }
        catch
        {
            if (_isLoaded)
            {
                _hasLoadError = true;
                ShowLoadError();
            }
        }
        finally
        {
            if (_isLoaded) LoadingRing.Visibility = Visibility.Collapsed;
        }
    }

    private void BuildGallery(IEnumerable<LibraryGame> games)
    {
        GameSectionsPanel.Children.Clear();
        var gamesWithShots = games
            .Select(game => new { Game = game, Shots = game.UserScreenshots.Where(HasLocalImage).ToList() })
            .Where(entry => entry.Shots.Count > 0)
            .ToList();

        if (gamesWithShots.Count == 0)
        {
            ShowEmpty();
            return;
        }

        foreach (var entry in gamesWithShots)
        {
            var section = new StackPanel { Spacing = 10 };
            section.Children.Add(new TextBlock
            {
                Text = entry.Game.Title,
                FontSize = 18,
                FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                TextTrimming = TextTrimming.CharacterEllipsis,
            });
            section.Children.Add(new TextBlock
            {
                Text = entry.Game.PlatformLabel,
                Style = (Style)Application.Current.Resources["TechLabelStyle"],
            });

            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12 };
            foreach (var shot in entry.Shots)
                row.Children.Add(CreateScreenshotButton(entry.Game, shot));

            section.Children.Add(new ScrollViewer
            {
                HorizontalScrollBarVisibility = ScrollBarVisibility.Auto,
                VerticalScrollBarVisibility = ScrollBarVisibility.Disabled,
                Content = row,
            });
            GameSectionsPanel.Children.Add(section);
        }

        EmptyState.Visibility = Visibility.Collapsed;
        GalleryScroll.Visibility = Visibility.Visible;
    }

    private Button CreateScreenshotButton(LibraryGame game, GameScreenshot shot)
    {
        var image = new Image
        {
            Width = 256,
            Height = 144,
            Stretch = Stretch.UniformToFill,
            Source = Artwork.Load(Artwork.FirstExisting(shot.ThumbnailPath, shot.Path), 640),
        };
        var button = new Button
        {
            Width = 260,
            Height = 148,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(8),
            Background = new SolidColorBrush(Color.FromArgb(0xFF, 0x17, 0x1B, 0x24)),
            BorderBrush = new SolidColorBrush(Color.FromArgb(0x1A, 0xFF, 0xFF, 0xFF)),
            BorderThickness = new Thickness(1),
            Content = image,
            Tag = shot,
        };
        var captureDate = shot.CreatedEpochMs is { } created ? FormatDate(created) : null;
        var captureName = string.IsNullOrWhiteSpace(captureDate)
            ? game.Title
            : $"{game.Title}, {captureDate}";
        AutomationProperties.SetName(button, $"{Strings.Tr("CAPTURAS")}: {captureName}");
        ToolTipService.SetToolTip(button, captureName);
        button.Click += Screenshot_Click;
        return button;
    }

    private async void Screenshot_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: GameScreenshot shot }) return;
        var viewer = new Image
        {
            Stretch = Stretch.Uniform,
            MaxHeight = 560,
            Source = Artwork.Load(shot.Path, 1920),
        };
        var dialog = new ContentDialog
        {
            XamlRoot = XamlRoot,
            Content = viewer,
            PrimaryButtonText = Strings.Tr("Abrir no visualizador"),
            CloseButtonText = Strings.Tr("Fechar"),
            DefaultButton = ContentDialogButton.Close,
        };
        try
        {
            if (await dialog.ShowAsync() == ContentDialogResult.Primary)
                await Windows.System.Launcher.LaunchFileAsync(await Windows.Storage.StorageFile.GetFileFromPathAsync(shot.Path));
        }
        catch
        {
            // A abertura é complementar; uma captura movida não afeta a galeria.
        }
    }

    private static bool HasLocalImage(GameScreenshot shot) => Artwork.FirstExisting(shot.Path) is not null;

    private void ShowEmpty()
    {
        GameSectionsPanel.Children.Clear();
        EmptyTitle.Text = Strings.Tr("Nenhuma captura local ainda.");
        EmptyDescription.Text = Strings.Tr("As capturas locais disponíveis nos jogos conhecidos aparecem aqui.");
        GalleryScroll.Visibility = Visibility.Collapsed;
        EmptyState.Visibility = Visibility.Visible;
    }

    private void ShowLoadError()
    {
        GameSectionsPanel.Children.Clear();
        EmptyTitle.Text = Strings.Tr("Não foi possível carregar as capturas agora.");
        EmptyDescription.Text = string.Empty;
        GalleryScroll.Visibility = Visibility.Collapsed;
        EmptyState.Visibility = Visibility.Visible;
    }

    private void OnLanguageChanged()
    {
        Localize();
        if (!_isLoaded) return;
        if (_hasLoadError) ShowLoadError();
        else BuildGallery(_viewModel.AllGames);
    }

    private void Localize()
    {
        Eyebrow.Text = Strings.Tr("CAPTURAS LOCAIS");
        TitleText.Text = Strings.Tr("GALERIA").ToUpper(CultureInfo.CurrentCulture);
        SubtitleText.Text = Strings.Tr("Capturas reais salvas no seu PC.");
        AutomationProperties.SetName(LoadingRing, Strings.Tr("Carregando capturas"));
    }

    private static string? FormatDate(long epochMs)
    {
        try
        {
            var culture = LocalizationService.Instance.EffectiveLanguage switch
            {
                AppLanguage.En => CultureInfo.GetCultureInfo("en-US"),
                AppLanguage.Es => CultureInfo.GetCultureInfo("es-ES"),
                _ => CultureInfo.GetCultureInfo("pt-BR"),
            };
            return DateTimeOffset.FromUnixTimeMilliseconds(epochMs)
                .ToLocalTime()
                .ToString("d", culture);
        }
        catch (ArgumentOutOfRangeException)
        {
            // Dado corrupto ou fora da faixa Unix: a captura continua acessível sem data inventada.
            return null;
        }
    }
}
