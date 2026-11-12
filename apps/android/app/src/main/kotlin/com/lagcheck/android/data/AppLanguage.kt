package com.lagcheck.android.data

import com.lagcheck.domain.presentation.ReadinessLanguage

/** Idioma escolhido em Ajustes ("Português (Brasil)", "English", "Español"). Qualquer outro valor cai em PT-BR. */
fun String.toAppLanguage(): ReadinessLanguage = when {
    contains("English", ignoreCase = true) -> ReadinessLanguage.EN
    contains("Español", ignoreCase = true) || contains("Espanol", ignoreCase = true) -> ReadinessLanguage.ES
    else -> ReadinessLanguage.PT_BR
}
