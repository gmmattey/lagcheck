using System.Text.Json;

namespace LagCheck.WinUI.Widgets;

/// <summary>Tamanho de um widget em células da grade (colunas x linhas).</summary>
public readonly record struct WidgetSpan(int Cols, int Rows)
{
    public override string ToString() => $"{Cols}x{Rows}";

    public static bool TryParse(string? text, out WidgetSpan span)
    {
        span = default;
        var parts = text?.Split('x');
        if (parts is not { Length: 2 } || !int.TryParse(parts[0], out var cols) || !int.TryParse(parts[1], out var rows) || cols < 1 || rows < 1) return false;
        span = new WidgetSpan(cols, rows);
        return true;
    }
}

/// <summary>Posição de um widget na grade, em células.</summary>
public readonly record struct WidgetPlacement(string Id, int Col, int Row, int Cols, int Rows);

/// <summary>
/// Empacotador da grade dos widgets: coloca cada widget, na ordem recebida, na primeira posição livre
/// (varrendo linha a linha). Lógica pura, sem WinUI, para poder ser testada.
/// </summary>
public static class WidgetPacker
{
    public static IReadOnlyList<WidgetPlacement> Pack(IReadOnlyList<(string Id, WidgetSpan Span)> items, int columns, out int rows)
    {
        columns = Math.Max(1, columns);
        var occupied = new List<bool[]>();
        var result = new List<WidgetPlacement>(items.Count);
        rows = 0;
        foreach (var (id, requested) in items)
        {
            var cols = Math.Clamp(requested.Cols, 1, columns);
            var height = Math.Max(1, requested.Rows);
            var placed = false;
            for (var row = 0; !placed; row++)
            {
                while (occupied.Count < row + height) occupied.Add(new bool[columns]);
                for (var col = 0; col + cols <= columns && !placed; col++)
                {
                    if (!Fits(occupied, row, col, cols, height)) continue;
                    for (var r = row; r < row + height; r++)
                        for (var c = col; c < col + cols; c++) occupied[r][c] = true;
                    result.Add(new WidgetPlacement(id, col, row, cols, height));
                    rows = Math.Max(rows, row + height);
                    placed = true;
                }
            }
        }
        return result;
    }

    private static bool Fits(List<bool[]> occupied, int row, int col, int cols, int height)
    {
        for (var r = row; r < row + height; r++)
            for (var c = col; c < col + cols; c++)
                if (occupied[r][c]) return false;
        return true;
    }
}

/// <summary>Preferência do usuário: ordem e widgets ocultos. Ids desconhecidos são ignorados; widgets novos entram no fim.</summary>
public sealed class WidgetPrefs
{
    public List<string> Order { get; set; } = new();
    public List<string> Hidden { get; set; } = new();
    /// <summary>Tamanho escolhido por widget, no formato "2x1".</summary>
    public Dictionary<string, string> Sizes { get; set; } = new();

    public bool IsHidden(string id) => Hidden.Contains(id, StringComparer.Ordinal);

    /// <summary>Ids na ordem do usuário; os que o usuário nunca viu seguem a ordem padrão, depois dos já ordenados.</summary>
    public IReadOnlyList<string> Ordered(IReadOnlyList<string> defaultOrder)
    {
        var known = defaultOrder.ToHashSet(StringComparer.Ordinal);
        var result = Order.Where(known.Contains).Distinct(StringComparer.Ordinal).ToList();
        result.AddRange(defaultOrder.Where(id => !result.Contains(id, StringComparer.Ordinal)));
        return result;
    }

    public void SetHidden(string id, bool hidden)
    {
        Hidden.Remove(id);
        if (hidden) Hidden.Add(id);
    }

    /// <summary>Move <paramref name="id"/> uma posição (−1 sobe, +1 desce) dentro da ordem completa.</summary>
    public void Move(string id, int delta, IReadOnlyList<string> defaultOrder)
    {
        var order = Ordered(defaultOrder).ToList();
        var index = order.IndexOf(id);
        var target = index + delta;
        if (index < 0 || target < 0 || target >= order.Count) return;
        order.RemoveAt(index);
        order.Insert(target, id);
        Order = order;
    }

    /// <summary>Oculta todos os widgets informados (a Início continua oferecendo "Personalizar" para trazê-los de volta).</summary>
    public void HideAll(IEnumerable<string> ids)
    {
        foreach (var id in ids) if (!IsHidden(id)) Hidden.Add(id);
    }

    public void ShowAll() => Hidden.Clear();

    /// <summary>Tamanho efetivo: o salvo, se ainda for permitido; senão o padrão (primeiro da lista).</summary>
    public WidgetSpan ResolveSpan(string id, IReadOnlyList<WidgetSpan> allowed)
    {
        if (allowed.Count == 0) return new WidgetSpan(2, 1);
        return Sizes.TryGetValue(id, out var text) && WidgetSpan.TryParse(text, out var saved) && allowed.Contains(saved) ? saved : allowed[0];
    }

    public void SetSize(string id, WidgetSpan span) => Sizes[id] = span.ToString();

    /// <summary>Passa ao próximo tamanho permitido (volta ao primeiro depois do último).</summary>
    public WidgetSpan CycleSize(string id, IReadOnlyList<WidgetSpan> allowed)
    {
        if (allowed.Count == 0) return new WidgetSpan(2, 1);
        var next = allowed[(allowed.ToList().IndexOf(ResolveSpan(id, allowed)) + 1) % allowed.Count];
        SetSize(id, next);
        return next;
    }

    /// <summary>Move <paramref name="id"/> para uma posição absoluta da ordem completa (arrastar e soltar).</summary>
    public void MoveTo(string id, int targetIndex, IReadOnlyList<string> defaultOrder)
    {
        var order = Ordered(defaultOrder).ToList();
        var index = order.IndexOf(id);
        if (index < 0) return;
        order.RemoveAt(index);
        order.Insert(Math.Clamp(targetIndex, 0, order.Count), id);
        Order = order;
    }

    public void Reset()
    {
        Order.Clear();
        Hidden.Clear();
        Sizes.Clear();
    }
}

/// <summary>Grava a preferência em JSON local; qualquer falha de disco cai no padrão, sem quebrar a tela.</summary>
public sealed class WidgetPrefsStore
{
    private readonly string _path;

    public WidgetPrefsStore(string? path = null)
    {
        _path = path ?? System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "LagCheck", "widgets.json");
    }

    public WidgetPrefs Load()
    {
        try
        {
            if (!File.Exists(_path)) return new WidgetPrefs();
            return JsonSerializer.Deserialize<WidgetPrefs>(File.ReadAllText(_path)) ?? new WidgetPrefs();
        }
        catch
        {
            return new WidgetPrefs();
        }
    }

    public void Save(WidgetPrefs prefs)
    {
        try
        {
            Directory.CreateDirectory(System.IO.Path.GetDirectoryName(_path)!);
            File.WriteAllText(_path, JsonSerializer.Serialize(prefs));
        }
        catch
        {
            // Sem disco, a personalização vale só nesta sessão.
        }
    }
}
