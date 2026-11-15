using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Localization;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace LagCheck.WinUI.Widgets;

/// <summary>
/// Moldura única de todo widget: vidro, cabeçalho (ícone, título, ação), corpo, rodapé, estados
/// (carregando, vazio, desatualizado, erro), feedback de hover/foco e modo de edição
/// (mover, redimensionar, ocultar, arrastar). Os widgets só entregam <see cref="WidgetContent"/>.
/// </summary>
public sealed class WidgetCard : Grid
{
    private static readonly Color SurfaceTop = Color.FromArgb(0xEE, 0x1E, 0x24, 0x30);
    private static readonly Color SurfaceBottom = Color.FromArgb(0xEE, 0x14, 0x18, 0x21);
    private static readonly Color SurfaceHoverTop = Color.FromArgb(0xF5, 0x26, 0x2D, 0x3B);
    private static readonly Color SurfaceHoverBottom = Color.FromArgb(0xF5, 0x19, 0x1E, 0x29);

    private readonly Rectangle _shadowCaster = new() { RadiusX = 12, RadiusY = 12, Fill = new SolidColorBrush(Color.FromArgb(255, 0x0B, 0x0D, 0x10)), IsHitTestVisible = false };
    private readonly Border _frame = new() { CornerRadius = new CornerRadius(12), BorderThickness = new Thickness(1), Padding = new Thickness(16, 12, 16, 12) };
    private readonly LinearGradientBrush _surfaceBrush = VerticalGradient(SurfaceTop, SurfaceBottom);
    private readonly LinearGradientBrush _surfaceHoverBrush = VerticalGradient(SurfaceHoverTop, SurfaceHoverBottom);
    private readonly LinearGradientBrush _defaultBorderBrush = VerticalGradient(Color.FromArgb(0x30, 255, 255, 255), Color.FromArgb(0x12, 255, 255, 255));
    private readonly SvgIcon _icon = new() { Size = 14 };
    private readonly TextBlock _title = new() { FontFamily = (FontFamily)Application.Current.Resources["TechnicalFont"], FontSize = 11, FontWeight = Microsoft.UI.Text.FontWeights.Normal, CharacterSpacing = 70, VerticalAlignment = VerticalAlignment.Center, TextTrimming = TextTrimming.CharacterEllipsis };
    private readonly Button _actionButton = new();
    private readonly StackPanel _editBar = new() { Orientation = Orientation.Horizontal, Spacing = 4, Visibility = Visibility.Collapsed };
    private readonly Button _sizeButton = new();
    private readonly Grid _bodyHost = new();
    private readonly TextBlock _caption = new() { FontSize = 13, TextTrimming = TextTrimming.CharacterEllipsis, Margin = new Thickness(0, 6, 0, 0) };
    private readonly Border _staleChip = new();
    private readonly Rectangle _editOutline = new() { RadiusX = 12, RadiusY = 12, StrokeThickness = 1.5, StrokeDashArray = { 4, 3 }, IsHitTestVisible = false, Opacity = 0 };
    private readonly Grid _skeleton = new() { RowSpacing = 8, Visibility = Visibility.Collapsed };

    private Action? _activate;
    private bool _editing;
    private bool _hovered;
    private Storyboard? _pulse;

    public WidgetCard(string widgetId)
    {
        WidgetId = widgetId;
        UseLayoutRounding = true;
        Fluid.Prepare(this);
        BuildChrome();
        BuildSkeleton();

        PointerEntered += (_, _) => SetHover(true);
        PointerExited += (_, _) => SetHover(false);
        GotFocus += (_, _) => SetHover(true);
        LostFocus += (_, _) => SetHover(false);
        Tapped += OnTapped;
        KeyDown += OnKeyDown;
        DragStarting += (_, e) =>
        {
            e.Data.SetText(WidgetId);
            e.Data.RequestedOperation = Windows.ApplicationModel.DataTransfer.DataPackageOperation.Move;
        };
        Unloaded += (_, _) => _pulse?.Stop();
    }

    public string WidgetId { get; }
    public WidgetSpan Span { get; private set; } = new(2, 1);

    public event Action<WidgetCard>? HideRequested;
    public event Action<WidgetCard>? SizeRequested;
    public event Action<WidgetCard, int>? MoveRequested;

    // ------------------------------------------------------------------ construção

    private static LinearGradientBrush VerticalGradient(Color top, Color bottom) => new()
    {
        StartPoint = new Windows.Foundation.Point(0, 0),
        EndPoint = new Windows.Foundation.Point(0, 1),
        GradientStops =
        {
            new GradientStop { Color = top, Offset = 0 },
            new GradientStop { Color = bottom, Offset = 1 },
        },
    };

    private void BuildChrome()
    {
        _frame.Background = _surfaceBrush;
        _frame.BorderBrush = _defaultBorderBrush;

        var root = new Grid { RowSpacing = 8 };
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var header = new Grid { ColumnSpacing = 8, MinHeight = 28 };
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        _icon.VerticalAlignment = VerticalAlignment.Center;
        _icon.Foreground = (Brush)Application.Current.Resources["TextSecondaryBrush"];
        _title.Foreground = (Brush)Application.Current.Resources["TextPrimaryBrush"];
        header.Children.Add(_icon);
        Grid.SetColumn(_title, 1);
        header.Children.Add(_title);

        var right = new Grid { VerticalAlignment = VerticalAlignment.Center };
        Grid.SetColumn(right, 2);
        _actionButton.Style = (Style)Application.Current.Resources["TextLinkButtonStyle"];
        _actionButton.MinHeight = 28;
        _actionButton.Height = 28;
        _actionButton.Padding = new Thickness(8, 0, 8, 0);
        _actionButton.FontSize = 12;
        _actionButton.Foreground = (Brush)Application.Current.Resources["PurpleLightBrush"];
        _actionButton.CornerRadius = new CornerRadius(8);
        _actionButton.Visibility = Visibility.Collapsed;
        right.Children.Add(_actionButton);

        _editBar.Children.Add(IconButton("", Strings.Tr("Mover para trás"), () => MoveRequested?.Invoke(this, -1)));
        _editBar.Children.Add(IconButton("", Strings.Tr("Mover para frente"), () => MoveRequested?.Invoke(this, 1)));
        _sizeButton.Style = (Style)Application.Current.Resources["SecondaryButtonStyle"];
        _sizeButton.Height = 28;
        _sizeButton.MinHeight = 28;
        _sizeButton.Padding = new Thickness(10, 0, 10, 0);
        _sizeButton.FontSize = 12;
        _sizeButton.CornerRadius = new CornerRadius(8);
        _sizeButton.Click += (_, _) => SizeRequested?.Invoke(this);
        AutomationProperties.SetName(_sizeButton, Strings.Tr("Alterar tamanho"));
        ToolTipService.SetToolTip(_sizeButton, Strings.Tr("Alterar tamanho"));
        _editBar.Children.Add(_sizeButton);
        _editBar.Children.Add(IconButton("", Strings.Tr("Ocultar widget"), () => HideRequested?.Invoke(this)));
        header.Children.Add(right);
        root.Children.Add(header);

        Grid.SetRow(_bodyHost, 1);
        _bodyHost.Children.Add(_skeleton);
        root.Children.Add(_bodyHost);

        _caption.Foreground = (Brush)Application.Current.Resources["TextTertiaryBrush"];
        Grid.SetRow(_caption, 2);
        root.Children.Add(_caption);

        _staleChip.Background = new SolidColorBrush(Color.FromArgb(0x33, 0xF5, 0x9E, 0x0B));
        _staleChip.CornerRadius = new CornerRadius(6);
        _staleChip.Padding = new Thickness(8, 2, 8, 2);
        _staleChip.HorizontalAlignment = HorizontalAlignment.Right;
        _staleChip.VerticalAlignment = VerticalAlignment.Top;
        _staleChip.IsHitTestVisible = false;
        _staleChip.Visibility = Visibility.Collapsed;
        _staleChip.Child = new TextBlock { Text = Strings.Tr("DESATUALIZADO"), FontFamily = (FontFamily)Application.Current.Resources["TechnicalFont"], FontSize = 11, FontWeight = Microsoft.UI.Text.FontWeights.Normal, CharacterSpacing = 60, Foreground = new SolidColorBrush(Color.FromArgb(255, 0xF5, 0x9E, 0x0B)) };
        Grid.SetRow(_staleChip, 1);

        GlowEffect.AttachShadow(_shadowCaster, Color.FromArgb(0x98, 0, 0, 0), blur: 20f, offsetY: 6f);
        Children.Add(_shadowCaster);
        _frame.Child = root;
        Children.Add(_frame);
        _editOutline.Stroke = (Brush)Application.Current.Resources["PurpleLightBrush"];
        Children.Add(_editOutline);
        // Controles de edição: pílula flutuante sobre a borda superior (acima do contorno), sem tirar espaço do título.
        _editBar.HorizontalAlignment = HorizontalAlignment.Right;
        _editBar.VerticalAlignment = VerticalAlignment.Top;
        _editBar.Margin = new Thickness(0, -16, 10, 0);
        _editBar.Padding = new Thickness(4);
        _editBar.CornerRadius = new CornerRadius(10);
        _editBar.Background = new SolidColorBrush(Color.FromArgb(0xFA, 0x14, 0x18, 0x28));
        Children.Add(_editBar);
        root.Children.Add(_staleChip);
    }

    private static Button IconButton(string glyph, string name, Action click)
    {
        var button = new Button
        {
            Width = 28,
            Height = 28,
            MinHeight = 28,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(8),
            Background = new SolidColorBrush(Color.FromArgb(0xB3, 0x25, 0x2A, 0x36)),
            Content = new FontIcon { Glyph = glyph, FontFamily = new FontFamily("Segoe Fluent Icons"), FontSize = 12, Foreground = (Brush)Application.Current.Resources["TextPrimaryBrush"] },
        };
        AutomationProperties.SetName(button, name);
        ToolTipService.SetToolTip(button, name);
        button.Click += (_, _) => click();
        return button;
    }

    private void BuildSkeleton()
    {
        for (var i = 0; i < 3; i++)
        {
            _skeleton.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            var bar = new Rectangle { Height = i == 0 ? 28 : 12, RadiusX = 6, RadiusY = 6, HorizontalAlignment = HorizontalAlignment.Left, Width = i == 0 ? 96 : i == 1 ? 168 : 128, Fill = new SolidColorBrush(Color.FromArgb(0x24, 255, 255, 255)) };
            Grid.SetRow(bar, i);
            _skeleton.Children.Add(bar);
        }
    }

    // ------------------------------------------------------------------ conteúdo

    /// <summary>Aplica o conteúdo mais recente; só troca o que mudou de fato.</summary>
    public void Apply(IHomeWidget widget, WidgetContent content, WidgetSpan span)
    {
        var changedLayout = _applied && (span != Span || content.State != _lastState);
        _applied = true;
        _lastState = content.State;
        Span = span;
        _title.Text = Strings.Tr(widget.Title);
        _icon.Data = widget.IconPath;
        _sizeButton.Content = span.ToString().Replace('x', '×');
        _activate = content.Activate;

        // Corpo e estados
        for (var i = _bodyHost.Children.Count - 1; i >= 0; i--)
            if (!ReferenceEquals(_bodyHost.Children[i], _skeleton)) _bodyHost.Children.RemoveAt(i);

        var showSkeleton = content.State == WidgetState.Loading;
        _skeleton.Visibility = showSkeleton ? Visibility.Visible : Visibility.Collapsed;
        SetPulse(showSkeleton);
        _staleChip.Visibility = content.State == WidgetState.Stale ? Visibility.Visible : Visibility.Collapsed;

        UIElement? body = content.State switch
        {
            WidgetState.Ready or WidgetState.Stale => content.Body,
            WidgetState.Empty or WidgetState.Error => BuildMessage(content),
            _ => null,
        };
        if (body is not null)
        {
            if (body is FrameworkElement element) element.Opacity = content.State == WidgetState.Stale ? 0.65 : 1;
            _bodyHost.Children.Add(body);
        }

        // Cabeçalho: ação (fora da edição) e acento
        if (content.Action is { } action)
        {
            _actionButton.Content = BuildActionContent(action);
            _actionButton.Visibility = _editing ? Visibility.Collapsed : Visibility.Visible;
            _actionButton.Tag = action;
            _actionButton.Click -= OnActionClick;
            _actionButton.Click += OnActionClick;
            AutomationProperties.SetName(_actionButton, action.Label);
        }
        else
        {
            _actionButton.Visibility = Visibility.Collapsed;
            _actionButton.Tag = null;
        }

        // Rodapé: em cartões de uma linha não há espaço, o texto vira dica
        var caption = content.State is WidgetState.Ready or WidgetState.Stale ? content.Caption : null;
        _caption.Text = caption ?? string.Empty;
        _caption.Visibility = !string.IsNullOrWhiteSpace(caption) && span.Rows > 1 ? Visibility.Visible : Visibility.Collapsed;
        ToolTipService.SetToolTip(this, string.IsNullOrWhiteSpace(caption) || span.Rows > 1 ? null : caption);

        _frame.BorderBrush = content.Accent is SolidColorBrush accent && content.State == WidgetState.Ready
            ? new SolidColorBrush(Color.FromArgb(0x66, accent.Color.R, accent.Color.G, accent.Color.B))
            : _defaultBorderBrush;

        var summary = content.Summary ?? content.Message ?? string.Empty;
        AutomationProperties.SetName(this, string.IsNullOrWhiteSpace(summary) ? _title.Text : $"{_title.Text}: {summary}");
        UpdateInteractivity();
        // Mudou de tamanho ou de estado (carregando -> pronto): o conteúdo reaparece com suavidade, não troca seco.
        if (changedLayout) Choreo.FadeSlideIn(_bodyHost, Choreo.Base, 8);
    }

    private bool _applied;
    private WidgetState _lastState;

    private static UIElement BuildActionContent(WidgetAction action)
    {
        var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        if (!string.IsNullOrEmpty(action.IconGlyph))
            row.Children.Add(new FontIcon { Glyph = action.IconGlyph, FontFamily = new FontFamily("Segoe Fluent Icons"), FontSize = 12, VerticalAlignment = VerticalAlignment.Center });
        row.Children.Add(new TextBlock { Text = Strings.Tr(action.Label), FontFamily = (FontFamily)Application.Current.Resources["BodySemiBoldFont"], FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.Normal, VerticalAlignment = VerticalAlignment.Center });
        return row;
    }

    private static UIElement BuildMessage(WidgetContent content)
    {
        var panel = new StackPanel { Spacing = 10, VerticalAlignment = VerticalAlignment.Center };
        panel.Children.Add(new TextBlock
        {
            Text = Strings.Tr(content.Message ?? string.Empty),
            FontSize = 13,
            LineHeight = 18,
            TextWrapping = TextWrapping.Wrap,
            MaxLines = 3,
            TextTrimming = TextTrimming.CharacterEllipsis,
            Foreground = (Brush)Application.Current.Resources["TextSecondaryBrush"],
        });
        return panel;
    }

    private void OnActionClick(object sender, RoutedEventArgs e)
    {
        if (_actionButton.Tag is WidgetAction action) action.Invoke();
    }

    private void SetPulse(bool on)
    {
        _pulse?.Stop();
        _pulse = null;
        _skeleton.Opacity = 1;
        if (!on || Motion.Reduced) return;
        var animation = new DoubleAnimation { From = 0.45, To = 1, Duration = TimeSpan.FromMilliseconds(900), AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever, EasingFunction = new SineEase() };
        Storyboard.SetTarget(animation, _skeleton);
        Storyboard.SetTargetProperty(animation, "Opacity");
        _pulse = new Storyboard();
        _pulse.Children.Add(animation);
        _pulse.Begin();
    }

    // ------------------------------------------------------------------ interação

    private bool Clickable => !_editing && _activate is not null;

    private void UpdateInteractivity()
    {
        IsTabStop = Clickable;
        UseSystemFocusVisuals = Clickable;
        _bodyHost.IsHitTestVisible = !_editing;
        CanDrag = _editing;
        if (!Clickable && _hovered) SetHover(false);
    }

    private void SetHover(bool hover)
    {
        _hovered = hover;
        var lit = hover && Clickable;
        _frame.Background = lit ? _surfaceHoverBrush : _surfaceBrush;
        if (_editing) return;
        Fluid.Hover(this, lit, 1.02f, -3f);
    }

    private void OnTapped(object sender, TappedRoutedEventArgs e)
    {
        if (!Clickable) return;
        // Botões dentro do corpo (miniaturas, capas, ação do cabeçalho) têm a própria ação.
        for (var node = e.OriginalSource as DependencyObject; node is not null && !ReferenceEquals(node, this); node = VisualTreeHelper.GetParent(node))
            if (node is Microsoft.UI.Xaml.Controls.Primitives.ButtonBase) return;
        _activate?.Invoke();
    }

    private void OnKeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (!Clickable || !ReferenceEquals(e.OriginalSource, this)) return;
        if (e.Key is Windows.System.VirtualKey.Enter or Windows.System.VirtualKey.Space)
        {
            e.Handled = true;
            _activate?.Invoke();
        }
    }

    // ------------------------------------------------------------------ edição

    public bool IsEditing
    {
        get => _editing;
        set
        {
            if (_editing == value) return;
            _editing = value;
            _editBar.Visibility = value ? Visibility.Visible : Visibility.Collapsed;
            _actionButton.Visibility = value || _actionButton.Tag is null ? Visibility.Collapsed : Visibility.Visible;
            Choreo.FadeTo(_editOutline, value ? 1 : 0);
            if (value) { Fluid.Hover(this, false); _frame.Background = _surfaceBrush; }
            UpdateInteractivity();
        }
    }
}
