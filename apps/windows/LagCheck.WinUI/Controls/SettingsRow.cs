using System;
using LagCheck.WinUI.Localization;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Automation.Peers;
using Microsoft.UI.Xaml.Automation.Provider;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Markup;
using Microsoft.UI.Xaml.Media;
using Windows.System;
using Windows.UI;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Linha plana de Ajustes inspirada na interface de configurações do PlayStation 5.
/// Título à esquerda (16px, TextPrimary), descrição embaixo (12-13px TextSecondary),
/// valor e controle à direita com separador fino (#14FFFFFF) e faixa de hover/foco.
/// Clicar ou teclar Enter/Espaço aciona o controle correspondente.
/// </summary>
[ContentProperty(Name = nameof(Control))]
public sealed class SettingsRow : UserControl
{
    private readonly Grid _rootGrid = new();
    private readonly Border _hoverBorder = new();
    private readonly Border _focusBorder = new();
    private readonly Border _separator = new();
    private readonly TextBlock _titleLabel = new();
    private readonly TextBlock _descriptionLabel = new();
    private readonly TextBlock _valueLabel = new();
    private readonly ContentPresenter _controlPresenter = new();

    private ToggleSwitch? _currentToggle;
    private bool _isPointerOver;
    private bool _isFocused;

    private static readonly SolidColorBrush TextPrimaryBrush = new(Color.FromArgb(255, 0xF5, 0xF7, 0xFC)); // #F5F7FC
    private static readonly SolidColorBrush TextSecondaryBrush = new(Color.FromArgb(255, 0x9A, 0xA3, 0xB5)); // #9AA3B5
    private static readonly SolidColorBrush HoverBackgroundBrush = new(Color.FromArgb(0x14, 0xFF, 0xFF, 0xFF)); // #14FFFFFF
    private static readonly SolidColorBrush FocusedBackgroundBrush = new(Color.FromArgb(0x1A, 0xFF, 0xFF, 0xFF));
    private static readonly SolidColorBrush FocusedBorderBrush = new(Color.FromArgb(0x40, 0xC9, 0xC4, 0xE8)); // Foco lilás sutil
    private static readonly SolidColorBrush SeparatorBrush = new(Color.FromArgb(0x14, 0xFF, 0xFF, 0xFF));
    private static readonly SolidColorBrush TransparentBrush = new(Microsoft.UI.Colors.Transparent);

    public event RoutedEventHandler? Activated;
    public event Action? MoveFocusToCategoryRequested;

    public SettingsRow()
    {
        IsTabStop = true;
        UseSystemFocusVisuals = false;
        MinHeight = 64;
        HorizontalAlignment = HorizontalAlignment.Stretch;

        _hoverBorder.CornerRadius = new CornerRadius(6);
        _hoverBorder.Background = HoverBackgroundBrush;
        _hoverBorder.Opacity = 0;
        _hoverBorder.IsHitTestVisible = false;
        _hoverBorder.OpacityTransition = Motion.Reduced ? null : new ScalarTransition { Duration = TimeSpan.FromMilliseconds(180) };

        _focusBorder.CornerRadius = new CornerRadius(6);
        _focusBorder.Background = FocusedBackgroundBrush;
        _focusBorder.BorderBrush = FocusedBorderBrush;
        _focusBorder.BorderThickness = new Thickness(1);
        _focusBorder.Opacity = 0;
        _focusBorder.IsHitTestVisible = false;
        _focusBorder.OpacityTransition = Motion.Reduced ? null : new ScalarTransition { Duration = TimeSpan.FromMilliseconds(180) };

        _separator.Height = 1;
        _separator.Background = SeparatorBrush;
        _separator.VerticalAlignment = VerticalAlignment.Bottom;
        _separator.HorizontalAlignment = HorizontalAlignment.Stretch;

        var contentGrid = new Grid
        {
            Padding = new Thickness(16, 12, 16, 12),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Center
        };
        contentGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        contentGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var textStack = new StackPanel
        {
            VerticalAlignment = VerticalAlignment.Center,
            Spacing = 2
        };

        _titleLabel.FontSize = 16;
        _titleLabel.Foreground = TextPrimaryBrush;
        _titleLabel.FontWeight = FontWeights.Normal;
        _titleLabel.TextWrapping = TextWrapping.Wrap;

        _descriptionLabel.FontSize = 13;
        _descriptionLabel.Foreground = TextSecondaryBrush;
        _descriptionLabel.TextWrapping = TextWrapping.Wrap;
        _descriptionLabel.Visibility = Visibility.Collapsed;

        textStack.Children.Add(_titleLabel);
        textStack.Children.Add(_descriptionLabel);
        Grid.SetColumn(textStack, 0);
        contentGrid.Children.Add(textStack);

        var rightStack = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 12,
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Right
        };

        _valueLabel.FontSize = 14;
        _valueLabel.Foreground = TextSecondaryBrush;
        _valueLabel.VerticalAlignment = VerticalAlignment.Center;
        _valueLabel.HorizontalAlignment = HorizontalAlignment.Right;
        _valueLabel.MinWidth = 96;
        _valueLabel.TextAlignment = TextAlignment.Right;
        _valueLabel.TextWrapping = TextWrapping.NoWrap;
        _valueLabel.Visibility = Visibility.Collapsed;

        _controlPresenter.VerticalAlignment = VerticalAlignment.Center;
        _controlPresenter.HorizontalAlignment = HorizontalAlignment.Right;

        rightStack.Children.Add(_valueLabel);
        rightStack.Children.Add(_controlPresenter);
        Grid.SetColumn(rightStack, 1);
        contentGrid.Children.Add(rightStack);

        _rootGrid.Children.Add(_hoverBorder);
        _rootGrid.Children.Add(_focusBorder);
        _rootGrid.Children.Add(contentGrid);
        _rootGrid.Children.Add(_separator);

        Content = _rootGrid;

        PointerEntered += (_, _) => { _isPointerOver = true; UpdateVisualState(); };
        PointerExited += (_, _) => { _isPointerOver = false; UpdateVisualState(); };
        GotFocus += (_, _) => { _isFocused = true; UpdateVisualState(); };
        LostFocus += (_, _) => { _isFocused = false; UpdateVisualState(); };

        PointerPressed += OnPointerPressed;
        KeyDown += OnKeyDown;
        IsEnabledChanged += (_, _) => OnIsEnabledChanged();

        UpdateVisualState();
    }

    public static readonly DependencyProperty TitleProperty = DependencyProperty.Register(
        nameof(Title), typeof(string), typeof(SettingsRow),
        new PropertyMetadata(string.Empty, (d, e) => ((SettingsRow)d).OnTitleChanged((string)e.NewValue)));

    public static readonly DependencyProperty DescriptionProperty = DependencyProperty.Register(
        nameof(Description), typeof(string), typeof(SettingsRow),
        new PropertyMetadata(string.Empty, (d, e) => ((SettingsRow)d).OnDescriptionChanged((string)e.NewValue)));

    public static readonly DependencyProperty ValueTextProperty = DependencyProperty.Register(
        nameof(ValueText), typeof(string), typeof(SettingsRow),
        new PropertyMetadata(string.Empty, (d, e) => ((SettingsRow)d).OnValueTextChanged((string)e.NewValue)));

    public static readonly DependencyProperty ControlProperty = DependencyProperty.Register(
        nameof(Control), typeof(UIElement), typeof(SettingsRow),
        new PropertyMetadata(null, (d, e) => ((SettingsRow)d).OnControlChanged((UIElement?)e.OldValue, (UIElement?)e.NewValue)));

    public string Title
    {
        get => (string)GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    public string Description
    {
        get => (string)GetValue(DescriptionProperty);
        set => SetValue(DescriptionProperty, value);
    }

    public string ValueText
    {
        get => (string)GetValue(ValueTextProperty);
        set => SetValue(ValueTextProperty, value);
    }

    public UIElement? Control
    {
        get => (UIElement?)GetValue(ControlProperty);
        set => SetValue(ControlProperty, value);
    }

    private void OnTitleChanged(string newTitle)
    {
        _titleLabel.Text = newTitle;
        UpdateAutomationProperties();
    }

    private void OnDescriptionChanged(string newDesc)
    {
        _descriptionLabel.Text = newDesc;
        _descriptionLabel.Visibility = string.IsNullOrWhiteSpace(newDesc) ? Visibility.Collapsed : Visibility.Visible;
    }

    private void OnValueTextChanged(string newValue)
    {
        if (!string.IsNullOrWhiteSpace(newValue))
        {
            _valueLabel.Text = newValue;
            _valueLabel.Visibility = Visibility.Visible;
        }
        else if (_currentToggle != null)
        {
            UpdateToggleValueText(_currentToggle.IsOn);
        }
        else
        {
            _valueLabel.Visibility = Visibility.Collapsed;
        }

        UpdateAutomationProperties();
    }

    private void OnControlChanged(UIElement? oldElement, UIElement? newElement)
    {
        if (_currentToggle != null)
        {
            _currentToggle.Toggled -= OnToggleToggled;
            _currentToggle = null;
        }

        _controlPresenter.Content = newElement;

        if (newElement is ToggleSwitch toggle)
        {
            _currentToggle = toggle;
            toggle.OnContent = string.Empty;
            toggle.OffContent = string.Empty;
            toggle.MinWidth = 0;
            toggle.Toggled += OnToggleToggled;
            UpdateToggleValueText(toggle.IsOn);
        }
        else if (string.IsNullOrWhiteSpace(ValueText))
        {
            _valueLabel.Visibility = Visibility.Collapsed;
        }

        UpdateAutomationProperties();
    }

    private void OnToggleToggled(object sender, RoutedEventArgs e)
    {
        if (sender is ToggleSwitch toggle)
        {
            UpdateToggleValueText(toggle.IsOn);
            UpdateAutomationProperties();
        }
    }

    private void UpdateToggleValueText(bool isOn)
    {
        if (!string.IsNullOrWhiteSpace(ValueText))
        {
            _valueLabel.Text = ValueText;
            _valueLabel.Visibility = Visibility.Visible;
            return;
        }

        _valueLabel.Text = isOn ? Strings.Tr("Ligado") : Strings.Tr("Desligado");
        _valueLabel.Visibility = Visibility.Visible;
    }

    private void UpdateAutomationProperties()
    {
        var val = !string.IsNullOrWhiteSpace(_valueLabel.Text) && _valueLabel.Visibility == Visibility.Visible
            ? _valueLabel.Text
            : null;

        var automationName = string.IsNullOrWhiteSpace(val)
            ? Title
            : $"{Title} - {val}";

        AutomationProperties.SetName(this, automationName);
    }

    private void OnIsEnabledChanged()
    {
        Opacity = IsEnabled ? 1.0 : 0.45;
        if (Control != null)
        {
            if (Control is Microsoft.UI.Xaml.Controls.Control inner) inner.IsEnabled = IsEnabled;
        }
    }

    private void OnPointerPressed(object sender, PointerRoutedEventArgs e)
    {
        if (!IsEnabled) return;

        if (Control != null && IsChildOf(e.OriginalSource as DependencyObject, Control))
        {
            return;
        }

        Focus(FocusState.Pointer);
        Activate();
        e.Handled = true;
    }

    private void OnKeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key is VirtualKey.Enter or VirtualKey.Space)
        {
            if (IsEnabled)
            {
                e.Handled = true;
                Activate();
            }
        }
        else if (e.Key == VirtualKey.Left)
        {
            e.Handled = true;
            MoveFocusToCategoryRequested?.Invoke();
        }
    }

    public void Activate()
    {
        if (!IsEnabled) return;

        Activated?.Invoke(this, new RoutedEventArgs());

        if (Control is ToggleSwitch toggle)
        {
            if (toggle.IsEnabled)
            {
                toggle.IsOn = !toggle.IsOn;
            }
        }
        else if (Control is ComboBox combo)
        {
            if (combo.IsEnabled)
            {
                combo.IsDropDownOpen = !combo.IsDropDownOpen;
                combo.Focus(FocusState.Programmatic);
            }
        }
        else if (Control is Button button)
        {
            if (button.IsEnabled)
            {
                if (FrameworkElementAutomationPeer.CreatePeerForElement(button) is ButtonAutomationPeer peer &&
                    peer.GetPattern(PatternInterface.Invoke) is IInvokeProvider invoker)
                {
                    invoker.Invoke();
                }
            }
        }
    }

    private void UpdateVisualState()
    {
        if (_isFocused)
        {
            _focusBorder.Opacity = 1;
            _hoverBorder.Opacity = 0;
        }
        else if (_isPointerOver)
        {
            _focusBorder.Opacity = 0;
            _hoverBorder.Opacity = 1;
        }
        else
        {
            _focusBorder.Opacity = 0;
            _hoverBorder.Opacity = 0;
        }
    }

    private static bool IsChildOf(DependencyObject? element, DependencyObject parent)
    {
        while (element != null)
        {
            if (ReferenceEquals(element, parent)) return true;
            element = VisualTreeHelper.GetParent(element);
        }
        return false;
    }
}
