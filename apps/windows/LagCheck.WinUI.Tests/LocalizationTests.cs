using System.Globalization;
using LagCheck.WinUI.Localization;
using Xunit;

namespace LagCheck.WinUI.Tests;

public sealed class LocalizationTests
{
    [Fact]
    public void All_registered_keys_have_valid_english_and_spanish_translations()
    {
        var service = LocalizationService.Instance;
        Assert.NotEmpty(service.AllKeys);

        foreach (var key in service.AllKeys)
        {
            var entry = service.GetEntry(key);
            Assert.NotNull(entry);

            Assert.False(string.IsNullOrWhiteSpace(entry.Value.En), $"Key '{key}' has empty EN translation");
            Assert.False(string.IsNullOrWhiteSpace(entry.Value.Es), $"Key '{key}' has empty ES translation");

            // Format placeholders check: if key has {0}, both translations must have {0}
            if (key.Contains("{0}"))
            {
                Assert.Contains("{0}", entry.Value.En);
                Assert.Contains("{0}", entry.Value.Es);
            }
        }
    }

    [Fact]
    public void Unknown_keys_fallback_to_the_original_text()
    {
        var service = LocalizationService.Instance;
        service.SelectedLanguage = AppLanguage.En;

        var unknown = "Um texto aleatório que não existe na tabela";
        Assert.Equal(unknown, service.Translate(unknown));
    }

    [Fact]
    public void Language_switching_translates_canonical_verdicts()
    {
        var service = LocalizationService.Instance;

        service.SelectedLanguage = AppLanguage.PtBr;
        Assert.Equal("● PRONTO PARA RANKED", Strings.Tr("● PRONTO PARA RANKED"));
        Assert.Equal("▲ EU EVITARIA RANKED AGORA", Strings.Tr("▲ EU EVITARIA RANKED AGORA"));
        Assert.Equal("— INCONCLUSIVO", Strings.Tr("— INCONCLUSIVO"));

        service.SelectedLanguage = AppLanguage.En;
        Assert.Equal("● READY FOR RANKED", Strings.Tr("● PRONTO PARA RANKED"));
        Assert.Equal("▲ I'D AVOID RANKED RIGHT NOW", Strings.Tr("▲ EU EVITARIA RANKED AGORA"));
        Assert.Equal("— INCONCLUSIVE", Strings.Tr("— INCONCLUSIVO"));

        service.SelectedLanguage = AppLanguage.Es;
        Assert.Equal("● LISTO PARA RANKED", Strings.Tr("● PRONTO PARA RANKED"));
        Assert.Equal("▲ EVITARÍA RANKED AHORA", Strings.Tr("▲ EU EVITARIA RANKED AGORA"));
        Assert.Equal("— INCONCLUSO", Strings.Tr("— INCONCLUSIVO"));
    }

    [Fact]
    public void Format_string_interpolates_arguments_correctly()
    {
        var service = LocalizationService.Instance;

        service.SelectedLanguage = AppLanguage.PtBr;
        Assert.Equal("Conexão · Valorant", Strings.Format("Conexão · {0}", "Valorant"));

        service.SelectedLanguage = AppLanguage.En;
        Assert.Equal("Connection · Valorant", Strings.Format("Conexão · {0}", "Valorant"));

        service.SelectedLanguage = AppLanguage.Es;
        Assert.Equal("Conexión · Valorant", Strings.Format("Conexión · {0}", "Valorant"));
    }

    [Theory]
    [InlineData("pt-BR", AppLanguage.PtBr)]
    [InlineData("en-US", AppLanguage.En)]
    [InlineData("en-GB", AppLanguage.En)]
    [InlineData("es-ES", AppLanguage.Es)]
    [InlineData("es-MX", AppLanguage.Es)]
    public void System_language_detection_maps_culture_correctly(string cultureName, AppLanguage expected)
    {
        var prev = CultureInfo.CurrentUICulture;
        try
        {
            CultureInfo.CurrentUICulture = new CultureInfo(cultureName);
            Assert.Equal(expected, LocalizationService.ResolveSystemLanguage());
        }
        finally
        {
            CultureInfo.CurrentUICulture = prev;
        }
    }
}
