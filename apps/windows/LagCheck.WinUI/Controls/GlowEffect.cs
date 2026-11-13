using System.Numerics;
using Microsoft.UI.Composition;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Hosting;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace LagCheck.WinUI.Controls;

/// <summary>Sombra colorida (glow) de composição, usada no botão JOGAR AGORA (0 0 36px rgba(124,58,237,.55)).</summary>
public static class GlowEffect
{
    /// <param name="shape">Retângulo arredondado com o mesmo contorno do botão, posicionado atrás dele.</param>
    public static void Attach(Rectangle shape, Color color, float blur)
    {
        void Build()
        {
            var compositor = ElementCompositionPreview.GetElementVisual(shape).Compositor;
            var shadow = compositor.CreateDropShadow();
            shadow.Color = color;
            shadow.BlurRadius = blur;
            shadow.Mask = shape.GetAlphaMask();
            var sprite = compositor.CreateSpriteVisual();
            sprite.Shadow = shadow;
            sprite.Size = new Vector2((float)shape.ActualWidth, (float)shape.ActualHeight);
            ElementCompositionPreview.SetElementChildVisual(shape, sprite);
            shape.SizeChanged += (_, e) =>
            {
                sprite.Size = new Vector2((float)e.NewSize.Width, (float)e.NewSize.Height);
                shadow.Mask = shape.GetAlphaMask();
            };
        }
        if (shape.IsLoaded) Build(); else shape.Loaded += (_, _) => Build();
    }
}
