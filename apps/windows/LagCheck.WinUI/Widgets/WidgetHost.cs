using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Localization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using Windows.Foundation;
using Windows.UI;

namespace LagCheck.WinUI.Widgets;

/// <summary>
/// Painel da grade: usa <see cref="WidgetPacker"/> para posicionar os cards, ajusta o número de colunas à
/// largura disponível e anima (FLIP) qualquer card que mude de lugar ou de tamanho.
/// </summary>
public sealed class WidgetGridPanel : Panel
{
    public const double CellWidth = 112;
    public const double CellHeight = 128;
    public const double Gap = 12;
    public const int MaxColumns = 8;

    private IReadOnlyList<WidgetPlacement> _placements = Array.Empty<WidgetPlacement>();
    private int _columns = 2;
    private readonly Dictionary<UIElement, Rect> _previous = new();

    public int Columns => _columns;

    private static double SpanWidth(int cols) => cols * CellWidth + (cols - 1) * Gap;
    private static double SpanHeight(int rows) => rows * CellHeight + (rows - 1) * Gap;

    protected override Size MeasureOverride(Size availableSize)
    {
        var width = double.IsInfinity(availableSize.Width) ? SpanWidth(6) : availableSize.Width;
        _columns = Math.Clamp((int)Math.Floor((width + Gap) / (CellWidth + Gap)), 2, MaxColumns);

        var cards = Children.OfType<WidgetCard>().ToList();
        _placements = WidgetPacker.Pack(cards.Select(card => (card.WidgetId, card.Span)).ToList(), _columns, out var rows);
        foreach (var card in cards)
        {
            var place = _placements.First(item => item.Id == card.WidgetId);
            card.Measure(new Size(SpanWidth(place.Cols), SpanHeight(place.Rows)));
        }
        var usedColumns = _placements.Count == 0 ? 0 : _placements.Max(item => item.Col + item.Cols);
        return new Size(usedColumns == 0 ? 0 : SpanWidth(usedColumns), rows == 0 ? 0 : SpanHeight(rows));
    }

    protected override Size ArrangeOverride(Size finalSize)
    {
        foreach (var card in Children.OfType<WidgetCard>())
        {
            var place = _placements.FirstOrDefault(item => item.Id == card.WidgetId);
            if (place.Id is null) continue;
            var rect = new Rect(place.Col * (CellWidth + Gap), place.Row * (CellHeight + Gap), SpanWidth(place.Cols), SpanHeight(place.Rows));
            card.Arrange(rect);
            Animate(card, rect);
        }
        return finalSize;
    }

    /// <summary>FLIP: o card já está no lugar novo; aplica o deslocamento antigo e deixa a transição devolver a zero.</summary>
    private void Animate(WidgetCard card, Rect rect)
    {
        var hadPrevious = _previous.TryGetValue(card, out var old);
        _previous[card] = rect;
        if (!hadPrevious || Motion.Reduced) return;
        var dx = (float)(old.X - rect.X);
        var dy = (float)(old.Y - rect.Y);
        if (Math.Abs(dx) < 1 && Math.Abs(dy) < 1) return;
        Choreo.SlideFrom(card, dx, dy, Choreo.Base);
    }

    /// <summary>Card sob o ponto (coordenadas do painel), para soltar um arrasto.</summary>
    public WidgetCard? CardAt(Point point)
    {
        foreach (var card in Children.OfType<WidgetCard>())
        {
            var place = _placements.FirstOrDefault(item => item.Id == card.WidgetId);
            if (place.Id is null) continue;
            var rect = new Rect(place.Col * (CellWidth + Gap), place.Row * (CellHeight + Gap), SpanWidth(place.Cols), SpanHeight(place.Rows));
            if (rect.Contains(point)) return card;
        }
        return null;
    }

    public void Forget(UIElement card) => _previous.Remove(card);
}

/// <summary>
/// Módulo de widgets da Início: lê o registro, aplica a preferência do usuário (ordem, tamanho,
/// visibilidade), cria/reaproveita os cards e oferece o modo "Personalizar" (arrastar, redimensionar,
/// ocultar, mostrar todos, ocultar todos, restaurar).
/// </summary>
public sealed class WidgetHost : Grid
{
    private readonly IReadOnlyList<IHomeWidget> _widgets;
    private readonly IReadOnlyList<string> _defaultOrder;
    private readonly WidgetPrefsStore _store;
    private readonly WidgetPrefs _prefs;
    private readonly Dictionary<string, WidgetCard> _cards = new(StringComparer.Ordinal);
    private readonly WidgetGridPanel _panel = new() { AllowDrop = true };
    private readonly StackPanel _toolbar = new() { Orientation = Orientation.Horizontal, Spacing = 8, HorizontalAlignment = HorizontalAlignment.Right };
    private readonly TextBlock _hint = new() { FontSize = 12, VerticalAlignment = VerticalAlignment.Center, TextWrapping = TextWrapping.Wrap };
    private readonly Border _hintPill = new() { CornerRadius = new CornerRadius(17), Padding = new Thickness(14, 8, 14, 8), Background = new SolidColorBrush(Color.FromArgb(0xD9, 0x0B, 0x0D, 0x12)), HorizontalAlignment = HorizontalAlignment.Left, MaxWidth = 380, Visibility = Visibility.Collapsed };
    private readonly WrapPanel _hiddenChips = new() { Spacing = 8, Visibility = Visibility.Collapsed };
    private WidgetContext? _context;
    private bool _editing;

    public WidgetHost() : this(null, null) { }

    public WidgetHost(WidgetPrefsStore? store, IReadOnlyList<IHomeWidget>? widgets)
    {
        _widgets = widgets ?? WidgetRegistry.All;
        _defaultOrder = _widgets.Select(widget => widget.Id).ToList();
        _store = store ?? new WidgetPrefsStore();
        _prefs = _store.Load();

        RowSpacing = 10;
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var bar = new Grid { ColumnSpacing = 12 };
        bar.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bar.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        _hint.Foreground = (Brush)Application.Current.Resources["TextPrimaryBrush"];
        _hintPill.Child = _hint;
        bar.Children.Add(_hintPill);
        Microsoft.UI.Xaml.Controls.Grid.SetColumn(_toolbar, 1);
        bar.Children.Add(_toolbar);
        Children.Add(bar);

        Microsoft.UI.Xaml.Controls.Grid.SetRow(_hiddenChips, 1);
        Children.Add(_hiddenChips);

        Microsoft.UI.Xaml.Controls.Grid.SetRow(_panel, 2);
        _panel.HorizontalAlignment = HorizontalAlignment.Right;
        Children.Add(_panel);

        _panel.DragOver += (_, e) =>
        {
            if (!_editing) return;
            e.AcceptedOperation = Windows.ApplicationModel.DataTransfer.DataPackageOperation.Move;
            e.DragUIOverride.IsGlyphVisible = false;
        };
        _panel.Drop += OnDrop;
        RebuildToolbar();
    }

    /// <summary>Alinhamento da grade dentro do host (à direita no desktop largo, à esquerda quando desce para baixo do hero).</summary>
    public void SetGridAlignment(HorizontalAlignment alignment)
    {
        _panel.HorizontalAlignment = alignment;
        _toolbar.HorizontalAlignment = alignment == HorizontalAlignment.Left ? HorizontalAlignment.Left : HorizontalAlignment.Right;
    }

    public bool IsEditing
    {
        get => _editing;
        set
        {
            if (_editing == value) return;
            _editing = value;
            foreach (var card in _cards.Values) card.IsEditing = value;
            RebuildToolbar();
            Refresh();
        }
    }

    /// <summary>Atualiza o contexto (jogo, histórico, plataformas...) e redesenha só o que mudou.</summary>
    public void Update(WidgetContext context)
    {
        _context = context;
        Refresh();
    }

    // ------------------------------------------------------------------ montagem

    private IReadOnlyList<IHomeWidget> AvailableOrdered()
    {
        if (_context is null) return Array.Empty<IHomeWidget>();
        var byId = _widgets.ToDictionary(widget => widget.Id, StringComparer.Ordinal);
        return _prefs.Ordered(_defaultOrder).Select(id => byId[id]).Where(widget => widget.IsAvailable(_context)).ToList();
    }

    private void Refresh()
    {
        if (_context is null) return;
        var available = AvailableOrdered();
        var visible = available.Where(widget => !_prefs.IsHidden(widget.Id)).ToList();

        // Remove cards que saíram
        foreach (var id in _cards.Keys.Where(id => visible.All(widget => widget.Id != id)).ToList())
        {
            _panel.Children.Remove(_cards[id]);
            _panel.Forget(_cards[id]);
            _cards.Remove(id);
        }

        var order = new List<WidgetCard>();
        var newCards = new List<WidgetCard>();
        foreach (var widget in visible)
        {
            var sizes = widget.Sizes(_context);
            var span = _prefs.ResolveSpan(widget.Id, sizes);
            if (!_cards.TryGetValue(widget.Id, out var card))
            {
                card = CreateCard(widget);
                _cards[widget.Id] = card;
                newCards.Add(card);
            }
            card.IsEditing = _editing;
            card.Apply(widget, SafeRender(widget, span), span);
            order.Add(card);
        }

        // Ordem dos filhos = ordem da preferência
        var current = _panel.Children.OfType<WidgetCard>().ToList();
        if (!current.SequenceEqual(order))
        {
            foreach (var card in current) _panel.Children.Remove(card);
            foreach (var card in order) _panel.Children.Add(card);
        }
        _panel.InvalidateMeasure();
        // Cards novos entram escalonados (um depois do outro), sem atrasar os que já estavam na tela.
        for (var i = 0; i < newCards.Count; i++) Choreo.FadeSlideIn(newCards[i], Choreo.Base, 14, 0, Math.Min(i, 6) * 55);

        RebuildHiddenChips(available.Where(widget => _prefs.IsHidden(widget.Id)).ToList());
        RebuildToolbar(visible.Count, available.Count);
    }

    private WidgetContent SafeRender(IHomeWidget widget, WidgetSpan span)
    {
        try { return widget.Render(_context!, span); }
        catch
        {
            // Um widget com defeito nunca derruba a Início.
            return new WidgetContent(WidgetState.Error, Message: "Não foi possível carregar este widget.");
        }
    }

    private WidgetCard CreateCard(IHomeWidget widget)
    {
        var card = new WidgetCard(widget.Id);
        card.HideRequested += c => { _prefs.SetHidden(c.WidgetId, true); Save(); };
        card.SizeRequested += c =>
        {
            if (_context is null) return;
            _prefs.CycleSize(c.WidgetId, widget.Sizes(_context));
            Save();
        };
        card.MoveRequested += (c, delta) => MoveBy(c.WidgetId, delta);
        return card;
    }

    // ------------------------------------------------------------------ edição e persistência

    private void Save()
    {
        _store.Save(_prefs);
        Refresh();
    }

    private void MoveBy(string id, int delta)
    {
        var visibleIds = AvailableOrdered().Where(widget => !_prefs.IsHidden(widget.Id)).Select(widget => widget.Id).ToList();
        var index = visibleIds.IndexOf(id);
        var neighbor = index + delta;
        if (index < 0 || neighbor < 0 || neighbor >= visibleIds.Count) return;
        var targetIndex = _prefs.Ordered(_defaultOrder).ToList().IndexOf(visibleIds[neighbor]);
        _prefs.MoveTo(id, targetIndex, _defaultOrder);
        Save();
    }

    private void OnDrop(object sender, DragEventArgs e)
    {
        if (!_editing) return;
        var target = _panel.CardAt(e.GetPosition(_panel));
        e.Handled = true;
        if (target is null) return;
        _ = DropAsync(e, target);
    }

    private async Task DropAsync(DragEventArgs e, WidgetCard target)
    {
        try
        {
            var id = await e.DataView.GetTextAsync();
            if (string.IsNullOrWhiteSpace(id) || id == target.WidgetId) return;
            var targetIndex = _prefs.Ordered(_defaultOrder).ToList().IndexOf(target.WidgetId);
            if (targetIndex < 0) return;
            _prefs.MoveTo(id, targetIndex, _defaultOrder);
            Save();
        }
        catch
        {
            // Arrasto de outro app: ignora.
        }
    }

    private void RebuildHiddenChips(IReadOnlyList<IHomeWidget> hidden)
    {
        _hiddenChips.Children.Clear();
        _hiddenChips.Visibility = _editing && hidden.Count > 0 ? Visibility.Visible : Visibility.Collapsed;
        foreach (var widget in hidden)
        {
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
            row.Children.Add(new FontIcon { Glyph = "", FontFamily = new FontFamily("Segoe Fluent Icons"), FontSize = 12 });
            row.Children.Add(new TextBlock { Text = Strings.Tr(widget.Title), FontFamily = (FontFamily)Application.Current.Resources["BodySemiBoldFont"], FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.Normal, VerticalAlignment = VerticalAlignment.Center });
            var chip = new Button
            {
                Style = (Style)Application.Current.Resources["PillChipButtonStyle"],
                Height = 34,
                Padding = new Thickness(14, 0, 14, 0),
                Content = row,
            };
            AutomationProperties.SetName(chip, Strings.Format("Mostrar {0}", Strings.Tr(widget.Title)));
            var id = widget.Id;
            chip.Click += (_, _) => { _prefs.SetHidden(id, false); Save(); };
            _hiddenChips.Children.Add(chip);
        }
    }

    // ------------------------------------------------------------------ barra

    private void RebuildToolbar(int visibleCount = -1, int availableCount = -1)
    {
        _toolbar.Children.Clear();
        _hintPill.Visibility = _editing ? Visibility.Visible : Visibility.Collapsed;
        _panel.Margin = new Thickness(0, _editing ? 18 : 0, 0, 0);
        _hint.Text = Strings.Tr("Arraste os cards para mover; use os botões para tamanho e visibilidade.");

        if (!_editing)
        {
            var allHidden = visibleCount == 0 && availableCount > 0;
            _toolbar.Children.Add(ToolbarButton(allHidden ? Strings.Tr("Mostrar widgets") : Strings.Tr("Personalizar"), "", () =>
            {
                if (allHidden) { _prefs.ShowAll(); _store.Save(_prefs); }
                else IsEditing = true;
            }, primary: false));
            return;
        }

        _toolbar.Children.Add(ToolbarButton(Strings.Tr("Mostrar todos"), "", () => { _prefs.ShowAll(); Save(); }, false));
        _toolbar.Children.Add(ToolbarButton(Strings.Tr("Ocultar todos"), "", () =>
        {
            _prefs.HideAll(AvailableOrdered().Select(widget => widget.Id));
            Save();
        }, false));
        _toolbar.Children.Add(ToolbarButton(Strings.Tr("Restaurar padrão"), "", () => { _prefs.Reset(); Save(); }, false));
        _toolbar.Children.Add(ToolbarButton(Strings.Tr("Concluído"), "", () => IsEditing = false, true));
    }

    private static Button ToolbarButton(string text, string glyph, Action click, bool primary)
    {
        var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        row.Children.Add(new FontIcon { Glyph = glyph, FontFamily = new FontFamily("Segoe Fluent Icons"), FontSize = 12, VerticalAlignment = VerticalAlignment.Center });
        row.Children.Add(new TextBlock { Text = text, FontFamily = (FontFamily)Application.Current.Resources["BodySemiBoldFont"], FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.Normal, VerticalAlignment = VerticalAlignment.Center });
        var button = new Button
        {
            Height = 34,
            MinHeight = 34,
            Padding = new Thickness(14, 0, 14, 0),
            CornerRadius = new CornerRadius(17),
            Content = row,
            Background = primary ? (Brush)Application.Current.Resources["PurpleBrush"] : new SolidColorBrush(Color.FromArgb(0xB8, 0x14, 0x18, 0x28)),
            Foreground = new SolidColorBrush(Microsoft.UI.Colors.White),
        };
        AutomationProperties.SetName(button, text);
        button.Click += (_, _) => click();
        Fluid.Feedback(button);
        return button;
    }
}
