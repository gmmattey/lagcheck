using System;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Windows.System;
using Windows.UI;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Botão de categoria da barra lateral de Ajustes no estilo PlayStation 5.
/// Estado inativo exibe texto simples em TextSecondary (sobe para TextPrimary no hover/foco);
/// estado ativo/focado tem contorno claro (#C9C4E8, 1.5px, cantos 6px) e fundo quase transparente.
/// </summary>
public sealed class SettingsCategoryButton : UserControl
{
    private readonly Grid _container = new();
    private readonly Border _hoverBorder = new();
    private readonly Border _focusBorder = new();
    private readonly Border _selectedBorder = new();
    private readonly TextBlock _label = new();
    private bool _isPointerOver;
    private bool _isFocused;

    private static readonly SolidColorBrush SelectedBorderBrush = new(Color.FromArgb(255, 0xC9, 0xC4, 0xE8)); // #C9C4E8
    private static readonly SolidColorBrush SelectedBackgroundBrush = new(Color.FromArgb(0x14, 0xFF, 0xFF, 0xFF)); // Quase transparente
    private static readonly SolidColorBrush HoverBackgroundBrush = new(Color.FromArgb(0x0C, 0xFF, 0xFF, 0xFF));
    private static readonly SolidColorBrush FocusedBorderBrush = new(Color.FromArgb(0x80, 0xC9, 0xC4, 0xE8));
    private static readonly SolidColorBrush TransparentBrush = new(Microsoft.UI.Colors.Transparent);

    private static readonly SolidColorBrush TextPrimaryBrush = new(Color.FromArgb(255, 0xF5, 0xF7, 0xFC)); // #F5F7FC
    private static readonly SolidColorBrush TextSecondaryBrush = new(Color.FromArgb(255, 0x9A, 0xA3, 0xB5)); // #9AA3B5

    public event RoutedEventHandler? Selected;
    public event Action? MoveFocusToContentRequested;

    public SettingsCategoryButton()
    {
        IsTabStop = true;
        UseSystemFocusVisuals = false;
        MinHeight = 44;
        HorizontalAlignment = HorizontalAlignment.Stretch;

        _hoverBorder.CornerRadius = new CornerRadius(6);
        _hoverBorder.Background = HoverBackgroundBrush;
        Choreo.FadeTo(_hoverBorder, 0);
        _hoverBorder.IsHitTestVisible = false;

        _focusBorder.CornerRadius = new CornerRadius(6);
        _focusBorder.Background = HoverBackgroundBrush;
        _focusBorder.BorderBrush = FocusedBorderBrush;
        _focusBorder.BorderThickness = new Thickness(1.5);
        Choreo.FadeTo(_focusBorder, 0);
        _focusBorder.IsHitTestVisible = false;

        _selectedBorder.CornerRadius = new CornerRadius(6);
        _selectedBorder.Background = SelectedBackgroundBrush;
        _selectedBorder.BorderBrush = SelectedBorderBrush;
        _selectedBorder.BorderThickness = new Thickness(1.5);
        Choreo.FadeTo(_selectedBorder, 0);
        _selectedBorder.IsHitTestVisible = false;

        _label.FontSize = 15;
        _label.TextTrimming = TextTrimming.CharacterEllipsis;
        _label.VerticalAlignment = VerticalAlignment.Center;
        _label.Margin = new Thickness(16, 10, 16, 10);

        _container.Children.Add(_hoverBorder);
        _container.Children.Add(_focusBorder);
        _container.Children.Add(_selectedBorder);
        _container.Children.Add(_label);
        Content = _container;

        PointerEntered += (_, _) => { _isPointerOver = true; UpdateVisualState(); };
        PointerExited += (_, _) => { _isPointerOver = false; UpdateVisualState(); };
        GotFocus += (_, _) => { _isFocused = true; UpdateVisualState(); };
        LostFocus += (_, _) => { _isFocused = false; UpdateVisualState(); };

        PointerPressed += OnPointerPressed;
        KeyDown += OnKeyDown;

        UpdateVisualState();
    }

    public static readonly DependencyProperty TitleProperty = DependencyProperty.Register(
        nameof(Title), typeof(string), typeof(SettingsCategoryButton),
        new PropertyMetadata(string.Empty, (d, e) => ((SettingsCategoryButton)d).OnTitleChanged((string)e.NewValue)));

    public static readonly DependencyProperty IsSelectedProperty = DependencyProperty.Register(
        nameof(IsSelected), typeof(bool), typeof(SettingsCategoryButton),
        new PropertyMetadata(false, (d, _) => ((SettingsCategoryButton)d).UpdateVisualState()));

    public string Title
    {
        get => (string)GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    public bool IsSelected
    {
        get => (bool)GetValue(IsSelectedProperty);
        set => SetValue(IsSelectedProperty, value);
    }

    private void OnTitleChanged(string newTitle)
    {
        _label.Text = newTitle;
        AutomationProperties.SetName(this, newTitle);
    }

    private void OnPointerPressed(object sender, PointerRoutedEventArgs e)
    {
        e.Handled = true;
        Focus(FocusState.Pointer);
        IsSelected = true;
        Selected?.Invoke(this, new RoutedEventArgs());
    }

    private void OnKeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key is VirtualKey.Enter or VirtualKey.Space)
        {
            e.Handled = true;
            IsSelected = true;
            Selected?.Invoke(this, new RoutedEventArgs());
        }
        else if (e.Key == VirtualKey.Right)
        {
            e.Handled = true;
            MoveFocusToContentRequested?.Invoke();
        }
    }

    private void UpdateVisualState()
    {
        if (IsSelected)
        {
            Choreo.FadeTo(_selectedBorder, 1);
            Choreo.FadeTo(_focusBorder, 0);
            Choreo.FadeTo(_hoverBorder, 0);
            _label.Foreground = TextPrimaryBrush;
            Typography.SemiBold(_label);
        }
        else if (_isFocused)
        {
            Choreo.FadeTo(_selectedBorder, 0);
            Choreo.FadeTo(_focusBorder, 1);
            Choreo.FadeTo(_hoverBorder, 0);
            _label.Foreground = TextPrimaryBrush;
            Typography.SemiBold(_label);
        }
        else if (_isPointerOver)
        {
            Choreo.FadeTo(_selectedBorder, 0);
            Choreo.FadeTo(_focusBorder, 0);
            Choreo.FadeTo(_hoverBorder, 1);
            _label.Foreground = TextPrimaryBrush;
            Typography.Body(_label);
        }
        else
        {
            Choreo.FadeTo(_selectedBorder, 0);
            Choreo.FadeTo(_focusBorder, 0);
            Choreo.FadeTo(_hoverBorder, 0);
            _label.Foreground = TextSecondaryBrush;
            Typography.Body(_label);
        }
    }
}
