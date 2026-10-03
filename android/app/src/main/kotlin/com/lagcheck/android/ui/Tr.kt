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
}

/** Texto da interface. A chave é o texto em PT-BR; sem tradução, aparece o PT-BR (nunca uma chave técnica). */
fun tr(pt: String): String = UiStrings.translate(pt, AppLocale.language)

/** Texto com `%s`/`%d`/`%.0f`. */
fun trf(pt: String, vararg args: Any?): String = UiStrings.translateFormat(pt, AppLocale.language, *args)
