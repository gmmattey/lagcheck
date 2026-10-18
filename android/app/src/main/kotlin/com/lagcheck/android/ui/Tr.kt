package com.lagcheck.android.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.domain.presentation.UiStrings

/**
 * Idioma ativo da interface. É estado do Compose: ler `tr(...)` dentro de um @Composable assina a mudança e a tela
 * recompõe sozinha quando a pessoa troca o idioma em Ajustes.
 */
object AppLocale {
    var language by mutableStateOf(ReadinessLanguage.PT_BR)

    /** Locale de data e hora do idioma escolhido: inglês nos EUA mostra 3:45 PM, não 15:45. */
    val javaLocale: java.util.Locale
        get() = when (language) {
            ReadinessLanguage.PT_BR -> java.util.Locale.forLanguageTag("pt-BR")
            ReadinessLanguage.ES -> java.util.Locale.forLanguageTag("es")
            ReadinessLanguage.EN ->
                java.util.Locale.getDefault().takeIf { it.language == "en" } ?: java.util.Locale.US
        }

    /** Hora curta no formato da região (12 h ou 24 h). */
    fun clock(timestamp: Long): String =
        java.text.DateFormat.getTimeInstance(java.text.DateFormat.SHORT, javaLocale).format(java.util.Date(timestamp))

    /** Dia e hora curtos, ex.: "Oct 18 · 3:45 PM" ou "18 de out. · 15:45". */
    fun dayAndClock(timestamp: Long): String {
        val pattern = android.text.format.DateFormat.getBestDateTimePattern(javaLocale, "dMMM")
        return java.text.SimpleDateFormat(pattern, javaLocale).format(java.util.Date(timestamp)) + " · " + clock(timestamp)
    }

    /** Data e hora do relatório, na ordem da região (EUA: mês primeiro). */
    fun dateTime(timestamp: Long): String =
        java.text.DateFormat.getDateTimeInstance(java.text.DateFormat.MEDIUM, java.text.DateFormat.SHORT, javaLocale)
            .format(java.util.Date(timestamp))
}

/** Texto da interface. A chave é o texto em PT-BR; sem tradução, aparece o PT-BR (nunca uma chave técnica). */
fun tr(pt: String): String = UiStrings.translate(pt, AppLocale.language)

/** Texto com `%s`/`%d`/`%.0f`. */
fun trf(pt: String, vararg args: Any?): String = UiStrings.translateFormat(pt, AppLocale.language, *args)
