using Windows.UI.ViewManagement;

namespace LagCheck.WinUI.Controls;

/// <summary>Honra a preferência local ("Reduzir movimento") e a configuração de animações do Windows.</summary>
/// <remarks>
/// Só leitura de estado: nada aqui altera transições já aplicadas. Antes, a duração de uma ScalarTransition
/// compartilhada por todos os botões era trocada para zero em tempo de execução; animação de composição com
/// duração zero é inválida e derrubava o app no PointerEntered (falha nativa em StartSingleAnimation).
/// </remarks>
public static class Motion
{
    // Até os ajustes chegarem do motor, vale o que o Windows diz (não "reduzido" por padrão).
    private static bool _reduced;
    private static readonly UISettings SystemSettings = new();

    public static bool Reduced
    {
        get => _reduced || !SystemSettings.AnimationsEnabled;
        set => _reduced = value;
    }
}
