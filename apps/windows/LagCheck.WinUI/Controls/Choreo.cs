using System.Numerics;
using Microsoft.UI.Composition;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Hosting;

namespace LagCheck.WinUI.Controls;

/// <summary>
/// Coreografia única do app. Toda animação passa por aqui para ter a MESMA linguagem:
/// durações padronizadas, curva de desaceleração suave (rápido no começo, assenta devagar) e saída
/// mais curta que a entrada. Roda na GPU (Composition), sem refazer layout. Com "Reduzir movimento"
/// (ou animações desligadas no Windows) tudo vai direto ao estado final.
/// </summary>
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

    /// <summary>Desaceleração suave (Material "emphasized decelerate").</summary>
    private static CubicBezierEasingFunction Decelerate(Compositor c) => c.CreateCubicBezierEasingFunction(new Vector2(0.05f, 0.7f), new Vector2(0.1f, 1f));
    /// <summary>Entra e sai com suavidade (reposicionar).</summary>
    private static CubicBezierEasingFunction Standard(Compositor c) => c.CreateCubicBezierEasingFunction(new Vector2(0.2f, 0f), new Vector2(0f, 1f));
    /// <summary>Acelera ao sair (fade-out).</summary>
    private static CubicBezierEasingFunction Accelerate(Compositor c) => c.CreateCubicBezierEasingFunction(new Vector2(0.3f, 0f), new Vector2(0.8f, 0.15f));

    private static Visual Prepare(UIElement element)
    {
        ElementCompositionPreview.SetIsTranslationEnabled(element, true);
        return ElementCompositionPreview.GetElementVisual(element);
    }

    private static TimeSpan Ms(int ms) => TimeSpan.FromMilliseconds(ms);

    /// <summary>Aparece subindo de <paramref name="dy"/> px (e opcionalmente com atraso, para escalonar listas).</summary>
    public static void FadeSlideIn(UIElement element, int ms = Base, float dy = 16, float dx = 0, int delayMs = 0)
    {
        var visual = Prepare(element);
        if (Motion.Reduced)
        {
            visual.Opacity = 1;
            visual.Properties.InsertVector3("Translation", Vector3.Zero);
            return;
        }
        var compositor = visual.Compositor;
        visual.StopAnimation("Opacity");
        visual.StopAnimation("Translation");
        visual.Opacity = 0;
        visual.Properties.InsertVector3("Translation", new Vector3(dx, dy, 0));

        var fade = compositor.CreateScalarKeyFrameAnimation();
        fade.InsertKeyFrame(1f, 1f, Decelerate(compositor));
        fade.Duration = Ms(ms);
        fade.DelayTime = Ms(delayMs);
        fade.DelayBehavior = AnimationDelayBehavior.SetInitialValueBeforeDelay;

        var slide = compositor.CreateVector3KeyFrameAnimation();
        slide.InsertKeyFrame(1f, Vector3.Zero, Decelerate(compositor));
        slide.Duration = Ms(ms);
        slide.DelayTime = Ms(delayMs);
        slide.DelayBehavior = AnimationDelayBehavior.SetInitialValueBeforeDelay;

        visual.StartAnimation("Opacity", fade);
        visual.StartAnimation("Translation", slide);
    }

    /// <summary>Some com um fade curto; <paramref name="done"/> roda ao terminar (ex.: esconder o elemento).</summary>
    public static void FadeOut(UIElement element, int ms = Exit, float dy = 0, Action? done = null)
    {
        var visual = Prepare(element);
        if (Motion.Reduced) { visual.Opacity = 0; done?.Invoke(); return; }
        var compositor = visual.Compositor;
        var batch = compositor.CreateScopedBatch(CompositionBatchTypes.Animation);
        var fade = compositor.CreateScalarKeyFrameAnimation();
        fade.InsertKeyFrame(1f, 0f, Accelerate(compositor));
        fade.Duration = Ms(ms);
        visual.StartAnimation("Opacity", fade);
        if (Math.Abs(dy) > 0.01f)
        {
            var slide = compositor.CreateVector3KeyFrameAnimation();
            slide.InsertKeyFrame(1f, new Vector3(0, dy, 0), Accelerate(compositor));
            slide.Duration = Ms(ms);
            visual.StartAnimation("Translation", slide);
        }
        batch.End();
        if (done is not null) batch.Completed += (_, _) => done();
    }

    /// <summary>Estado final de visibilidade, sem animação (reaproveita o elemento depois de um FadeOut).</summary>
    public static void Reset(UIElement element)
    {
        var visual = Prepare(element);
        visual.StopAnimation("Opacity");
        visual.StopAnimation("Translation");
        visual.StopAnimation("Scale");
        visual.Opacity = 1;
        visual.Properties.InsertVector3("Translation", Vector3.Zero);
        visual.Scale = Vector3.One;
    }

    /// <summary>
    /// Animação de pose (escala + deslocamento): hover, foco, selecionado. Interrompe a anterior e parte do
    /// valor atual, então nunca "salta" se o ponteiro entra e sai rápido.
    /// </summary>
    public static void Pose(UIElement element, float scale, float translateY, float translateX = 0, int ms = Fast)
    {
        var visual = Prepare(element);
        var target = new Vector3(scale, scale, 1);
        var targetT = new Vector3(translateX, translateY, 0);
        if (Motion.Reduced)
        {
            visual.StopAnimation("Scale");
            visual.StopAnimation("Translation");
            visual.Scale = target;
            visual.Properties.InsertVector3("Translation", targetT);
            return;
        }
        var compositor = visual.Compositor;
        var ease = Standard(compositor);
        var scaleAnimation = compositor.CreateVector3KeyFrameAnimation();
        scaleAnimation.InsertKeyFrame(1f, target, ease);
        scaleAnimation.Duration = Ms(ms);
        var moveAnimation = compositor.CreateVector3KeyFrameAnimation();
        moveAnimation.InsertKeyFrame(1f, targetT, ease);
        moveAnimation.Duration = Ms(ms);
        visual.StartAnimation("Scale", scaleAnimation);
        visual.StartAnimation("Translation", moveAnimation);
    }

    /// <summary>Define o ponto de escala (centro) do elemento, para <see cref="Pose"/> girar em torno do meio.</summary>
    public static void Center(UIElement element, double width, double height)
    {
        var visual = Prepare(element);
        visual.CenterPoint = new Vector3((float)width / 2, (float)height / 2, 0);
    }

    /// <summary>
    /// Reposicionamento (FLIP): o elemento JÁ está no lugar novo; começa visualmente no lugar antigo
    /// (<paramref name="fromDx"/>, <paramref name="fromDy"/>) e desliza até o novo.
    /// </summary>
    public static void SlideFrom(UIElement element, float fromDx, float fromDy, int ms = Base)
    {
        var visual = Prepare(element);
        if (Motion.Reduced) { visual.Properties.InsertVector3("Translation", Vector3.Zero); return; }
        var compositor = visual.Compositor;
        visual.StopAnimation("Translation");
        visual.Properties.InsertVector3("Translation", new Vector3(fromDx, fromDy, 0));
        var slide = compositor.CreateVector3KeyFrameAnimation();
        slide.InsertKeyFrame(1f, Vector3.Zero, Standard(compositor));
        slide.Duration = Ms(ms);
        visual.StartAnimation("Translation", slide);
    }

    /// <summary>Pulso curto de opacidade (troca de conteúdo no mesmo lugar): cai a <paramref name="from"/> e volta a 1.</summary>
    public static void Refresh(UIElement element, float from = 0.35f, int ms = Base)
    {
        var visual = Prepare(element);
        if (Motion.Reduced) { visual.Opacity = 1; return; }
        var compositor = visual.Compositor;
        visual.StopAnimation("Opacity");
        visual.Opacity = from;
        var fade = compositor.CreateScalarKeyFrameAnimation();
        fade.InsertKeyFrame(1f, 1f, Decelerate(compositor));
        fade.Duration = Ms(ms);
        visual.StartAnimation("Opacity", fade);
    }
}
