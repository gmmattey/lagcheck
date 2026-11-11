package com.lagcheck.desktop.library.launcher

import com.lagcheck.desktop.library.model.PcGame
import java.awt.Desktop
import java.io.File
import java.net.URI

sealed interface GameLaunchResult {
    data class Success(val message: String, val process: Process? = null) : GameLaunchResult
    data class Failure(val reason: String) : GameLaunchResult
}

object GameRunner {
    fun launch(game: PcGame): GameLaunchResult {
        // 1. Tentar iniciar via URI de protocolo de launcher (Steam, Epic, Xbox)
        val uri = game.launchUri
        if (!uri.isNullOrBlank()) {
            return launchUri(uri, game.title)
        }

        // 2. Tentar executar binário diretamente se disponível
        val exe = game.executablePath
        if (!exe.isNullOrBlank()) {
            val file = File(exe)
            if (file.exists()) {
                return try {
                    val process = ProcessBuilder(file.absolutePath)
                        .directory(file.parentFile)
                        .start()
                    GameLaunchResult.Success("Jogo iniciado com sucesso: ${game.title}", process)
                } catch (e: Exception) {
                    GameLaunchResult.Failure("Falha ao executar o binário (${e.message})")
                }
            }
        }

        return GameLaunchResult.Failure("Nenhum caminho ou protocolo de execução encontrado para este jogo.")
    }

    private fun launchUri(uriString: String, title: String): GameLaunchResult {
        return try {
            val os = System.getProperty("os.name").lowercase()
            when {
                os.contains("win") -> {
                    // No Windows, usar cmd /c start "" "uri" é mais robusto para protocolos customizados
                    ProcessBuilder("cmd", "/c", "start", "", uriString).start()
                    GameLaunchResult.Success("Solicitação de abertura enviada ao launcher: $title")
                }
                os.contains("mac") -> {
                    ProcessBuilder("open", uriString).start()
                    GameLaunchResult.Success("Solicitação de abertura enviada: $title")
                }
                else -> {
                    if (Desktop.isDesktopSupported() && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
                        Desktop.getDesktop().browse(URI.create(uriString))
                        GameLaunchResult.Success("Solicitação de abertura enviada: $title")
                    } else {
                        ProcessBuilder("xdg-open", uriString).start()
                        GameLaunchResult.Success("Solicitação de abertura enviada: $title")
                    }
                }
            }
        } catch (e: Exception) {
            GameLaunchResult.Failure("Não foi possível acionar o launcher para $title (${e.message})")
        }
    }
}
