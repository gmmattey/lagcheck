using System;
using System.Collections.Generic;
using System.IO;
using LagCheck.WinUI.Widgets;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class WidgetLayoutTests
{
    [Fact]
    public void WidgetSpan_ToString_FormatsCorrectly()
    {
        Assert.Equal("2x1", new WidgetSpan(2, 1).ToString());
        Assert.Equal("4x2", new WidgetSpan(4, 2).ToString());
        Assert.Equal("1x1", new WidgetSpan(1, 1).ToString());
    }

    [Theory]
    [InlineData("2x1", true, 2, 1)]
    [InlineData("4x2", true, 4, 2)]
    [InlineData("1x1", true, 1, 1)]
    [InlineData(null, false, 0, 0)]
    [InlineData("", false, 0, 0)]
    [InlineData("   ", false, 0, 0)]
    [InlineData("2x", false, 0, 0)]
    [InlineData("x1", false, 0, 0)]
    [InlineData("abc", false, 0, 0)]
    [InlineData("0x1", false, 0, 0)]
    [InlineData("2x0", false, 0, 0)]
    [InlineData("-1x2", false, 0, 0)]
    [InlineData("2x1x3", false, 0, 0)]
    public void WidgetSpan_TryParse_ValidatesAndParses(string? input, bool expectedSuccess, int expectedCols, int expectedRows)
    {
        var success = WidgetSpan.TryParse(input, out var span);
        Assert.Equal(expectedSuccess, success);
        if (expectedSuccess)
        {
            Assert.Equal(expectedCols, span.Cols);
            Assert.Equal(expectedRows, span.Rows);
        }
    }

    [Fact]
    public void WidgetPacker_MaintainsOrder()
    {
        var items = new List<(string Id, WidgetSpan Span)>
        {
            ("a", new WidgetSpan(2, 1)),
            ("b", new WidgetSpan(2, 1)),
            ("c", new WidgetSpan(2, 1)),
        };

        var placements = WidgetPacker.Pack(items, columns: 4, out var rows);

        Assert.Equal(3, placements.Count);
        Assert.Equal("a", placements[0].Id);
        Assert.Equal("b", placements[1].Id);
        Assert.Equal("c", placements[2].Id);
        Assert.Equal(0, placements[0].Col);
        Assert.Equal(2, placements[1].Col);
        Assert.Equal(0, placements[2].Col);
        Assert.Equal(1, placements[2].Row);
        Assert.Equal(2, rows);
    }

    [Fact]
    public void WidgetPacker_FillsHoles_With_2x1_After_2x2()
    {
        // Grade com 4 colunas:
        // Item 'a' (2x2) vai em (col 0, row 0, 2 cols, 2 rows) -> ocupa (0,0), (1,0), (0,1), (1,1)
        // Item 'b' (4x1) não cabe em row 0 ou row 1 -> vai para row 2 (0, 2, 4 cols, 1 row)
        // Item 'c' (2x1) cabe no buraco deixado ao lado de 'a' na row 0 -> (col 2, row 0, 2 cols, 1 row)
        var items = new List<(string Id, WidgetSpan Span)>
        {
            ("a", new WidgetSpan(2, 2)),
            ("b", new WidgetSpan(4, 1)),
            ("c", new WidgetSpan(2, 1)),
        };

        var placements = WidgetPacker.Pack(items, columns: 4, out var rows);

        var a = Assert.Single(placements, p => p.Id == "a");
        var b = Assert.Single(placements, p => p.Id == "b");
        var c = Assert.Single(placements, p => p.Id == "c");

        Assert.Equal(0, a.Col);
        Assert.Equal(0, a.Row);

        Assert.Equal(0, b.Col);
        Assert.Equal(2, b.Row);

        Assert.Equal(2, c.Col);
        Assert.Equal(0, c.Row);

        Assert.Equal(3, rows);
    }

    [Fact]
    public void WidgetPacker_ClampsSingleColumn()
    {
        var items = new List<(string Id, WidgetSpan Span)>
        {
            ("wide", new WidgetSpan(4, 2)),
            ("medium", new WidgetSpan(2, 1)),
        };

        var placements = WidgetPacker.Pack(items, columns: 1, out var rows);

        Assert.Equal(2, placements.Count);
        Assert.Equal(1, placements[0].Cols);
        Assert.Equal(2, placements[0].Rows);
        Assert.Equal(0, placements[0].Col);
        Assert.Equal(0, placements[0].Row);

        Assert.Equal(1, placements[1].Cols);
        Assert.Equal(1, placements[1].Rows);
        Assert.Equal(0, placements[1].Col);
        Assert.Equal(2, placements[1].Row);

        Assert.Equal(3, rows);
    }

    [Fact]
    public void WidgetPacker_ReturnsCorrectTotalRows()
    {
        var items = new List<(string Id, WidgetSpan Span)>
        {
            ("w1", new WidgetSpan(4, 1)),
            ("w2", new WidgetSpan(4, 1)),
            ("w3", new WidgetSpan(4, 2)),
        };

        WidgetPacker.Pack(items, columns: 4, out var rows);
        Assert.Equal(4, rows);
    }

    [Fact]
    public void WidgetPrefs_Ordered_WithNewAndUnknownIds()
    {
        var defaultOrder = new[] { "latency", "platforms", "quality", "activity", "gallery", "favorites" };
        var prefs = new WidgetPrefs
        {
            Order = { "quality", "unknown_xyz", "latency" }
        };

        var ordered = prefs.Ordered(defaultOrder);

        Assert.Equal(
            new[] { "quality", "latency", "platforms", "activity", "gallery", "favorites" },
            ordered);
    }

    [Fact]
    public void WidgetPrefs_Move_RespectsBoundaries()
    {
        var defaultOrder = new[] { "a", "b", "c" };
        var prefs = new WidgetPrefs();

        // Mover o primeiro para cima (-1) não deve ter efeito
        prefs.Move("a", -1, defaultOrder);
        Assert.Empty(prefs.Order);

        // Mover o último para baixo (+1) não deve ter efeito
        prefs.Move("c", 1, defaultOrder);
        Assert.Empty(prefs.Order);

        // Mover o do meio para cima (-1) inverte com o primeiro
        prefs.Move("b", -1, defaultOrder);
        Assert.Equal(new[] { "b", "a", "c" }, prefs.Order);

        // Mover id desconhecido não altera nada
        prefs.Move("inexistente", 1, defaultOrder);
        Assert.Equal(new[] { "b", "a", "c" }, prefs.Order);
    }

    [Fact]
    public void WidgetPrefs_MoveTo_RespectsLimits()
    {
        var defaultOrder = new[] { "a", "b", "c", "d" };
        var prefs = new WidgetPrefs();

        // Move "d" para o índice 0 (início)
        prefs.MoveTo("d", 0, defaultOrder);
        Assert.Equal(new[] { "d", "a", "b", "c" }, prefs.Order);

        // Move "a" para índice além do limite superior (clamp ao final)
        prefs.MoveTo("a", 999, defaultOrder);
        Assert.Equal(new[] { "d", "b", "c", "a" }, prefs.Order);

        // Move "c" para índice negativo (clamp a 0)
        prefs.MoveTo("c", -5, defaultOrder);
        Assert.Equal(new[] { "c", "d", "b", "a" }, prefs.Order);

        // Move id desconhecido não altera a ordem
        prefs.MoveTo("xyz", 1, defaultOrder);
        Assert.Equal(new[] { "c", "d", "b", "a" }, prefs.Order);
    }

    [Fact]
    public void WidgetPrefs_SetHidden_TracksState()
    {
        var prefs = new WidgetPrefs();
        Assert.False(prefs.IsHidden("latency"));

        prefs.SetHidden("latency", true);
        Assert.True(prefs.IsHidden("latency"));

        prefs.SetHidden("latency", false);
        Assert.False(prefs.IsHidden("latency"));
    }

    [Fact]
    public void WidgetPrefs_HideAll_And_ShowAll()
    {
        var prefs = new WidgetPrefs();
        prefs.HideAll(new[] { "latency", "platforms", "latency" });

        Assert.True(prefs.IsHidden("latency"));
        Assert.True(prefs.IsHidden("platforms"));
        Assert.Equal(2, prefs.Hidden.Count);

        prefs.ShowAll();
        Assert.Empty(prefs.Hidden);
        Assert.False(prefs.IsHidden("latency"));
        Assert.False(prefs.IsHidden("platforms"));
    }

    [Fact]
    public void WidgetPrefs_ResolveSpan_AllowedAndFallback()
    {
        var prefs = new WidgetPrefs();
        var allowed = new WidgetSpan[] { new(2, 2), new(2, 1), new(4, 2) };

        // Lista vazia cai no fallback 2x1
        Assert.Equal(new WidgetSpan(2, 1), prefs.ResolveSpan("any", Array.Empty<WidgetSpan>()));

        // Sem tamanho salvo cai no primeiro da lista permitida
        Assert.Equal(new WidgetSpan(2, 2), prefs.ResolveSpan("latency", allowed));

        // Tamanho salvo válido e permitido
        prefs.SetSize("latency", new WidgetSpan(2, 1));
        Assert.Equal(new WidgetSpan(2, 1), prefs.ResolveSpan("latency", allowed));

        // Tamanho salvo não permitido volta ao padrão
        prefs.SetSize("latency", new WidgetSpan(3, 3));
        Assert.Equal(new WidgetSpan(2, 2), prefs.ResolveSpan("latency", allowed));

        // Texto salvo inválido volta ao padrão
        prefs.Sizes["latency"] = "invalid_span";
        Assert.Equal(new WidgetSpan(2, 2), prefs.ResolveSpan("latency", allowed));
    }

    [Fact]
    public void WidgetPrefs_SetSize_StoresString()
    {
        var prefs = new WidgetPrefs();
        prefs.SetSize("latency", new WidgetSpan(4, 2));

        Assert.True(prefs.Sizes.TryGetValue("latency", out var text));
        Assert.Equal("4x2", text);
    }

    [Fact]
    public void WidgetPrefs_CycleSize_CyclesAndWraps()
    {
        var prefs = new WidgetPrefs();
        var allowed = new WidgetSpan[] { new(2, 2), new(2, 1), new(4, 2) };

        // Inicial é o padrão (2x2), primeiro ciclo vai para 2x1
        var next1 = prefs.CycleSize("latency", allowed);
        Assert.Equal(new WidgetSpan(2, 1), next1);

        // Segundo ciclo vai para 4x2
        var next2 = prefs.CycleSize("latency", allowed);
        Assert.Equal(new WidgetSpan(4, 2), next2);

        // Terceiro ciclo volta ao primeiro (2x2)
        var next3 = prefs.CycleSize("latency", allowed);
        Assert.Equal(new WidgetSpan(2, 2), next3);

        // Com lista vazia retorna 2x1
        Assert.Equal(new WidgetSpan(2, 1), prefs.CycleSize("other", Array.Empty<WidgetSpan>()));
    }

    [Fact]
    public void WidgetPrefs_Reset_ClearsAllData()
    {
        var prefs = new WidgetPrefs
        {
            Order = { "latency", "platforms" },
            Hidden = { "quality" },
            Sizes = { ["latency"] = "4x2" }
        };

        prefs.Reset();

        Assert.Empty(prefs.Order);
        Assert.Empty(prefs.Hidden);
        Assert.Empty(prefs.Sizes);
    }

    [Fact]
    public void WidgetPrefsStore_SaveAndLoad_RoundTrip()
    {
        var tempFile = Path.Combine(Path.GetTempPath(), $"lagcheck_widgets_test_{Guid.NewGuid():N}.json");
        try
        {
            var store = new WidgetPrefsStore(tempFile);
            var initial = new WidgetPrefs
            {
                Order = { "activity", "latency" },
                Hidden = { "favorites" },
                Sizes = { ["latency"] = "2x1", ["activity"] = "2x2" }
            };

            store.Save(initial);

            var loaded = store.Load();
            Assert.Equal(initial.Order, loaded.Order);
            Assert.Equal(initial.Hidden, loaded.Hidden);
            Assert.Equal(initial.Sizes, loaded.Sizes);
        }
        finally
        {
            if (File.Exists(tempFile)) File.Delete(tempFile);
        }
    }

    [Fact]
    public void WidgetPrefsStore_CorruptedJson_FallsBackToDefault()
    {
        var tempFile = Path.Combine(Path.GetTempPath(), $"lagcheck_corrupt_test_{Guid.NewGuid():N}.json");
        try
        {
            File.WriteAllText(tempFile, "{ broken json content [[[[");
            var store = new WidgetPrefsStore(tempFile);

            var loaded = store.Load();
            Assert.NotNull(loaded);
            Assert.Empty(loaded.Order);
            Assert.Empty(loaded.Hidden);
            Assert.Empty(loaded.Sizes);
        }
        finally
        {
            if (File.Exists(tempFile)) File.Delete(tempFile);
        }
    }

    [Fact]
    public void WidgetPrefsStore_NonExistentFile_ReturnsDefault()
    {
        var nonExistentPath = Path.Combine(Path.GetTempPath(), $"non_existent_{Guid.NewGuid():N}.json");
        var store = new WidgetPrefsStore(nonExistentPath);

        var loaded = store.Load();
        Assert.NotNull(loaded);
        Assert.Empty(loaded.Order);
        Assert.Empty(loaded.Hidden);
        Assert.Empty(loaded.Sizes);
    }
}
