using LagCheck.WinUI.History;
using LagCheck.WinUI.Library;
using LagCheck.WinUI.PlatformStatus;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;

namespace LagCheck.WinUI.Widgets;

/// <summary>Estado de apresentação de um widget; o card cuida da aparência de cada um.</summary>
public enum WidgetState
{
    /// <summary>Dado real disponível: mostra <see cref="WidgetContent.Body"/>.</summary>
    Ready,
    /// <summary>Buscando agora: card com esqueleto pulsando.</summary>
    Loading,
    /// <summary>Não há dado ainda: mostra a mensagem e a ação que resolve (ex.: "Fazer o primeiro teste").</summary>
    Empty,
    /// <summary>Dado antigo: mostra o corpo com selo de desatualizado.</summary>
    Stale,
    /// <summary>Falha ao obter: mostra a mensagem e, se houver, a ação de tentar de novo.</summary>
    Error,
}

/// <summary>Ação do cabeçalho do card (link à direita), ex.: "Ver histórico", "Atualizar".</summary>
public sealed record WidgetAction(string Label, Action Invoke, string? IconGlyph = null);

/// <summary>
/// O que um widget quer exibir agora. Records imutáveis: o host compara e só redesenha o que mudou.
/// Use <paramref name="Activate"/> somente quando clicar no card leva ao destino óbvio (ex.: Atividade -> detalhes do jogo);
/// caso contrário, prefira uma ação explícita no cabeçalho (<paramref name="Action"/>).
/// </summary>
public sealed record WidgetContent(
    WidgetState State,
    UIElement? Body = null,
    string? Message = null,
    string? Caption = null,
    WidgetAction? Action = null,
    /// <summary>Ação ao clicar no card inteiro. Usar Activate só quando clicar no card leva ao destino óbvio (ex.: Atividade -> detalhes do jogo); caso contrário, ação explícita no cabeçalho.</summary>
    Action? Activate = null,
    Brush? Accent = null,
    string? Summary = null);

/// <summary>Contexto da Início entregue a cada widget. Nenhum dado aqui é inventado: o que falta vem nulo/vazio.</summary>
public sealed record WidgetContext(
    LibraryGame? Game,
    bool IsPc,
    IReadOnlyList<LibraryGame> Library,
    IReadOnlyList<SessionHistoryEntry> History,
    PlatformStatusSnapshot? Platforms,
    bool PlatformsLoading,
    WidgetActions Actions);

/// <summary>Efeitos que um widget pode pedir à Início (clique, ação do cabeçalho).</summary>
public sealed record WidgetActions(
    Action<LibraryGame> OpenDetails,
    Action<LibraryGame> SelectGame,
    Action OpenHistory,
    Action OpenGallery,
    Action<string?, string?> TestConnection,
    Action RefreshPlatforms,
    Action<string?, string?>? OpenHistoryFiltered = null)
{
    public void NavigateToHistory(string? gameId = null, string? gameTitle = null)
    {
        if (OpenHistoryFiltered is not null) OpenHistoryFiltered(gameId, gameTitle);
        else OpenHistory();
    }
}

/// <summary>
/// Um widget da Início. Registre a implementação em <see cref="WidgetRegistry"/>; o host decide
/// ordem, visibilidade (preferência do usuário), posição na grade e animação.
/// </summary>
public interface IHomeWidget
{
    /// <summary>Id estável (persistido na preferência). Nunca mude depois de lançado.</summary>
    string Id { get; }

    /// <summary>Título em PT-BR (chave de <c>Strings.Tr</c>), em caixa alta.</summary>
    string Title { get; }

    /// <summary>Dados SVG (path) do ícone do cabeçalho, mesmo formato de <c>SvgIcon.Data</c>.</summary>
    string IconPath { get; }

    /// <summary>Se o widget faz sentido neste contexto (jogo, Este PC, sem jogos...). Falso = não aparece.</summary>
    bool IsAvailable(WidgetContext context);

    /// <summary>
    /// Tamanhos permitidos neste contexto, em células (cada célula tem ~112 px). O primeiro é o padrão;
    /// o usuário alterna entre eles no modo de edição.
    /// </summary>
    IReadOnlyList<WidgetSpan> Sizes(WidgetContext context);

    /// <summary>Monta o conteúdo para o tamanho escolhido. Chamado de novo quando o contexto ou o tamanho mudam; deve ser barato.</summary>
    WidgetContent Render(WidgetContext context, WidgetSpan span);
}
