using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text.Json;

namespace LagCheck.WinUI.Localization;

/// <summary>
/// Central multi-language service for LagCheck Windows (PT-BR, EN, ES).
/// Mirrors the robust architecture of Android's UiStrings and iOS AppLocalization:
/// - The canonical PT-BR text is the key.
/// - If a translation is missing or language is PT-BR, it falls back cleanly to PT-BR (never blank, never tech keys).
/// - Honors system language by default, with explicit user override stored in local preferences.
/// </summary>
public sealed class LocalizationService
{
    private static readonly Lazy<LocalizationService> _instance = new(() => new LocalizationService());
    public static LocalizationService Instance => _instance.Value;

    private readonly record struct TranslationEntry(string En, string Es);
    private readonly Dictionary<string, TranslationEntry> _table = new(StringComparer.Ordinal);
    private AppLanguage _selectedLanguage = AppLanguage.System;

    public event Action? LanguageChanged;

    public LocalizationService()
    {
        PopulateTranslations();
        LoadPreference();
    }

    public AppLanguage SelectedLanguage
    {
        get => _selectedLanguage;
        set
        {
            if (_selectedLanguage == value) return;
            _selectedLanguage = value;
            SavePreference();
            LanguageChanged?.Invoke();
        }
    }

    public AppLanguage EffectiveLanguage => _selectedLanguage switch
    {
        AppLanguage.System => ResolveSystemLanguage(),
        var specific => specific
    };

    public static AppLanguage ResolveSystemLanguage()
    {
        var cultureName = CultureInfo.CurrentUICulture.Name;
        if (cultureName.StartsWith("en", StringComparison.OrdinalIgnoreCase)) return AppLanguage.En;
        if (cultureName.StartsWith("es", StringComparison.OrdinalIgnoreCase)) return AppLanguage.Es;
        return AppLanguage.PtBr;
    }

    public string Translate(string ptText)
    {
        if (string.IsNullOrEmpty(ptText)) return ptText;
        if (!_table.TryGetValue(ptText, out var entry)) return ptText;

        return EffectiveLanguage switch
        {
            AppLanguage.En => entry.En,
            AppLanguage.Es => entry.Es,
            _ => ptText
        };
    }

    public string Format(string ptFormat, params object[] args)
    {
        var translatedFormat = Translate(ptFormat);
        try
        {
            return string.Format(CultureInfo.InvariantCulture, translatedFormat, args);
        }
        catch
        {
            return translatedFormat;
        }
    }

    public IReadOnlyCollection<string> AllKeys => _table.Keys;

    public (string En, string Es)? GetEntry(string ptText) =>
        _table.TryGetValue(ptText, out var e) ? (e.En, e.Es) : null;

    private void Add(string pt, string en, string es)
    {
        _table[pt] = new TranslationEntry(en, es);
    }

    private void PopulateTranslations()
    {
        // -------------------------------------------------------------
        // 1. Navegação, Barra Lateral e Shell (ShellPage)
        // -------------------------------------------------------------
        Add("Início", "Home", "Inicio");
        Add("Biblioteca", "Library", "Biblioteca");
        Add("Conexão", "Connection", "Conexión");
        Add("Histórico", "History", "Historial");
        Add("Ajustes", "Settings", "Ajustes");
        Add("Buscar jogo...", "Search games...", "Buscar juego...");
        Add("Buscar jogo (Ctrl+F)", "Search game (Ctrl+F)", "Buscar juego (Ctrl+F)");
        Add("Recolher barra lateral", "Collapse sidebar", "Contraer barra lateral");
        Add("Expandir barra lateral", "Expand sidebar", "Expandir barra lateral");
        Add("Biblioteca de jogos instalados", "Installed games library", "Biblioteca de juegos instalados");
        Add("Diagnóstico de rota de rede", "Network route check", "Diagnóstico de ruta de red");
        Add("Histórico de conexões", "Connection history", "Historial de conexiones");
        Add("Ajustes do launcher", "Launcher settings", "Ajustes del launcher");
        Add("REDE ATIVA", "ACTIVE NETWORK", "RED ACTIVA");
        Add("Rede ativa · Conectado", "Active network · Connected", "Red activa · Conectado");
        Add("GAME LAUNCHER", "GAME LAUNCHER", "GAME LAUNCHER");
        Add("PC GAMER", "PC GAMER", "PC GAMER");
        Add("BUILD v0.1.0 · WINUI 3", "BUILD v0.1.0 · WINUI 3", "BUILD v0.1.0 · WINUI 3");
        Add("Conexão · {0}", "Connection · {0}", "Conexión · {0}");

        // -------------------------------------------------------------
        // 2. Vereditos de Rede e Regra de Produto (docs/07-voz-do-produto.md)
        // -------------------------------------------------------------
        Add("● PRONTO PARA RANKED", "● READY FOR RANKED", "● LISTO PARA RANKED");
        Add("▲ EU EVITARIA RANKED AGORA", "▲ I'D AVOID RANKED RIGHT NOW", "▲ EVITARÍA RANKED AHORA");
        Add("▲ CONDIÇÕES INSTÁVEIS", "▲ UNSTABLE CONDITIONS", "▲ CONDICIONES INESTABLES");
        Add("— INCONCLUSIVO", "— INCONCLUSIVE", "— INCONCLUSO");
        Add("Pronto para jogar", "Ready to play", "Listo para jugar");
        Add("Conexão boa", "Good connection", "Buena conexión");
        Add("Condições instáveis", "Unstable conditions", "Condiciones inestables");
        Add("Evitaria Ranked", "Avoid Ranked", "Evitaría Ranked");
        Add("Inconclusivo", "Inconclusive", "Inconcluso");
        Add("sua conexão", "your connection", "tu conexión");
        Add("ESTABILIDADE DA ROTA", "ROUTE STABILITY", "ESTABILIDAD DE LA RUTA");
        Add("COMPETITIVO", "COMPETITIVE", "COMPETITIVO");
        Add("RESPOSTA", "RESPONSE", "RESPUESTA");
        Add("JITTER", "JITTER", "JITTER");
        Add("SOB CARGA", "UNDER LOAD", "BAJO CARGA");
        Add("PERDA", "LOSS", "PÉRDIDA");
        Add("EVIDÊNCIA DE ROTA", "ROUTE EVIDENCE", "EVIDENCIA DE RUTA");
        Add("Conexão instável", "Unstable connection", "Conexión inestable");
        Add("Conexão ruim", "Poor connection", "Conexión deficiente");
        Add("Conexão indeterminada", "Indeterminate connection", "Conexión indeterminada");
        Add("Medição inconclusiva", "Inconclusive check", "Medición inconclusa");
        Add("Eu evitaria ranked agora", "I'd avoid ranked right now", "Evitaría ranked ahora");
        Add("Pronto para ranked", "Ready for ranked", "Listo para ranked");

        // -------------------------------------------------------------
        // 3. Ações Rápidas do Launcher (Home & Game Details)
        // -------------------------------------------------------------
        Add("▶ JOGAR AGORA", "▶ PLAY NOW", "▶ JUGAR AHORA");
        Add("Checar conexão", "Check connection", "Chequear conexión");
        Add("Favoritar jogo", "Favorite game", "Agregar a favoritos");
        Add("Remover favorito", "Remove favorite", "Quitar de favoritos");
        Add("FAVORITAR", "FAVORITE", "FAVORITO");
        Add("REMOVER FAVORITO", "REMOVE FAVORITE", "QUITAR DE FAVORITOS");
        Add("Atualizar imagem oficial", "Refresh official artwork", "Actualizar imagen oficial");
        Add("Atualizando imagem...", "Refreshing artwork...", "Actualizando imagen...");
        Add("Imagem atualizada com sucesso.", "Artwork updated successfully.", "Imagen actualizada con éxito.");
        Add("Não foi possível atualizar a imagem agora.", "Could not update artwork right now.", "No se pudo actualizar la imagen ahora.");
        Add("Iniciando {0}...", "Launching {0}...", "Iniciando {0}...");
        Add("COCKPIT DE TELEMETRIA", "TELEMETRY COCKPIT", "CABINA DE TELEMETRÍA");
        Add("NENHUM JOGO LOCAL ENCONTRADO", "NO LOCAL GAMES FOUND", "NO SE ENCONTRARON JUEGOS LOCALES");
        Add("O LagCheck monitora seus jogos instalados (Steam, Epic, Xbox) ou sua rota geral.",
            "LagCheck checks your installed games (Steam, Epic, Xbox) or your general connection route.",
            "LagCheck monitorea tus juegos instalados (Steam, Epic, Xbox) o tu ruta general.");
        Add("Procurar jogos instalados", "Scan installed games", "Buscar juegos instalados");
        Add("Testar conexão geral", "Test general connection", "Probar conexión general");

        // -------------------------------------------------------------
        // 4. Biblioteca de Jogos (Library)
        // -------------------------------------------------------------
        Add("BIBLIOTECA", "LIBRARY", "BIBLIOTECA");
        Add("{0} JOGO", "{0} GAME", "{0} JUEGO");
        Add("{0} JOGOS", "{0} GAMES", "{0} JUEGOS");
        Add("Buscar na sua biblioteca (Ctrl+F)", "Search in your library (Ctrl+F)", "Buscar en tu biblioteca (Ctrl+F)");
        Add("Fazer varredura de launchers instalados", "Scan installed game launchers", "Escanear launchers instalados");
        Add("Procurar jogos", "Scan games", "Buscar juegos");
        Add("Varrendo launchers instalados...", "Scanning installed launchers...", "Escaneando launchers instalados...");
        Add("Varredura concluída.", "Scan completed.", "Escaneo completado.");
        Add("Ordenar: Nome A–Z", "Sort: Name A–Z", "Ordenar: Nombre A–Z");
        Add("Ordenar: Mais recentes", "Sort: Most recent", "Ordenar: Más recientes");
        Add("Ordenar: Plataforma", "Sort: Platform", "Ordenar: Plataforma");
        Add("Ordenar: Favoritos primeiro", "Sort: Favorites first", "Ordenar: Favoritos primero");
        Add("Todos os jogos", "All games", "Todos los juegos");
        Add("Instalados", "Installed", "Instalados");
        Add("PC local", "Local PC", "PC local");
        Add("Favoritos", "Favorites", "Favoritos");
        Add("Recentes", "Recent", "Recientes");
        Add("Nenhum jogo corresponde à busca ou ao filtro atual.", "No games match the current search or filter.", "Ningún juego coincide con la búsqueda o el filtro actual.");
        Add("NÃO INSTALADO", "NOT INSTALLED", "NO INSTALADO");
        Add("Conexão suportada", "Diagnostic supported", "Conexión admitida");
        Add("Conexão geral", "General connection", "Conexión general");
        Add("Offline / Sem medição", "Offline / No check", "Offline / Sin medición");
        Add("Sem diagnóstico", "No diagnostic", "Sin diagnóstico");

        // -------------------------------------------------------------
        // 5. Diagnóstico de Conexão e Métricas (DiagnosticPage)
        // -------------------------------------------------------------
        Add("DIAGNÓSTICO DE CONEXÃO", "CONNECTION DIAGNOSTIC", "DIAGNÓSTICO DE CONEXIÓN");
        Add("CONECTANDO", "CONNECTING", "CONECTANDO");
        Add("TODOS", "ALL", "TODOS");
        Add("INSTALADOS", "INSTALLED", "INSTALADOS");
        Add("RECENTES", "RECENT", "RECIENTES");
        Add("FAVORITOS", "FAVORITES", "FAVORITOS");
        Add("PC LOCAL", "LOCAL PC", "PC LOCAL");
        Add("DIAGNÓSTICO INDISPONÍVEL", "DIAGNOSTIC UNAVAILABLE", "DIAGNÓSTICO NO DISPONIBLE");
        Add("DIAGNÓSTICO HOMOLOGADO", "VERIFIED DIAGNOSTIC", "DIAGNÓSTICO HOMOLOGADO");
        Add("SEM DIAGNÓSTICO ONLINE", "NO ONLINE DIAGNOSTIC", "SIN DIAGNÓSTICO ONLINE");
        Add("CONEXÃO GERAL", "GENERAL CONNECTION", "CONEXIÓN GENERAL");
        Add("O motor local não concluiu a ação.", "Local engine did not complete the action.", "El motor local no completó la acción.");
        Add("Não foi possível ler a biblioteca local agora.", "Could not read local library right now.", "No se pudo leer la biblioteca local ahora.");
        Add("LATÊNCIA EM REPOUSO", "IDLE LATENCY", "LATENCIA EN REPOSO");
        Add("Testando servidores de menor latência…", "Testing lowest latency servers…", "Probando servidores de menor latencia…");
        Add("Medindo a resposta e os reflexos da sua conexão…", "Measuring ping and connection responsiveness…", "Midiendo la respuesta y reflejos de tu conexión…");
        Add("Simulando tráfego na rede para medir acréscimo de atraso…", "Simulating network traffic to measure latency increase…", "Simulando tráfico de red para medir incremento de retraso…");
        Add("Comparando os resultados com as exigências de jogo…", "Comparing results with game requirements…", "Comparando resultados con las exigencias del juego…");
        Add("Mais rápido até agora: {0} ({1:0} ms)", "Fastest so far: {0} ({1:0} ms)", "Más rápido hasta ahora: {0} ({1:0} ms)");
        Add("● Voz e chamadas: Bom · Sem cortes nem atraso.",
            "● Voice and chat: Good · Clean audio without cutoffs or delay.",
            "● Voz y chat: Bueno · Audio limpio sin cortes ni retraso.");
        Add("▲ Voz e chamadas: Atenção · Possível atraso em chamadas.",
            "▲ Voice and chat: Caution · Possible delay in calls.",
            "▲ Voz y chat: Atención · Posible retraso en llamadas.");
        Add("● Streaming ao vivo: Bom · Upload de {0} Mbps (1080p60).",
            "● Live streaming: Good · {0} Mbps upload (1080p60).",
            "● Transmisión en vivo: Bueno · Subida de {0} Mbps (1080p60).");
        Add("● NAT: Aberto ou moderado · Bom para partidas online.",
            "● NAT: Open or moderate · Good for online matches.",
            "● NAT: Abierto o moderado · Bueno para partidas online.");
        Add("— Medição inconclusiva", "— Inconclusive check", "— Medición inconclusa");
        Add("Não foi possível concluir", "Could not complete", "No se pudo completar");
        Add("{0} · Competitivo", "{0} · Competitive", "{0} · Competitivo");
        Add("CARGA", "LOAD", "CARGA");
        Add("ANALISANDO", "ANALYZING", "ANALIZANDO");
        Add("Varrendo servidores mais próximos…", "Scanning nearest servers…", "Buscando servidores más cercanos…");
        Add("● CONEXÃO   ● LATÊNCIA   ● SOB CARGA   ● ANÁLISE", "● CONNECTION   ● LATENCY   ● UNDER LOAD   ● ANALYSIS", "● CONEXIÓN   ● LATENCIA   ● BAJO CARGA   ● ANÁLISIS");
        Add("Varrendo regiões mundiais…", "Scanning global regions…", "Escaneando regiones mundiales…");
        Add("Medindo latência de repouso até os servidores…", "Measuring idle latency to servers…", "Midiendo latencia de reposo a los servidores…");
        Add("Testando estabilidade sob carga de download e upload…", "Testing stability under download and upload load…", "Probando estabilidad bajo carga de descarga y subida…");
        Add("Consolidando veredito e traçado de rota…", "Consolidating verdict and route trace…", "Consolidando veredicto y trazado de ruta…");
        Add("Medição cancelada.", "Check cancelled.", "Medición cancelada.");
        Add("Falha ao medir: verifique a conexão com a internet.", "Check failed: verify internet connection.", "Fallo al medir: comprueba tu conexión a internet.");
        Add("Teste agora", "Test now", "Probar ahora");
        Add("Cancelar", "Cancel", "Cancelar");
        Add("Testar novamente", "Test again", "Probar de nuevo");
        Add("Escolher outro jogo", "Choose another game", "Elegir otro juego");
        Add("RESPOSTA", "RESPONSE", "RESPUESTA");
        Add("JITTER", "JITTER", "JITTER");
        Add("SOB CARGA", "UNDER LOAD", "BAJO CARGA");
        Add("UPLOAD", "UPLOAD", "SUBIDA");
        Add("EVIDÊNCIA DE ROTA", "ROUTE EVIDENCE", "EVIDENCIA DE RUTA");
        Add("Traçado de rota ativa até o datacenter regional", "Active route trace to regional datacenter", "Trazado de ruta activa al datacenter regional");
        Add("VOZ, STREAMING E NAT", "VOICE, STREAMING AND NAT", "VOZ, STREAMING Y NAT");
        Add("ROTA ESTIMADA: {0}", "ESTIMATED ROUTE: {0}", "RUTA ESTIMADA: {0}");
        Add("● Bom · Latência e jitter baixos: voz sem cortes nem atraso.",
            "● Good · Low latency and jitter: clean voice with no cutoffs.",
            "● Bueno · Baja latencia y jitter: voz clara sin cortes ni retraso.");
        Add("● Bom · Upload estável para transmissão em 1080p60.",
            "● Good · Stable upload for 1080p60 streaming.",
            "● Bueno · Subida estable para streaming en 1080p60.");
        Add("● Aberto ou moderado · Bom para partidas online e chat.",
            "● Open or moderate · Good for online matches and voice chat.",
            "● Abierto o moderado · Bueno para partidas online y chat.");
        Add("▲ Atenção · Oscilação na rota pode causar cortes no Discord.",
            "▲ Caution · Route jitter may cause audio dropouts in Discord.",
            "▲ Atención · Oscilación en la ruta puede causar cortes en Discord.");
        Add("▲ Instável · Upload oscilou durante o teste: risco de perda de quadros.",
            "▲ Unstable · Upload dropped during check: risk of frame drops.",
            "▲ Inestable · Subida osciló durante la prueba: riesgo de pérdida de cuadros.");
        Add("▲ Restrito / Estrito · Pode dificultar entrar em lobbies ou salas de voz.",
            "▲ Strict NAT · May cause trouble joining lobbies or voice parties.",
            "▲ Estricto · Puede dificultar unirse a lobbies o salas de voz.");

        // -------------------------------------------------------------
        // 6. Histórico de Sessões (HistoryPage)
        // -------------------------------------------------------------
        Add("REGISTRO LOCAL", "LOCAL LOG", "REGISTRO LOCAL");
        Add("Histórico de Sessões", "Session History", "Historial de Sesiones");
        Add("Resultados concluídos ficam guardados apenas neste PC.", "Completed results are stored only on this PC.", "Los resultados completados se guardan solo en esta PC.");
        Add("Buscar por região ou veredito", "Search by region or verdict", "Buscar por región o veredicto");
        Add("Sem testes nesta sessão", "No tests in this session", "Sin pruebas en esta sesión");
        Add("Quando uma medição terminar pelo motor compartilhado, o resultado real aparece aqui.",
            "When a measurement finishes through the engine, the real result appears here.",
            "Cuando finalice una medición con el motor compartido, el resultado real aparecerá aquí.");
        Add("Nenhuma medição corresponde à busca.", "No measurements match the search.", "Ninguna medición coincide con la búsqueda.");
        Add("REGIÃO NÃO INFORMADA", "REGION NOT SPECIFIED", "REGIÓN NO ESPECIFICADA");

        // -------------------------------------------------------------
        // 7. Configurações e Ajustes (SettingsPage)
        // -------------------------------------------------------------
        Add("SISTEMA · CONFIGURAÇÕES", "SYSTEM · SETTINGS", "SISTEMA · CONFIGURACIÓN");
        Add("Ajustes do Launcher", "Launcher Settings", "Ajustes del Launcher");
        Add("Controle o comportamento da interface e diagnósticos de rede neste PC.",
            "Control interface behavior and network diagnostics on this PC.",
            "Controla el comportamiento de la interfaz y diagnósticos de red en esta PC.");
        Add("Conectando aos ajustes locais…", "Connecting to local settings…", "Conectando con los ajustes locales…");
        Add("Ajustes locais conectados.", "Local settings connected.", "Ajustes locales conectados.");
        Add("Ajustes indisponíveis: o host local não respondeu.", "Settings unavailable: local host did not respond.", "Ajustes no disponibles: el host local no respondió.");
        Add("Ajustes salvos neste PC.", "Settings saved on this PC.", "Ajustes guardados en esta PC.");
        Add("Não foi possível salvar os ajustes. Nada foi alterado.", "Could not save settings. Nothing was changed.", "No se pudieron guardar los ajustes. No se modificó nada.");

        // Idioma
        Add("Idioma do aplicativo", "App language", "Idioma de la aplicación");
        Add("Escolha o idioma da interface. Por padrão, segue as configurações do Windows.",
            "Choose interface language. By default, follows Windows settings.",
            "Elige el idioma de la interfaz. Por defecto, sigue la configuración de Windows.");
        Add("Sistema (Padrão)", "System (Default)", "Sistema (Predeterminado)");

        // Interface e Visual
        Add("Interface e Visual", "Interface and Visuals", "Interfaz y Visual");
        Add("Reduzir movimento", "Reduce motion", "Reducir movimiento");
        Add("Desativa animações e transições visuais para resposta imediata.",
            "Disables animations and visual transitions for immediate response.",
            "Desactiva animaciones y transiciones visuales para respuesta inmediata.");
        Add("Baixar imagens dos jogos", "Download game artwork", "Descargar imágenes de juegos");
        Add("Carrega capas e banners oficiais do cache local dos seus launchers. Desligado, usa miniaturas neutras.",
            "Loads official covers and banners from local launcher cache. Disabled, uses neutral thumbnails.",
            "Carga portadas y banners oficiales del caché local de tus launchers. Desactivado, usa miniaturas neutras.");

        // Privacidade e Rede
        Add("Privacidade e Rede", "Privacy and Network", "Privacidad y Red");
        Add("Localização aproximada", "Approximate location", "Ubicación aproximada");
        Add("Usa a cidade estimada pelo IP para traçar a rota geográfica. Nunca utiliza GPS.",
            "Uses estimated city by IP to plot geographical route. Never uses GPS.",
            "Usa la ciudad estimada por IP para trazar la ruta geográfica. Nunca usa GPS.");
        Add("Enviar estatísticas anônimas", "Send anonymous stats", "Enviar estadísticas anónimas");
        Add("Apenas veredito e rota da partida. Sem endereço IP, nome de rede ou identificador pessoal.",
            "Only match verdict and route. No IP address, network name or personal identifier.",
            "Solo veredicto y ruta de la partida. Sin dirección IP, nombre de red o identificador personal.");
        Add("Gerar novo ID local", "Generate new local ID", "Generar nuevo ID local");
        Add("Gerando um novo identificador local…", "Generating new local identifier…", "Generando un nuevo identificador local…");
        Add("Novo identificador gerado neste PC.", "New identifier generated on this PC.", "Nuevo identificador generado en esta PC.");
        Add("Não foi possível gerar um novo identificador agora.", "Could not generate new identifier right now.", "No se pudo generar un nuevo identificador ahora.");

        // Atualizações
        Add("Atualizações", "Updates", "Actualizaciones");
        Add("Verificar automaticamente", "Check automatically", "Verificar automáticamente");
        Add("Consulta periodicamente por novas versões no canal oficial do GitHub.",
            "Periodically checks for new versions on official GitHub channel.",
            "Consulta periódicamente nuevas versiones en el canal oficial de GitHub.");
        Add("Conectando ao atualizador local…", "Connecting to local updater…", "Conectando con el actualizador local…");
        Add("Verificar agora", "Check now", "Verificar ahora");
        Add("Verificando a fonte configurada…", "Checking configured source…", "Comprobando la fuente configurada…");
        Add("Nenhuma fonte de atualização está configurada.", "No update source is configured.", "No hay ninguna fuente de actualización configurada.");
        Add("Última verificação: {0}. ", "Last checked: {0}. ", "Última comprobación: {0}. ");
        Add("Ainda não verificado. ", "Not checked yet. ", "Aún no verificado. ");
        Add("Atualização {0} encontrada.", "Update {0} found.", "Actualización {0} encontrada.");
        Add("disponível", "available", "disponible");
        Add("Atualização pronta no host local.", "Update ready on local host.", "Actualización lista en el host local.");
        Add("Não foi possível verificar agora.", "Could not check right now.", "No se pudo verificar ahora.");
        Add("Nenhuma atualização disponível.", "No update available.", "No hay actualizaciones disponibles.");
        Add("Não foi possível consultar atualizações agora.", "Could not check for updates right now.", "No se pudo consultar actualizaciones ahora.");

        // Sobre
        Add("Sobre o LagCheck", "About LagCheck", "Acerca de LagCheck");
        Add("LagCheck para Windows — Launcher gamer com pre-flight check de rede integrado. Sem conta obrigatória e sem anúncios.",
            "LagCheck for Windows — Gamer launcher with built-in pre-flight network check. No account required, no ads.",
            "LagCheck para Windows — Launcher gamer con pre-flight check de red integrado. Sin cuenta obligatoria y sin anuncios.");
        Add("Versão v0.1.0 · WinUI 3 (x64) · Repositório Oficial",
            "Version v0.1.0 · WinUI 3 (x64) · Official Repository",
            "Versión v0.1.0 · WinUI 3 (x64) · Repositorio Oficial");

        // -------------------------------------------------------------
        // 8. Ficha do Jogo e Telas Auxiliares
        // -------------------------------------------------------------
        Add("Voltar", "Back", "Volver");
        Add("Voltar à tela anterior", "Go back to previous screen", "Volver a la pantalla anterior");
        Add("ATIVIDADE RECENTE", "RECENT ACTIVITY", "ACTIVIDAD RECIENTE");
        Add("DIAS JOGADOS", "DAYS PLAYED", "DÍAS JUGADOS");
        Add("Heatmap de atividade ativo localmente neste PC.", "Activity heatmap stored locally on this PC.", "Mapa de calor de actividad almacenado localmente en esta PC.");
        Add("Menos", "Less", "Menos");
        Add("Mais", "More", "Más");
        Add("PLATAFORMA", "PLATFORM", "PLATAFORMA");
        Add("REDE E DIAGNÓSTICO", "NETWORK & DIAGNOSTIC", "RED Y DIAGNÓSTICO");
        Add("HISTÓRICO DE MEDIÇÕES", "MEASUREMENT HISTORY", "HISTORIAL DE MEDICIONES");
        Add("Nenhuma medição registrada para este jogo nesta sessão.", "No measurements logged for this game in this session.", "Ninguna medición registrada para este juego en esta sesión.");
        Add("Medir agora", "Check now", "Medir ahora");

        Add("INTEGRAÇÃO LOCAL", "LOCAL INTEGRATION", "INTEGRACIÓN LOCAL");
        Add("Biblioteca em integração", "Library in integration", "Biblioteca en integración");
        Add("A leitura local dos jogos instalados ainda não foi conectada à interface WinUI. Nenhum jogo é exibido até a fonte real ficar disponível.",
            "Local reading of installed games has not yet been connected to WinUI. No games are displayed until real source is available.",
            "La lectura local de juegos instalados aún no se ha conectado a WinUI. No se muestra ningún juego hasta que la fuente real esté disponible.");
        Add("Diagnóstico indisponível", "Diagnostic unavailable", "Diagnóstico no disponible");
        Add("O motor compartilhado ainda não está conectado a esta interface. Nenhuma medição foi iniciada e nenhum resultado foi criado.",
            "Shared engine is not connected to this interface yet. No measurement was started and no result was created.",
            "El motor compartido aún no está conectado a esta interfaz. No se inició ninguna medición ni se creó ningún resultado.");

        Add("CATÁLOGO OFICIAL", "OFFICIAL CATALOG", "CATÁLOGO OFICIAL");
        Add("Catálogo de Jogos", "Games Catalog", "Catálogo de Juegos");
        Add("Escolha um contexto de diagnóstico quando a fonte local estiver disponível.",
            "Choose a diagnostic context when the local source is available.",
            "Elige un contexto de diagnóstico cuando la fuente local esté disponible.");
        Add("Buscar no catálogo", "Search catalog", "Buscar en el catálogo");
        Add("Catálogo indisponível", "Catalog unavailable", "Catálogo no disponible");
        Add("O catálogo local ainda não respondeu. Esta tela não inventa jogos, endpoints ou compatibilidade.",
            "Local catalog has not responded yet. This screen does not invent games, endpoints or compatibility.",
            "El catálogo local aún no respondió. Esta pantalla no inventa juegos, endpoints ni compatibilidad.");
        Add("Nenhum jogo no catálogo", "No games in catalog", "Ningún juego en el catálogo");
        Add("O catálogo local não retornou jogos compatíveis.", "Local catalog did not return compatible games.", "El catálogo local no devolvió juegos compatibles.");
        Add("TESTAR", "CHECK", "PROBAR");
        Add("Testar contexto do jogo", "Check game context", "Probar contexto del juego");
    }

    private static string GetConfigFilePath()
    {
        try
        {
            var folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "LagCheck");
            Directory.CreateDirectory(folder);
            return Path.Combine(folder, "ui_settings.json");
        }
        catch
        {
            return string.Empty;
        }
    }

    private void LoadPreference()
    {
        try
        {
            var file = GetConfigFilePath();
            if (!string.IsNullOrEmpty(file) && File.Exists(file))
            {
                var json = File.ReadAllText(file);
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("language", out var prop))
                {
                    _selectedLanguage = AppLanguageExtensions.FromCode(prop.GetString());
                }
            }
        }
        catch
        {
            _selectedLanguage = AppLanguage.System;
        }
    }

    private void SavePreference()
    {
        try
        {
            var file = GetConfigFilePath();
            if (string.IsNullOrEmpty(file)) return;

            var json = JsonSerializer.Serialize(new { language = _selectedLanguage.Code() });
            File.WriteAllText(file, json);
        }
        catch
        {
            // Fallback silencioso seguro se permissão de I/O falhar
        }
    }
}
