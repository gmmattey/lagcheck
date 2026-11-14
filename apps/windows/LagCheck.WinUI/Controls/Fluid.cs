using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Feedback de cards e botões (hover, foco, pressionar, pose). Tudo passa pelo <see cref="Choreo"/>:
/// mesma curva e duração em todo o app, na GPU, sem salto se o ponteiro entra e sai rápido.
/// </summary>
public static class Fluid
{
    /// <summary>Prepara o elemento: centro de escala acompanha o tamanho.</summary>
    public static void Prepare(UIElement element)
    {
        if (element is FrameworkElement frame)
        {
            frame.SizeChanged -= OnSizeChanged;
            frame.SizeChanged += OnSizeChanged;
            Choreo.Center(element, frame.ActualWidth, frame.ActualHeight);
        }
    }

    private static void OnSizeChanged(object sender, SizeChangedEventArgs e)
    {
        if (sender is UIElement element) Choreo.Center(element, e.NewSize.Width, e.NewSize.Height);
    }

    /// <summary>Feedback padrão de botão (hover sobe de leve, pressionar afunda); o mesmo toque em todas as telas.</summary>
    public static void Feedback(Button button, float scale = 1.015f, float lift = -1f)
    {
        Prepare(button);
        var hovered = false;
        button.PointerEntered += (_, _) => { hovered = true; Hover(button, true, scale, lift); };
        button.PointerExited += (_, _) => { hovered = false; Hover(button, false); };
        button.AddHandler(UIElement.PointerPressedEvent, new Microsoft.UI.Xaml.Input.PointerEventHandler((_, _) => Press(button, true, scale)), true);
        button.AddHandler(UIElement.PointerReleasedEvent, new Microsoft.UI.Xaml.Input.PointerEventHandler((_, _) => Hover(button, hovered, scale, lift)), true);
        button.PointerCanceled += (_, _) => { hovered = false; Hover(button, false); };
    }

    /// <summary>Estado de passagem do mouse: o card sobe um pouco e cresce de leve.</summary>
    public static void Hover(UIElement element, bool hovering, float scale = 1.035f, float lift = -6f) =>
        Choreo.Pose(element, hovering ? scale : 1f, hovering ? lift : 0f);

    /// <summary>Pose fixa (escala + deslocamento vertical), ex.: tile selecionado x em repouso.</summary>
    public static void SetPose(UIElement element, float scale, float translateY) => Choreo.Pose(element, scale, translateY, 0, Choreo.Base);

    /// <summary>Estado de pressão: o card afunda um pouco e volta ao soltar.</summary>
    public static void Press(UIElement element, bool pressed, float hoverScale = 1.035f)
    {
        if (Motion.Reduced) return;
        Choreo.Pose(element, pressed ? 0.985f : hoverScale, 0f, 0, 90);
    }
}
