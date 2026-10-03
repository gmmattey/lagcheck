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
        // endregion

        // region Status das redes de console
        t("%s com instabilidade", "%s Experiencing Issues", "%s con problemas")
        t("%s fora do ar", "%s Service Outage", "%s fuera de servicio")
        t("Pode haver lentidão ou dificuldade temporária para entrar em partidas online.", "You may experience delays or matchmaking issues until services normalize.", "Puede haber lentitud o dificultades temporales para ingresar a partidas online.")
        t("Os servidores de login e multiplayer estão passando por interrupções no momento.", "Online sign-in and multiplayer servers are currently experiencing interruptions.", "Los servidores de inicio de sesión y multijugador están experimentando interrupciones en este momento.")
        t("Fora do ar", "Outage", "Fuera de servicio")
        t("Afeta: %s", "Affects: %s", "Afecta a: %s")
        // endregion

        for ((pt, en, es) in SCREEN_STRINGS) t(pt, en, es)
    }
}
