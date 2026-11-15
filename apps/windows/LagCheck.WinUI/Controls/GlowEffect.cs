using System.Numerics;
using System.Runtime.CompilerServices;
using Microsoft.UI.Composition;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Hosting;
using Microsoft.UI.Xaml.Shapes;
using Windows.UI;

namespace LagCheck.WinUI.Controls;

/// <summary>Sombra colorida (glow) e sombra de elevação de composição.</summary>
public static class GlowEffect
{
    private sealed class ShadowAttachment
    {
        public DropShadow? Shadow;
        public SpriteVisual? Sprite;
        public bool Built;
    }

    private static readonly ConditionalWeakTable<Rectangle, ShadowAttachment> Attachments = new();

    /// <param name="shape">Retângulo arredondado com o mesmo contorno do botão, posicionado atrás dele.</param>
    public static void Attach(Rectangle shape, Color color, float blur) =>
        AttachShadow(shape, color, blur, offsetY: 0f, offsetX: 0f);

    /// <summary>Anexa uma sombra projetada de elevação ao <paramref name="shape"/> de forma idempotente.</summary>
    public static void AttachShadow(Rectangle shape, Color color, float blur, float offsetY = 6f, float offsetX = 0f)
    {
        if (Attachments.TryGetValue(shape, out var existing))
        {
            if (existing.Shadow is { } s)
            {
                s.Color = color;
                s.BlurRadius = blur;
                s.Offset = new Vector3(offsetX, offsetY, 0f);
            }
            return;
        }

        var attachment = new ShadowAttachment();
        Attachments.Add(shape, attachment);

        void Build()
        {
            if (attachment.Built) return;
            attachment.Built = true;
            var compositor = ElementCompositionPreview.GetElementVisual(shape).Compositor;
            var shadow = compositor.CreateDropShadow();
            shadow.Color = color;
            shadow.BlurRadius = blur;
            shadow.Offset = new Vector3(offsetX, offsetY, 0f);
            shadow.Mask = shape.GetAlphaMask();
            var sprite = compositor.CreateSpriteVisual();
            sprite.Shadow = shadow;
            sprite.Size = new Vector2((float)shape.ActualWidth, (float)shape.ActualHeight);
            ElementCompositionPreview.SetElementChildVisual(shape, sprite);
            attachment.Shadow = shadow;
            attachment.Sprite = sprite;
            shape.SizeChanged += (_, e) =>
            {
                sprite.Size = new Vector2((float)e.NewSize.Width, (float)e.NewSize.Height);
                shadow.Mask = shape.GetAlphaMask();
            };
        }

        if (shape.IsLoaded) Build();
        else shape.Loaded += (_, _) => Build();
    }
}
