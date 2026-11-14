package com.lagcheck.domain.util

data class ParsedUri(
    val scheme: String?,
    val host: String?,
    val path: String?,
    val rawQuery: String?
)

fun parseUri(uriString: String): ParsedUri? {
    if (uriString.isBlank()) return null
    val colonIdx = uriString.indexOf(':')
    if (colonIdx <= 0) return null
    val scheme = uriString.substring(0, colonIdx)
    val remainder = uriString.substring(colonIdx + 1)
    if (!remainder.startsWith("//")) {
        return null
    }
    val withoutSlashes = remainder.substring(2)
    val queryStart = withoutSlashes.indexOf('?')
    val hashStart = withoutSlashes.indexOf('#')
    val candidates = mutableListOf(withoutSlashes.length)
    if (queryStart >= 0) candidates.add(queryStart)
    if (hashStart >= 0) candidates.add(hashStart)
    val endOfPath = candidates.minOrNull() ?: withoutSlashes.length

    val authorityAndPath = withoutSlashes.substring(0, endOfPath)
    val rawQuery = if (queryStart >= 0) {
        val endOfQuery = if (hashStart > queryStart) hashStart else withoutSlashes.length
        withoutSlashes.substring(queryStart + 1, endOfQuery)
    } else null

    val slashIdx = authorityAndPath.indexOf('/')
    val (authority, path) = if (slashIdx >= 0) {
        authorityAndPath.substring(0, slashIdx) to authorityAndPath.substring(slashIdx)
    } else {
        authorityAndPath to ""
    }

    val host = if (authority.contains(':')) {
        authority.substringBefore(':')
    } else {
        authority
    }

    return ParsedUri(
        scheme = scheme,
        host = host.ifEmpty { null },
        path = path,
        rawQuery = rawQuery
    )
}

fun urlEncode(input: String): String {
    val sb = StringBuilder()
    for (b in input.encodeToByteArray()) {
        val c = b.toInt().toChar()
        if (c in 'a'..'z' || c in 'A'..'Z' || c in '0'..'9' || c == '.' || c == '-' || c == '*' || c == '_') {
            sb.append(c)
        } else if (c == ' ') {
            sb.append('+')
        } else {
            val unsigned = b.toInt() and 0xFF
            sb.append('%')
            val hex = unsigned.toString(16).uppercase()
            if (hex.length == 1) sb.append('0')
            sb.append(hex)
        }
    }
    return sb.toString()
}

fun urlDecode(input: String): String {
    val s = input.replace('+', ' ')
    val bytes = mutableListOf<Byte>()
    var i = 0
    while (i < s.length) {
        if (s[i] == '%' && i + 2 < s.length) {
            val hex = s.substring(i + 1, i + 3)
            val byteVal = hex.toIntOrNull(16)
            if (byteVal != null) {
                bytes.add(byteVal.toByte())
                i += 3
                continue
            }
        }
        val encoded = s[i].toString().encodeToByteArray()
        for (b in encoded) {
            bytes.add(b)
        }
        i++
    }
    return bytes.toByteArray().decodeToString()
}
