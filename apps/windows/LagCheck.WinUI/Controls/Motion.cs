using Windows.UI.ViewManagement;
using Microsoft.UI.Xaml;

namespace LagCheck.WinUI.Controls;

/// <summary>Honra a preferência local e a configuração de animações do Windows.</summary>
public static class Motion
{
    private static bool _reduced = true;
    private static readonly UISettings SystemSettings = new();

    public static bool Reduced
    {
        get
        {
            var reduced = _reduced || !SystemSettings.AnimationsEnabled;
            UpdateInteractionTransition(reduced);
            return reduced;
        }
        set
        {
            _reduced = value;
            UpdateInteractionTransition(_reduced || !SystemSettings.AnimationsEnabled);
        }
    }

    private static void UpdateInteractionTransition(bool reduced)
    {
        if (Application.Current?.Resources is not { } resources) return;
        foreach (var dictionary in resources.MergedDictionaries)
        {
            if (dictionary.TryGetValue("InteractionOpacityTransition", out var value) && value is ScalarTransition transition)
            {
                var duration = reduced ? TimeSpan.Zero : TimeSpan.FromMilliseconds(180);
                if (transition.Duration != duration) transition.Duration = duration;
                break;
            }
        }
    }
}
