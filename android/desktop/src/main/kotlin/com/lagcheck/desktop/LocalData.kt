package com.lagcheck.desktop

import java.nio.file.Files
import java.nio.file.Path

/** Dados locais do protótipo; não entram no repositório nem acompanham a medição. */
object LocalData {
    val directory: Path by lazy {
        val base = System.getenv("APPDATA")?.takeIf { it.isNotBlank() }
            ?: System.getProperty("user.home")
        Files.createDirectories(Path.of(base, "LagCheck"))
    }
}
