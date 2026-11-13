package com.lagcheck.domain.presentation

import java.util.Locale

/**
 * Tradução da interface do app. A chave é o próprio texto em PT-BR (o idioma de origem). O app chama `tr("texto")`.
 * Se faltar tradução, devolve o PT: a tela nunca fica em branco nem mostra uma chave técnica.
 * Um teste varre o código do app e falha se algum `tr("...")` não tiver EN e ES aqui.
 * Tom: `docs/07-voz-do-produto.md`. Textos curtos, sem jargão, sem promessa.
 */
object UiStrings {
    private class Entry(val en: String, val es: String)

    private val table = HashMap<String, Entry>()

    private fun t(pt: String, en: String, es: String) {
        require(pt !in table) { "tradução duplicada: $pt" }
        table[pt] = Entry(en, es)
    }

    fun translate(pt: String, language: ReadinessLanguage): String {
        val e = table[pt] ?: return pt
        return when (language) {
            ReadinessLanguage.PT_BR -> pt
            ReadinessLanguage.EN -> e.en
            ReadinessLanguage.ES -> e.es
        }
    }

    /** Texto com `%s`/`%d`/`%.0f`. Formata com `Locale.ROOT` para o ponto decimal não variar com o aparelho. */
    fun translateFormat(pt: String, language: ReadinessLanguage, vararg args: Any?): String =
        String.format(Locale.ROOT, translate(pt, language), *args)

    /** Textos que têm tradução (para o teste de completude e para checar placeholders). */
    fun keys(): Set<String> = table.keys

    fun has(pt: String): Boolean = pt in table
    fun entry(pt: String, language: ReadinessLanguage): String? = table[pt]?.let { if (language == ReadinessLanguage.EN) it.en else it.es }

    init {
        // region Compartilhar por ícones (Decisão 81)
        t("Link", "Link", "Enlace")
        t("Stories", "Stories", "Stories")
        t("Vídeo", "Video", "Video")
        t("Mais apps", "More apps", "Más apps")
        t("Legenda e hashtags copiadas. Cole no post.", "Caption and hashtags copied. Paste into your post.", "Leyenda y hashtags copiados. Pégalos en tu publicación.")
        // endregion

        // region Ícone do app (Decisão 83)
        t("Ícone do app", "App icon", "Ícono de la app")
        t("O launcher atualiza em alguns segundos.", "The launcher updates in a few seconds.", "El launcher se actualiza en unos segundos.")
        t("Clássico", "Classic", "Clásico")
        t("Joinha", "Thumbs up", "Pulgar arriba")
        t("Piscadinha", "Wink", "Guiño")
        t("Comemorando", "Cheering", "Celebrando")
        t("Glifo roxo", "Purple glyph", "Glifo morado")
        t("Mascote", "Mascot", "Mascota")
        // endregion

        // region Anúncios (Decisão 82)
        t("Anúncio", "Ad", "Anuncio")
        t("Opções de privacidade", "Privacy options", "Opciones de privacidad")
        // endregion

        // region Histórico (protótipo Android, Decisão 80)
        t("Confirmando referência regional…", "Confirming regional reference…", "Confirmando referencia regional…")
        t("Sem rota viável", "No viable route", "Sin ruta viable")
        t("O LagCheck não conseguiu resposta das rotas de referência para sua região.", "LagCheck didn't get a response from the reference routes for your region.", "LagCheck no obtuvo respuesta de las rutas de referencia para tu región.")
        t("Voltar para o Início", "Back to Home", "Volver al Inicio")
        t("checks", "checks", "checks")
        t("Configurações", "Settings", "Configuración")
        t("Lembrete pré-partida", "Pre-match reminder", "Recordatorio antes de jugar")
        t("Escolha um jogo para ativar.", "Pick a game to enable it.", "Elige un juego para activarlo.")
        t("Todos os dias às %02d:%02d · %s", "Every day at %02d:%02d · %s", "Todos los días a las %02d:%02d · %s")
        t("Horário", "Time", "Hora")
        t("Abrir ajustes do aparelho", "Open device settings", "Abrir ajustes del dispositivo")
        t("jogos", "games", "juegos")
        t("1 check", "1 check", "1 check")
        t("%d checks", "%d checks", "%d checks")
        t("prontos p/ Ranked", "Ranked-ready", "listos p/ Ranked")
        t("Últimos %d dias", "Last %d days", "Últimos %d días")
        t("Pronto em %d de %d checks", "Ready in %d of %d checks", "Listo en %d de %d checks")
        t("Instável: %d · Evitaria: %d · Inconclusivos: %d", "Unstable: %d · Avoid: %d · Inconclusive: %d", "Inestable: %d · Evitaría: %d · No concluyentes: %d")
        // endregion

        // region Cockpit (Dados da Rede)
        t("Fechar", "Close", "Cerrar")
        t("Dados da Rede", "Network Data", "Datos de la Red")
        t("Conexão", "Connection", "Conexión")
        t("Wi-Fi", "Wi-Fi", "Wi-Fi")
        t("Dados móveis", "Mobile data", "Datos móviles")
        t("Ethernet", "Ethernet", "Ethernet")
        t("Banda", "Band", "Banda")
        t("Frequência", "Frequency", "Frecuencia")
        t("Sinal (RSSI)", "Signal (RSSI)", "Señal (RSSI)")
        t("Velocidade do link", "Link speed", "Velocidad del enlace")
        t("Gateway", "Gateway", "Gateway")
        t("Latência do roteador", "Router latency", "Latencia del router")
        t("Sem resposta", "No response", "Sin respuesta")
        t("Medindo…", "Measuring…", "Midiendo…")
        t("Não disponível", "Not available", "No disponible")
        t("Tipo de NAT", "NAT type", "Tipo de NAT")
        t("CGNAT", "CGNAT", "CGNAT")
        t("NAT duplo", "Double NAT", "NAT doble")
        t("Detectado", "Detected", "Detectado")
        t("Suspeito", "Suspected", "Sospechado")
        t("Não detectado", "Not detected", "No detectado")
        t("Inconclusivo", "Inconclusive", "No concluyente")
        t("Voz (Discord)", "Voice chat (Discord)", "Voz (Discord)")
        t("Favorável · roteador %d ms", "Good · router %d ms", "Favorable · router %d ms")
        t("Atenção · roteador %d ms", "Heads up · router %d ms", "Atención · router %d ms")
        t("Não avaliado", "Not assessed", "No evaluado")
        t("CONEXÃO LOCAL", "LOCAL CONNECTION", "CONEXIÓN LOCAL")
        t("BORDA DA REDE", "NETWORK EDGE", "BORDE DE LA RED")
        t("VOZ", "VOICE", "VOZ")
        t("Copiar dados da rede", "Copy network data", "Copiar datos de la red")
        t("Dados da rede copiados!", "Network data copied!", "¡Datos de la red copiados!")
        t("Exportar Dados da Rede", "Export Network Data", "Exportar Datos de la Red")
        t("LagCheck - Dados da Rede", "LagCheck - Network Data", "LagCheck - Datos de la Red")
        t("Medido agora no aparelho. O que não foi medido aparece como —.", "Measured on this device right now. Anything not measured shows —.", "Medido ahora en el dispositivo. Lo que no se midió aparece como —.")
        t("IP Local", "Local IP", "IP Local")
        t("IP Público", "Public IP", "IP Público")
        t("Atualizar", "Refresh", "Actualizar")
        t("Compartilhar", "Share", "Compartir")
        t("Cloud Gaming", "Cloud Gaming", "Cloud Gaming")
        t("Multiplayer", "Multiplayer", "Multijugador")
        t("Live Stream", "Live Stream", "Transmisión en vivo")
        t("CASOS DE USO", "USE CASES", "CASOS DE USO")
        t("Atenção · NAT restrito", "Heads up · Strict NAT", "Atención · NAT estricta")
        t("Atenção · Duplo NAT", "Heads up · Double NAT", "Atención · NAT doble")
        t("Favorável · NAT ok, roteador %d ms", "Good · NAT ok, router %d ms", "Favorable · NAT ok, router %d ms")
        t("Atenção · 2.4 GHz detectado", "Heads up · 2.4 GHz detected", "Atención · 2.4 GHz detectado")
        t("Favorável · 5 GHz, roteador %d ms", "Good · 5 GHz, router %d ms", "Favorable · 5 GHz, router %d ms")
        // endregion

        // region Relatório em PDF e Favoritos
        t("Estimativa da rota até a infraestrutura de referência. Não é o ping real do jogo.", "Estimate of the route to the reference infrastructure. Not the game's real ping.", "Estimación de la ruta hasta la infraestructura de referencia. No es el ping real del juego.")
        t("Gerado em %s", "Generated on %s", "Generado el %s")
        t("Não deu para gerar o relatório.", "Couldn't generate the report.", "No se pudo generar el informe.")
        t("FAVORITOS", "FAVORITES", "FAVORITOS")
        t("Favoritar", "Add to favorites", "Agregar a favoritos")
        t("Remover dos favoritos", "Remove from favorites", "Quitar de favoritos")
        t("RECENTES", "RECENT", "RECIENTES")
        t("TODOS OS JOGOS A–Z", "ALL GAMES A–Z", "TODOS LOS JUEGOS A–Z")
        t("Nenhum jogo encontrado", "No games found", "No se encontraron juegos")
        t("Fazer Check de %s", "Run Check for %s", "Hacer Check de %s")
        t("Fechar busca", "Close search", "Cerrar búsqueda")
        // endregion

        // region Status das redes de console
        t("%s com instabilidade", "%s Experiencing Issues", "%s con problemas")
        t("%s fora do ar", "%s Service Outage", "%s fuera de servicio")
        t("Pode haver lentidão ou dificuldade temporária para entrar em partidas online.", "You may experience delays or matchmaking issues until services normalize.", "Puede haber lentitud o dificultades temporales para ingresar a partidas online.")
        t("Os servidores de login e multiplayer estão passando por interrupções no momento.", "Online sign-in and multiplayer servers are currently experiencing interruptions.", "Los servidores de inicio de sesión y multijugador están experimentando interrupciones en este momento.")
        t("Fora do ar", "Outage", "Fuera de servicio")
        t("Afeta: %s", "Affects: %s", "Afecta a: %s")
        // endregion

        // region Cards e vídeo de compartilhamento (Decisão 80)
        t("Resposta", "Response", "Respuesta")
        t("Jitter", "Jitter", "Jitter")
        t("Check · %s", "Check · %s", "Check · %s")
        t("Check", "Check", "Check")
        t("Medido com pacotes UDP reais.", "Measured with real UDP packets.", "Medido con paquetes UDP reales.")
        t("Teste a sua conexão no Lagcheck.", "Test your connection on Lagcheck.", "Prueba tu conexión en Lagcheck.")
        t("Escolha seu jogo.", "Pick your game.", "Elige tu juego.")
        t("Procurando o servidor mais próximo…", "Finding the nearest server…", "Buscando el servidor más cercano…")
        t("Testando os reflexos da sua rede.", "Testing your network’s reflexes.", "Probando los reflejos de tu red.")
        t("Cada milissegundo conta em %s.", "Every millisecond counts in %s.", "Cada milisegundo cuenta en %s.")
        t("Enchendo a fila para ver se aguenta a pressão.", "Filling the queue to see if it holds under pressure.", "Llenando la cola para ver si aguanta la presión.")
        t("Quase lá. Preparando seu veredito.", "Almost there. Preparing your verdict.", "Casi listo. Preparando tu veredicto.")
        t("Cards e vídeo para as redes", "Cards and video for social", "Tarjetas y video para redes")
        t("Gere um card ou um vídeo com o seu resultado. Só os números medidos aparecem.", "Create a card or a video with your result. Only measured numbers appear.", "Crea una tarjeta o un video con tu resultado. Solo aparecen los números medidos.")
        t("Card 1200×630 (WhatsApp, Telegram, X)", "1200×630 card (WhatsApp, Telegram, X)", "Tarjeta 1200×630 (WhatsApp, Telegram, X)")
        t("Card 1080×1920 (Status, Stories, TikTok)", "1080×1920 card (Status, Stories, TikTok)", "Tarjeta 1080×1920 (Estados, Stories, TikTok)")
        t("Vídeo 9:16 para TikTok e Reels", "9:16 video for TikTok and Reels", "Video 9:16 para TikTok y Reels")
        t("Gerando o vídeo…", "Creating the video…", "Creando el video…")
        t("Não foi possível gerar o arquivo. Tente de novo.", "Could not create the file. Try again.", "No se pudo crear el archivo. Inténtalo de nuevo.")
        t("Testei minha conexão para jogar %s no Lagcheck. Teste a sua: https://lagcheck.signallq.com", "I tested my connection to play %s on Lagcheck. Test yours: https://lagcheck.signallq.com", "Probé mi conexión para jugar %s en Lagcheck. Prueba la tuya: https://lagcheck.signallq.com")
        // endregion

        // region Home Cockpit e Gauge (Decisão 113)
        t("TESTAR", "TEST", "PROBAR")
        t("MEDINDO...", "MEASURING...", "MIDIENDO...")
        t("TESTAR POR JOGO", "TEST BY GAME", "PROBAR POR JUEGO")
        t("Ver todos", "See all", "Ver todos")
        t("Adicionar", "Add", "Añadir")
        t("1 toque ▸", "1 tap ▸", "1 toque ▸")
        // endregion

        // region Duelo de Host (Decisão 112)
        t("DUELO DE HOST", "HOST DUEL", "DUELO DE HOST")
        t("Quem puxa a ranked?", "Who hosts the lobby?", "¿Quién crea la sala?")
        t("Seu Duo", "Your Duo", "Tu Dúo")
        t("%s quer decidir quem cria a sala no lobby.", "%s wants to decide who hosts the ranked lobby.", "%s quiere decidir quién crea la sala en el lobby.")
        t("Válido por mais %d min", "Valid for %d more min", "Válido por %d min más")
        t("Regra de host v1", "Host rule v1", "Regla de host v1")
        t("Aceitar e Medir Minha Rota", "Accept & Measure My Route", "Aceptar y Medir Mi Ruta")
        t("Recusar Desafio", "Decline Challenge", "Rechazar Duelo")
        t("SEU NICK NO LOBBY", "YOUR LOBBY NICK", "TU NICK EN EL LOBBY")
        t("Como quer aparecer no duelo?", "What is your gamer tag?", "¿Cómo quieres aparecer en el duelo?")
        t("Fica salvo só no seu aparelho. Sem conta, sem login.", "Saved only on your device. No account, no login.", "Guardado solo en tu dispositivo. Sin cuenta ni login.")
        t("Ex: Luiz, FalleN, Coringa", "E.g. Luiz, Shroud, TenZ", "Ej: Luiz, FalleN, Ibai")
        t("Gerar Desafio", "Create Challenge", "Crear Duelo")
        t("VEREDITO DO LOBBY", "LOBBY VERDICT", "VEREDICTO DEL LOBBY")
        t("HOST OFICIAL", "OFFICIAL HOST", "HOST OFICIAL")
        t("Você", "You", "Tú")
        t("Desafiante", "Challenger", "Desafiante")
        t("Expira em %d min", "Expires in %d min", "Expira en %d min")
        t("Duelo 1v1 • Regra de host v1", "1v1 Duel • Host rule v1", "Duelo 1v1 • Regla de host v1")
        t("Copiar Veredito pro Discord", "Copy Verdict for Discord", "Copiar Veredicto para Discord")
        t("Veredito copiado para a call do Discord!", "Verdict copied for Discord call!", "¡Veredicto copiado para la llamada de Discord!")
        t("Compartilhar Link do Duelo", "Share Duel Link", "Compartir Enlace del Duelo")
        t("Compartilhar Duelo de Host", "Share Host Duel", "Compartir Duelo de Host")
        t("Voltar ao Início", "Back to Home", "Volver al Inicio")
        t("Desafiar Duo no Lobby", "Challenge Duo in Lobby", "Desafiar al Dúo en el Lobby")
        t("Ver Confronto do Duelo", "View Duel Matchup", "Ver Enfrentamiento del Duelo")
        t("PRONTO", "READY", "LISTO")
        t("INSTÁVEL", "UNSTABLE", "INESTABLE")
        t("EVITAR", "AVOID", "EVITAR")
        t("INCONCLUSIVO", "INCONCLUSIVE", "INCONCLUSO")
        // endregion

        for ((pt, en, es) in SCREEN_STRINGS) t(pt, en, es)
    }
}
