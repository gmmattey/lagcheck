package com.lagcheck.desktop.library.repository

import com.lagcheck.desktop.LocalData
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.util.Properties

/**
 * Preferências do usuário sobre a biblioteca: favoritos e último início pelo LagCheck.
 * Fica em arquivo próprio e é independente dos jogos encontrados, então um launcher fora do ar
 * nunca apaga nada daqui.
 */
class LibraryStore(private val file: Path, private val legacyFile: Path? = null) {

    data class Snapshot(
        val favorites: Set<String> = emptySet(),
        val lastLaunched: Map<String, Long> = emptyMap(),
    )

    fun load(): Snapshot {
        if (Files.exists(file)) return readCurrent()
        // Migração: a versão anterior guardava só favoritos, uma linha "fav:<id>" por jogo.
        // O arquivo antigo é preservado.
        val legacy = legacyFile?.takeIf { Files.exists(it) } ?: return Snapshot()
        val favorites = runCatching {
            Files.readAllLines(legacy).filter { it.startsWith(LEGACY_PREFIX) }
                .map { it.removePrefix(LEGACY_PREFIX).trim() }.filter { it.isNotEmpty() }.toSet()
        }.getOrDefault(emptySet())
        val migrated = Snapshot(favorites = favorites)
        if (favorites.isNotEmpty()) save(migrated)
        return migrated
    }

    /** Falha de escrita nunca derruba a interface: devolve false. */
    fun save(snapshot: Snapshot): Boolean = runCatching {
        val props = Properties()
        snapshot.favorites.forEach { props.setProperty(FAV + it, "1") }
        snapshot.lastLaunched.forEach { (id, at) -> props.setProperty(LAUNCHED + id, at.toString()) }
        file.parent?.let { Files.createDirectories(it) }
        val tmp = file.resolveSibling(file.fileName.toString() + ".tmp")
        Files.newOutputStream(tmp).use { props.store(it, null) }
        Files.move(tmp, file, StandardCopyOption.REPLACE_EXISTING)
        true
    }.getOrDefault(false)

    private fun readCurrent(): Snapshot = runCatching {
        val props = Properties().apply { Files.newInputStream(file).use { load(it) } }
        val favorites = props.stringPropertyNames().filter { it.startsWith(FAV) }.map { it.removePrefix(FAV) }.toSet()
        val launched = props.stringPropertyNames().filter { it.startsWith(LAUNCHED) }.mapNotNull { key ->
            props.getProperty(key).toLongOrNull()?.let { key.removePrefix(LAUNCHED) to it }
        }.toMap()
        Snapshot(favorites, launched)
    }.getOrDefault(Snapshot())

    companion object {
        private const val FAV = "fav."
        private const val LAUNCHED = "launched."
        private const val LEGACY_PREFIX = "fav:"

        fun default(): LibraryStore = LibraryStore(
            file = LocalData.directory.resolve("library-state.properties"),
            legacyFile = Path.of(System.getProperty("user.home"), ".lagcheck", "orbit_prefs.properties"),
        )
    }
}
