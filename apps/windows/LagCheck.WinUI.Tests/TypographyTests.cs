using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class TypographyTests
{
    private static string FindRepoRoot()
    {
        var current = AppContext.BaseDirectory;
        while (!string.IsNullOrEmpty(current))
        {
            var themePath = Path.Combine(current, "apps", "windows", "LagCheck.WinUI", "Styles", "Theme.xaml");
            var fontsPath = Path.Combine(current, "apps", "android", "desktop", "src", "main", "resources", "fonts");
            if (File.Exists(themePath) && Directory.Exists(fontsPath))
            {
                return current;
            }
            current = Path.GetDirectoryName(current);
        }

        // Fallback: busca a partir do diretório de trabalho atual
        current = Directory.GetCurrentDirectory();
        while (!string.IsNullOrEmpty(current))
        {
            var themePath = Path.Combine(current, "apps", "windows", "LagCheck.WinUI", "Styles", "Theme.xaml");
            var fontsPath = Path.Combine(current, "apps", "android", "desktop", "src", "main", "resources", "fonts");
            if (File.Exists(themePath) && Directory.Exists(fontsPath))
            {
                return current;
            }
            current = Path.GetDirectoryName(current);
        }

        throw new DirectoryNotFoundException("Não foi possível localizar a raiz do repositório contendo Theme.xaml e as fontes de referência.");
    }

    [Fact]
    public void Theme_declares_triad_font_families_pointing_to_existing_ttf_files()
    {
        var repoRoot = FindRepoRoot();
        var themePath = Path.Combine(repoRoot, "apps", "windows", "LagCheck.WinUI", "Styles", "Theme.xaml");
        var fontsDir = Path.Combine(repoRoot, "apps", "android", "desktop", "src", "main", "resources", "fonts");

        Assert.True(File.Exists(themePath), $"Theme.xaml não encontrado em: {themePath}");
        Assert.True(Directory.Exists(fontsDir), $"Diretório de fontes não encontrado em: {fontsDir}");

        var doc = XDocument.Load(themePath);
        var xNamespace = XNamespace.Get("http://schemas.microsoft.com/winfx/2006/xaml");
        var defaultNamespace = doc.Root?.GetDefaultNamespace() ?? XNamespace.None;

        var expectedKeys = new[]
        {
            "BodyFont",
            "BodyMediumFont",
            "BodySemiBoldFont",
            "MetricFont",
            "HeadingFont",
            "HeadingBoldFont",
            "TechnicalFont",
        };

        var fontDeclarations = new Dictionary<string, string>();
        foreach (var element in doc.Descendants())
        {
            if (element.Name.LocalName == "FontFamily")
            {
                var key = element.Attribute(xNamespace + "Key")?.Value;
                if (!string.IsNullOrEmpty(key))
                {
                    fontDeclarations[key] = element.Value.Trim();
                }
            }
        }

        foreach (var key in expectedKeys)
        {
            Assert.True(fontDeclarations.ContainsKey(key), $"Chave de fonte '{key}' não declarada em Theme.xaml");

            var value = fontDeclarations[key];
            Assert.Contains(".ttf", value);

            // Extrai o nome do arquivo .ttf da URI (ex: ms-appx:///Assets/Fonts/barlow_regular.ttf#Barlow)
            var match = Regex.Match(value, @"(?<file>[a-zA-Z0-9_]+\.ttf)");
            Assert.True(match.Success, $"Não foi possível extrair o arquivo .ttf da declaração '{value}' (chave {key})");

            var ttfFileName = match.Groups["file"].Value;
            var ttfFullPath = Path.Combine(fontsDir, ttfFileName);
            Assert.True(File.Exists(ttfFullPath), $"Arquivo .ttf '{ttfFileName}' não existe em {fontsDir} (usado por {key})");
        }
    }

    [Fact]
    public void Theme_does_not_contain_segoe_ui_variable_or_cascadia_outside_comments()
    {
        var repoRoot = FindRepoRoot();
        var themePath = Path.Combine(repoRoot, "apps", "windows", "LagCheck.WinUI", "Styles", "Theme.xaml");
        var rawXml = File.ReadAllText(themePath);

        // Remove comentários XML (<!-- ... -->)
        var xmlWithoutComments = Regex.Replace(rawXml, @"<!--.*?-->", string.Empty, RegexOptions.Singleline);

        Assert.DoesNotContain("Segoe UI Variable", xmlWithoutComments, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("Cascadia", xmlWithoutComments, StringComparison.OrdinalIgnoreCase);
    }
}
