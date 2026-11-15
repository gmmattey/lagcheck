using System.Globalization;
using LagCheck.WinUI.Controls;
using LagCheck.WinUI.Library;
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
        var prev = service.SelectedLanguage;
        try
        {
            service.SelectedLanguage = AppLanguage.En;

            var unknown = "Um texto aleatório que não existe na tabela";
            Assert.Equal(unknown, service.Translate(unknown));
        }
        finally
        {
            service.SelectedLanguage = prev;
        }
    }

    [Fact]
    public void Language_switching_translates_canonical_verdicts()
    {
        var service = LocalizationService.Instance;
        var prev = service.SelectedLanguage;
        try
        {
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
        finally
        {
            service.SelectedLanguage = prev;
        }
    }

    [Fact]
    public void Home_launch_cta_is_localized_in_all_supported_languages()
    {
        var service = LocalizationService.Instance;
        var prev = service.SelectedLanguage;
        try
        {
            service.SelectedLanguage = AppLanguage.PtBr;
            Assert.Equal("JOGAR AGORA", Strings.Tr("JOGAR AGORA"));

            service.SelectedLanguage = AppLanguage.En;
            Assert.Equal("PLAY NOW", Strings.Tr("JOGAR AGORA"));

            service.SelectedLanguage = AppLanguage.Es;
            Assert.Equal("JUGAR AHORA", Strings.Tr("JOGAR AGORA"));
        }
        finally
        {
            service.SelectedLanguage = prev;
        }
    }

    [Fact]
    public void Quick_action_returns_to_portuguese_after_a_language_switch()
    {
        var service = LocalizationService.Instance;
        var prev = service.SelectedLanguage;
        try
        {
            service.SelectedLanguage = AppLanguage.Es;
            Assert.Equal("▶ JUGAR AHORA", Strings.Tr("▶ JOGAR AGORA"));

            service.SelectedLanguage = AppLanguage.PtBr;
            Assert.Equal("▶ JOGAR AGORA", Strings.Tr("▶ JOGAR AGORA"));
        }
        finally
        {
            service.SelectedLanguage = prev;
        }
    }

    [Fact]
    public void Format_string_interpolates_arguments_correctly()
    {
        var service = LocalizationService.Instance;
        var prev = service.SelectedLanguage;
        try
        {
            service.SelectedLanguage = AppLanguage.PtBr;
            Assert.Equal("Conexão · Valorant", Strings.Format("Conexão · {0}", "Valorant"));

            service.SelectedLanguage = AppLanguage.En;
            Assert.Equal("Connection · Valorant", Strings.Format("Conexão · {0}", "Valorant"));

            service.SelectedLanguage = AppLanguage.Es;
            Assert.Equal("Conexión · Valorant", Strings.Format("Conexión · {0}", "Valorant"));
        }
        finally
        {
            service.SelectedLanguage = prev;
        }
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

    [Fact]
    public void Settings_ps5_categories_and_fullscreen_strings_are_localized_correctly()
    {
        var service = LocalizationService.Instance;
        var prev = service.SelectedLanguage;
        try
        {
            service.SelectedLanguage = AppLanguage.PtBr;
            Assert.Equal("Tela e janela", Strings.Tr("Tela e janela"));
            Assert.Equal("Modo tela cheia", Strings.Tr("Modo tela cheia"));
            Assert.Equal("Abrir em tela cheia", Strings.Tr("Abrir em tela cheia"));
            Assert.Equal("Ligado", Strings.Tr("Ligado"));
            Assert.Equal("Desligado", Strings.Tr("Desligado"));

            service.SelectedLanguage = AppLanguage.En;
            Assert.Equal("Screen and window", Strings.Tr("Tela e janela"));
            Assert.Equal("Full screen mode", Strings.Tr("Modo tela cheia"));
            Assert.Equal("Open in full screen", Strings.Tr("Abrir em tela cheia"));
            Assert.Equal("On", Strings.Tr("Ligado"));
            Assert.Equal("Off", Strings.Tr("Desligado"));

            service.SelectedLanguage = AppLanguage.Es;
            Assert.Equal("Pantalla y ventana", Strings.Tr("Tela e janela"));
            Assert.Equal("Modo pantalla completa", Strings.Tr("Modo tela cheia"));
            Assert.Equal("Abrir en pantalla completa", Strings.Tr("Abrir em tela cheia"));
            Assert.Equal("Activado", Strings.Tr("Ligado"));
            Assert.Equal("Desactivado", Strings.Tr("Desligado"));
        }
        finally
        {
            service.SelectedLanguage = prev;
        }
    }

    [Fact]
    public void Effective_culture_follows_selected_app_language()
    {
        var service = LocalizationService.Instance;
        var prev = service.SelectedLanguage;
        try
        {
            service.SelectedLanguage = AppLanguage.PtBr;
            Assert.Equal("pt-BR", service.EffectiveCulture.Name);

            service.SelectedLanguage = AppLanguage.En;
            Assert.Equal("en-US", service.EffectiveCulture.Name);

            service.SelectedLanguage = AppLanguage.Es;
            Assert.Equal("es-ES", service.EffectiveCulture.Name);
        }
        finally
        {
            service.SelectedLanguage = prev;
        }
    }

    [Fact]
    public void GamePills_translates_store_genres_to_selected_language()
    {
        var service = LocalizationService.Instance;
        var prev = service.SelectedLanguage;
        var game = new LibraryGame(
            Id: "steam_949230",
            Title: "Cities: Skylines II",
            Platform: GamePlatform.Steam,
            IsInstalled: true,
            IsFavorite: false,
            IsLaunchable: true,
            LastPlayedEpochMs: null,
            LastLaunchedEpochMs: null,
            InstalledAtEpochMs: null,
            CoverArtworkPath: null,
            HeroArtworkPath: null,
            NetworkKind: GameNetworkKind.Offline,
            DiagnosticGameId: null,
            NetworkLabel: "Offline",
            Tags: System.Array.Empty<string>(),
            Description: null,
            AlsoIds: System.Array.Empty<string>(),
            Info: new GameInfo(
                Description: null,
                Developer: "Iceflake Studios",
                Publisher: "Paradox Interactive",
                ReleaseDate: "2023-10-24",
                Genres: new[] { "Simulation", "Strategy" },
                Modes: new[] { "singleplayer" }));

        try
        {
            service.SelectedLanguage = AppLanguage.PtBr;
            Assert.Equal(new[] { "Simulação", "Estratégia", "Um jogador" }, GamePills.Labels(game));

            service.SelectedLanguage = AppLanguage.En;
            Assert.Equal(new[] { "Simulation", "Strategy", "Single-player" }, GamePills.Labels(game));

            service.SelectedLanguage = AppLanguage.Es;
            Assert.Equal(new[] { "Simulación", "Estrategia", "Un jugador" }, GamePills.Labels(game));
        }
        finally
        {
            service.SelectedLanguage = prev;
        }
    }
}
