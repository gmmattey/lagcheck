using System.Runtime.CompilerServices;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Coreografia única do app. Toda animação passa por aqui para ter a MESMA linguagem:
/// durações padronizadas, desaceleração suave e saída mais curta que a entrada.
/// </summary>
/// <remarks>
/// Usa só Storyboards clássicos (Opacity + CompositeTransform), que o XAML anima de forma independente
/// na GPU. NÃO usar ElementCompositionPreview.GetElementVisual nem transições implícitas
/// (OpacityTransition/ScaleTransition/TranslationTransition): misturar esses mecanismos derrubava o app
/// com acesso inválido dentro do Microsoft.UI.Xaml.dll ao clicar em botões (ex.: "Testar conexão").
/// Com "Reduzir movimento" as durações viram zero (Storyboard com duração zero é válido).
/// </remarks>
public static class Choreo
{
    /// <summary>Microinteração (hover, foco, pressionar).</summary>
    public const int Fast = 180;
    /// <summary>Entrada de elemento, troca de conteúdo, reposicionamento.</summary>
    public const int Base = 320;
    /// <summary>Troca de tela e eventos de destaque.</summary>
    public const int Slow = 480;
    /// <summary>Saída: sempre mais curta que a entrada.</summary>
    public const int Exit = 140;

    private static EasingFunctionBase Decelerate => new ExponentialEase { EasingMode = EasingMode.EaseOut, Exponent = 5 };
    private static EasingFunctionBase Standard => new CubicEase { EasingMode = EasingMode.EaseOut };
    private static EasingFunctionBase Accelerate => new CubicEase { EasingMode = EasingMode.EaseIn };

    // Storyboard vigente por canal ("o" = opacidade, "t" = transformação) de cada elemento. Mantém vivo o
    // que segura o valor final e deixa o anterior ser coletado quando todos os seus canais forem substituídos.
    private static readonly ConditionalWeakTable<UIElement, Dictionary<string, Storyboard>> Running = new();

    private static CompositeTransform Transform(UIElement element)
    {
        if (element.RenderTransform is CompositeTransform existing) return existing;
        var transform = new CompositeTransform();
        element.RenderTransform = transform;
        element.RenderTransformOrigin = new Windows.Foundation.Point(0.5, 0.5);
        return transform;
    }

    private static int Effective(int ms) => Motion.Reduced ? 0 : ms;

    private static DoubleAnimationUsingKeyFrames Track(DependencyObject target, string property, double? from, double to, int ms, int delayMs, EasingFunctionBase ease)
    {
        var animation = new DoubleAnimationUsingKeyFrames();
        if (from is { } start)
        {
            animation.KeyFrames.Add(new DiscreteDoubleKeyFrame { KeyTime = KeyTime.FromTimeSpan(TimeSpan.Zero), Value = start });
            if (delayMs > 0) animation.KeyFrames.Add(new DiscreteDoubleKeyFrame { KeyTime = KeyTime.FromTimeSpan(TimeSpan.FromMilliseconds(delayMs)), Value = start });
        }
        animation.KeyFrames.Add(new EasingDoubleKeyFrame { KeyTime = KeyTime.FromTimeSpan(TimeSpan.FromMilliseconds(delayMs + ms)), Value = to, EasingFunction = ease });
        Storyboard.SetTarget(animation, target);
        Storyboard.SetTargetProperty(animation, property);
        return animation;
    }

    private static void Begin(UIElement element, Storyboard storyboard, Action? done = null)
    {
        var channels = Running.GetOrCreateValue(element);
        foreach (var child in storyboard.Children)
            channels[Storyboard.GetTargetProperty(child) == "Opacity" ? "o" : "t"] = storyboard;
        if (done is not null) storyboard.Completed += (_, _) => done();
        storyboard.Begin();
    }

    private static void StopAll(UIElement element)
    {
        if (!Running.TryGetValue(element, out var channels)) return;
        foreach (var storyboard in channels.Values.Distinct().ToList()) storyboard.Stop();
        channels.Clear();
    }

    /// <summary>Aparece subindo de <paramref name="dy"/> px (e opcionalmente com atraso, para escalonar listas).</summary>
    public static void FadeSlideIn(UIElement element, int ms = Base, float dy = 16, float dx = 0, int delayMs = 0)
    {
        var transform = Transform(element);
        ms = Effective(ms);
        if (Motion.Reduced) delayMs = 0;
        var storyboard = new Storyboard();
        storyboard.Children.Add(Track(element, "Opacity", 0, 1, ms, delayMs, Decelerate));
        storyboard.Children.Add(Track(transform, "TranslateY", dy, 0, ms, delayMs, Decelerate));
        storyboard.Children.Add(Track(transform, "TranslateX", dx, 0, ms, delayMs, Decelerate));
        Begin(element, storyboard);
    }

    /// <summary>Some com um fade curto; <paramref name="done"/> roda ao terminar (ex.: esconder o elemento).</summary>
    public static void FadeOut(UIElement element, int ms = Exit, float dy = 0, Action? done = null)
    {
        var transform = Transform(element);
        ms = Effective(ms);
        var storyboard = new Storyboard();
        storyboard.Children.Add(Track(element, "Opacity", null, 0, ms, 0, Accelerate));
        if (Math.Abs(dy) > 0.01f) storyboard.Children.Add(Track(transform, "TranslateY", null, dy, ms, 0, Accelerate));
        Begin(element, storyboard, done);
    }

    /// <summary>Estado final de visibilidade, sem animação (reaproveita o elemento depois de um FadeOut).</summary>
    public static void Reset(UIElement element)
    {
        StopAll(element);
        var transform = Transform(element);
        element.Opacity = 1;
        transform.TranslateX = transform.TranslateY = 0;
        transform.ScaleX = transform.ScaleY = 1;
    }

    /// <summary>
    /// Animação de pose (escala + deslocamento): hover, foco, selecionado. Parte do valor atual,
    /// então nunca "salta" se o ponteiro entra e sai rápido.
    /// </summary>
    public static void Pose(UIElement element, float scale, float translateY, float translateX = 0, int ms = Fast)
    {
        var transform = Transform(element);
        ms = Effective(ms);
        var storyboard = new Storyboard();
        storyboard.Children.Add(Track(transform, "ScaleX", null, scale, ms, 0, Standard));
        storyboard.Children.Add(Track(transform, "ScaleY", null, scale, ms, 0, Standard));
        storyboard.Children.Add(Track(transform, "TranslateY", null, translateY, ms, 0, Standard));
        storyboard.Children.Add(Track(transform, "TranslateX", null, translateX, ms, 0, Standard));
        Begin(element, storyboard);
    }

    /// <summary>Escala em torno do centro do elemento (mantido por compatibilidade; o centro é relativo).</summary>
    public static void Center(UIElement element, double width, double height) => Transform(element);

    /// <summary>
    /// Reposicionamento (FLIP): o elemento JÁ está no lugar novo; começa visualmente no lugar antigo
    /// (<paramref name="fromDx"/>, <paramref name="fromDy"/>) e desliza até o novo.
    /// </summary>
    public static void SlideFrom(UIElement element, float fromDx, float fromDy, int ms = Base)
    {
        var transform = Transform(element);
        ms = Effective(ms);
        var storyboard = new Storyboard();
        storyboard.Children.Add(Track(transform, "TranslateX", fromDx, 0, ms, 0, Standard));
        storyboard.Children.Add(Track(transform, "TranslateY", fromDy, 0, ms, 0, Standard));
        Begin(element, storyboard);
    }

    /// <summary>Pulso curto de opacidade (troca de conteúdo no mesmo lugar): cai a <paramref name="from"/> e volta a 1.</summary>
    public static void Refresh(UIElement element, float from = 0.35f, int ms = Base)
    {
        ms = Effective(ms);
        var storyboard = new Storyboard();
        storyboard.Children.Add(Track(element, "Opacity", from, 1, ms, 0, Decelerate));
        Begin(element, storyboard);
    }

    /// <summary>Leva a opacidade a <paramref name="to"/> a partir do valor atual (hover, anéis, destaques).</summary>
    public static void FadeTo(UIElement element, double to, int ms = Fast)
    {
        ms = Effective(ms);
        var storyboard = new Storyboard();
        storyboard.Children.Add(Track(element, "Opacity", null, to, ms, 0, Standard));
        Begin(element, storyboard);
    }
}
