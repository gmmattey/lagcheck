package com.lagcheck.domain.model

import com.lagcheck.domain.util.parseUri
import com.lagcheck.domain.util.urlDecode

sealed class AppDeepLink {
    data class QuickCheck(val gameID: String?, val platform: String?) : AppDeepLink()
    object NetworkCockpit : AppDeepLink()
    object GamesCatalog : AppDeepLink()
    object Home : AppDeepLink()
    data class HostDuel(val payload: HostDuelPayload) : AppDeepLink()
}

object DeepLinkParser {

    fun parse(uriString: String): AppDeepLink? {
        // 0. Duelo de Host (Decisão 112)
        val duel = HostDuelPayload.parse(uriString)
        if (duel != null) {
            return AppDeepLink.HostDuel(duel)
        }

        val uri = parseUri(uriString) ?: return null

        val scheme = uri.scheme?.lowercase() ?: return null
        if (scheme != "lagcheck" && scheme != "https") {
            return null
        }

        val host = uri.host?.lowercase().orEmpty()
        val path = uri.path?.lowercase().orEmpty()

        if (scheme == "https") {
            if (host != "lagcheck.signallq.com") {
                return null
            }
        }

        val rawQuery = uri.rawQuery.orEmpty()
        val params = rawQuery.split("&").filter { it.contains("=") }.associate {
            val parts = it.split("=", limit = 2)
            val key = urlDecode(parts[0]).lowercase()
            val value = urlDecode(parts.getOrElse(1) { "" })
            key to value
        }

        val gameParam = params["game"] ?: params["gameid"]
        val rawPlatform = params["platform"]?.lowercase()
        val validPlatforms = setOf("iphone", "mobile", "pc", "playstation", "xbox", "nintendo")
        val platformParam = if (rawPlatform != null && validPlatforms.contains(rawPlatform)) rawPlatform else null

        return when {
            host == "quicktest" || host == "test" || host == "check" ||
                    path == "/quicktest" || path == "/test" || path == "/check" -> {
                AppDeepLink.QuickCheck(gameParam, platformParam)
            }
            host == "games" || host == "catalog" || path == "/games" || path == "/catalog" -> {
                AppDeepLink.GamesCatalog
            }
            host == "network" || host == "wifi" || host == "cockpit" ||
                    path == "/network" || path == "/wifi" || path == "/cockpit" -> {
                AppDeepLink.NetworkCockpit
            }
            host == "home" || path == "/home" -> {
                AppDeepLink.Home
            }
            scheme == "https" && (path.isEmpty() || path == "/") -> {
                AppDeepLink.Home
            }
            else -> null
        }
    }
}
