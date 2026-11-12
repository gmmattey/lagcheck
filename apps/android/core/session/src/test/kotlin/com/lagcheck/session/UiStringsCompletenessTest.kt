package com.lagcheck.session

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.presentation.ReadinessLanguage
import com.lagcheck.domain.presentation.UiStrings
import java.io.File
import org.junit.Test

/**
 * Garante EN e ES para todo texto da interface sem precisar compilar o app: varre o código-fonte do `:app` atrás de
 * `tr("...")`/`trf("...")` e exige tradução (e placeholders iguais) para cada um.
 */
class UiStringsCompletenessTest {
    private val root: File = generateSequence(File(System.getProperty("user.dir")).absoluteFile) { it.parentFile }
        .first { File(it, "android/app/src/main").exists() }

    private val callRegex = Regex("""\btrf?\(\s*"((?:[^"\\]|\\.)*)"""")

    private fun unescape(s: String) = s.replace("\\\"", "\"").replace("\\n", "\n").replace("\\\\", "\\").replace("\\$", "$")

    private val used: Map<String, List<String>> by lazy {
        val map = HashMap<String, MutableList<String>>()
        File(root, "android/app/src/main").walkTopDown().filter { it.extension == "kt" }.forEach { f ->
            callRegex.findAll(f.readText()).forEach { m -> map.getOrPut(unescape(m.groupValues[1])) { mutableListOf() }.add(f.name) }
        }
        map
    }

    private val placeholder = Regex("%(?:\\.\\d+)?[sdf%]")
    private fun placeholders(s: String) = placeholder.findAll(s).map { it.value }.toList()

    @Test fun theScanActuallyFindsTheScreensTexts() {
        assertThat(used.size).isGreaterThan(100)
    }

    @Test fun everyTextUsedByTheAppHasEnglishAndSpanish() {
        val missing = used.keys.filterNot { UiStrings.has(it) }
        assertThat(missing).isEmpty()
    }

    @Test fun translationsKeepTheSamePlaceholders() {
        for (pt in UiStrings.keys()) {
            val ph = placeholders(pt)
            for (lang in listOf(ReadinessLanguage.EN, ReadinessLanguage.ES)) {
                assertThat(placeholders(UiStrings.entry(pt, lang)!!)).containsExactlyElementsIn(ph)
            }
        }
    }

    @Test fun noTranslationIsBlankAndNonTrivialTextsActuallyChange() {
        for (pt in UiStrings.keys()) {
            for (lang in listOf(ReadinessLanguage.EN, ReadinessLanguage.ES)) assertThat(UiStrings.entry(pt, lang)!!.trim()).isNotEmpty()
        }
        // Frases longas em PT não podem ter ficado iguais em EN (traduzir de verdade, não copiar).
        for (pt in UiStrings.keys().filter { it.length > 24 && ' ' in it }) {
            assertThat(UiStrings.entry(pt, ReadinessLanguage.EN)).isNotEqualTo(pt)
        }
    }

    @Test fun missingTranslationFallsBackToPortugueseNeverToAKey() {
        assertThat(UiStrings.translate("texto que não existe", ReadinessLanguage.EN)).isEqualTo("texto que não existe")
        assertThat(UiStrings.translate("Fechar", ReadinessLanguage.EN)).isEqualTo("Close")
        assertThat(UiStrings.translateFormat("%d min atrás", ReadinessLanguage.ES, 5)).isEqualTo("hace 5 min")
        assertThat(UiStrings.translateFormat("%.1f%% perda", ReadinessLanguage.EN, 0.4)).isEqualTo("0.4% loss")
    }

    @Test fun portugueseIsReturnedUntouched() {
        for (pt in UiStrings.keys()) assertThat(UiStrings.translate(pt, ReadinessLanguage.PT_BR)).isEqualTo(pt)
    }

    @Test fun noLeftoverHardcodedPortugueseInUiTextCalls() {
        // Textos de tela ainda soltos (text = "..." com letras) são o que o teste de completude não enxerga.
        val loose = Regex("""\b(?:text|title|label|subtext|detail|status|placeholder|contentDescription) = "([^"$]*[A-Za-zÀ-ú]{3,}[^"$]*)"|\bText\("([^"$]*[A-Za-zÀ-ú]{3,}[^"$]*)"""")
        val allowedBrand = setOf("Discord", "WhatsApp", "lagcheck", "Wi-Fi", "PS5", "…", "Lagcheck Score", "Jitter", "Mobile", "PlayStation", "Xbox", "Nintendo", "PC", "Ethernet")
        val offenders = mutableListOf<String>()
        File(root, "android/app/src/main/kotlin").walkTopDown().filter { it.extension == "kt" }.forEach { f ->
            f.readLines().forEachIndexed { i, line ->
                if (line.trimStart().startsWith("//") || line.trimStart().startsWith("*")) return@forEachIndexed
                loose.findAll(line).forEach { m ->
                    val text = m.groupValues[1].ifEmpty { m.groupValues[2] }
                    if (text !in allowedBrand && !text.startsWith("mailto") && !text.startsWith("http")) offenders += "${f.name}:${i + 1} -> $text"
                }
            }
        }
        assertThat(offenders).isEmpty()
    }
}
