using System;
using System.Numerics;
using Microsoft.UI.Xaml;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Movimento de composição para cards e botões: o Windows interpola escala, deslocamento e opacidade
/// na GPU, então a passada do mouse acompanha o ponteiro sem engasgar.
/// </summary>
public static class Fluid
{
    private static readonly TimeSpan Duration = TimeSpan.FromMilliseconds(240);

    /// <summary>Liga as transições implícitas. Depois disso, mudar Scale/Translation/Opacity anima sozinho.</summary>
    public static void Prepare(UIElement element)
    {
        element.ScaleTransition = new Vector3Transition { Duration = Duration };
        element.TranslationTransition = new Vector3Transition { Duration = Duration };
        element.OpacityTransition = new ScalarTransition { Duration = Duration };
        if (element is FrameworkElement frame)
        {
            frame.SizeChanged -= OnSizeChanged;
            frame.SizeChanged += OnSizeChanged;
            element.CenterPoint = new Vector3((float)frame.ActualWidth / 2, (float)frame.ActualHeight / 2, 0);
        }
    }

    private static void OnSizeChanged(object sender, SizeChangedEventArgs e)
    {
        if (sender is UIElement element) element.CenterPoint = new Vector3((float)e.NewSize.Width / 2, (float)e.NewSize.Height / 2, 0);
    }

    /// <summary>Estado de passagem do mouse: o card sobe um pouco e cresce de leve.</summary>
    public static void Hover(UIElement element, bool hovering, float scale = 1.035f, float lift = -6f)
    {
        if (Motion.Reduced)
        {
            element.Scale = Vector3.One;
            element.Translation = Vector3.Zero;
            return;
        }
        element.Scale = hovering ? new Vector3(scale, scale, 1) : Vector3.One;
        element.Translation = hovering ? new Vector3(0, lift, 0) : Vector3.Zero;
    }

    /// <summary>Estado de pressão: o card afunda um pouco e volta ao soltar.</summary>
    public static void Press(UIElement element, bool pressed, float hoverScale = 1.035f)
    {
        if (Motion.Reduced) return;
        var scale = pressed ? 0.985f : hoverScale;
        element.Scale = new Vector3(scale, scale, 1);
    }
}
