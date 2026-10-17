package com.lagcheck.domain.model

import java.net.URI

sealed class AppDeepLink {
    data class QuickCheck(val gameID: String?, val platform: String?) : AppDeepLink()
    object NetworkCockpit : AppDeepLink()
    object GamesCatalog : AppDeepLink()
    object Home : AppDeepLink()
}

object DeepLinkParser {

    fun parse(uriString: String): AppDeepLink? {
        val uri = try {
            URI(uriString)
        } catch (_: Exception) {
            return null
        }

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
            val key = java.net.URLDecoder.decode(parts[0], "UTF-8").lowercase()
            val value = java.net.URLDecoder.decode(parts.getOrElse(1) { "" }, "UTF-8")
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
