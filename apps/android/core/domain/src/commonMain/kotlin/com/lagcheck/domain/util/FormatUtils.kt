package com.lagcheck.domain.util

/**
 * Formata como `String.format(Locale.ROOT, "%.Nf", value)` do Java: arredondamento HALF_UP sobre a
 * representação decimal mais curta do double (2.675 -> "2.68", 1.005 -> "1.01", 99.95 -> "100.0").
 * Implementado sobre os dígitos de `toString()`, que é a forma mais curta em JVM, iOS e JS.
 */
fun formatDecimal(value: Double, decimals: Int): String {
    require(decimals >= 0) { "decimals must be >= 0" }
    if (value.isNaN()) return "NaN"
    if (value.isInfinite()) return if (value > 0) "Infinity" else "-Infinity"
    val isNeg = value < 0.0 || (value == 0.0 && 1.0 / value < 0.0)
    val text = (if (isNeg) -value else value).toString()

    // Decompõe em dígitos e expoente decimal: valor = 0.d1d2d3... × 10^pointPos
    val expIndex = text.indexOfFirst { it == 'e' || it == 'E' }
    val mantissa = if (expIndex >= 0) text.substring(0, expIndex) else text
    val exponent = if (expIndex >= 0) text.substring(expIndex + 1).removePrefix("+").toInt() else 0
    val dot = mantissa.indexOf('.')
    val intDigits = if (dot >= 0) mantissa.substring(0, dot) else mantissa
    val fracDigits = if (dot >= 0) mantissa.substring(dot + 1) else ""
    var digits = (intDigits + fracDigits).trimStart('0')
    var pointPos = intDigits.trimStart('0').length + exponent
    if (intDigits.trimStart('0').isEmpty()) {
        // 0.000ddd: os zeros iniciais da fração deslocam a vírgula.
        val leadingZeros = fracDigits.length - fracDigits.trimStart('0').length
        pointPos = -leadingZeros + exponent
    }
    if (digits.isEmpty()) {
        digits = "0"
        pointPos = 1
    }

    // Dígitos inteiros e fracionários alinhados, com `decimals + 1` casas para decidir o arredondamento.
    val totalKeep = pointPos + decimals
    val padded = when {
        pointPos <= 0 -> "0".repeat(-pointPos + 1) + digits
        else -> digits
    }
    val shift = if (pointPos <= 0) -pointPos + 1 else 0
    val keepCount = totalKeep + shift
    val kept = StringBuilder()
    for (i in 0 until maxOf(keepCount, 0)) kept.append(if (i < padded.length) padded[i] else '0')
    val nextDigit = if (keepCount >= 0 && keepCount < padded.length) padded[keepCount] else '0'

    var number = kept.toString().ifEmpty { "0" }
    if (nextDigit >= '5') number = incrementDecimalString(number)
    val integerLength = number.length - decimals
    val intPart = number.substring(0, maxOf(integerLength, 0)).trimStart('0').ifEmpty { "0" }
    val fracPart = if (decimals > 0) number.substring(maxOf(integerLength, 0)).padStart(decimals, '0') else ""
    val isZero = intPart == "0" && fracPart.all { it == '0' }
    val prefix = if (isNeg && !isZero) "-" else ""
    return if (decimals > 0) "$prefix$intPart.$fracPart" else "$prefix$intPart"
}

private fun incrementDecimalString(number: String): String {
    val chars = number.toCharArray()
    var i = chars.size - 1
    while (i >= 0) {
        if (chars[i] == '9') {
            chars[i] = '0'
            i--
        } else {
            chars[i] = chars[i] + 1
            return chars.concatToString()
        }
    }
    return "1" + chars.concatToString()
}

fun formatString(template: String, vararg args: Any?): String {
    val sb = StringBuilder()
    var argIndex = 0
    var i = 0
    while (i < template.length) {
        val c = template[i]
        if (c == '%' && i + 1 < template.length) {
            if (template[i + 1] == '%') {
                sb.append('%')
                i += 2
                continue
            }
            var j = i + 1
            val plus = if (j < template.length && template[j] == '+') { j++; true } else false
            var padZero = false
            var width = 0
            if (j < template.length && template[j] == '0') {
                padZero = true
                j++
            }
            while (j < template.length && template[j].isDigit()) {
                width = width * 10 + (template[j] - '0')
                j++
            }
            var precision = -1
            if (j < template.length && template[j] == '.') {
                j++
                precision = 0
                while (j < template.length && template[j].isDigit()) {
                    precision = precision * 10 + (template[j] - '0')
                    j++
                }
            }
            if (j < template.length) {
                val spec = template[j]
                val arg = if (argIndex < args.size) args[argIndex++] else null
                when (spec) {
                    's' -> sb.append(arg?.toString() ?: "null")
                    'd' -> {
                        val num = when (arg) {
                            is Number -> arg.toLong()
                            is String -> arg.toLongOrNull() ?: 0L
                            else -> 0L
                        }
                        var s = num.toString()
                        if (padZero && s.length < width) {
                            s = "0".repeat(width - s.length) + s
                        }
                        if (plus && num >= 0) s = "+$s"
                        sb.append(s)
                    }
                    'f' -> {
                        val num = when (arg) {
                            is Number -> arg.toDouble()
                            is String -> arg.toDoubleOrNull() ?: 0.0
                            else -> 0.0
                        }
                        val prec = if (precision >= 0) precision else 6
                        val s = formatDecimal(num, prec)
                        val formatted = if (plus && num >= 0 && !s.startsWith("+") && !s.startsWith("-")) "+$s" else s
                        sb.append(formatted)
                    }
                    else -> {
                        sb.append(template.substring(i, j + 1))
                    }
                }
                i = j + 1
                continue
            }
        }
        sb.append(c)
        i++
    }
    return sb.toString()
}
