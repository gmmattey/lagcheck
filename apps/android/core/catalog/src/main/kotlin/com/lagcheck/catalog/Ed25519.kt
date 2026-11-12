package com.lagcheck.catalog

import java.math.BigInteger
import java.security.MessageDigest

/**
 * Verificação Ed25519 (RFC 8032 §5.1.7) em Kotlin puro, somente verify.
 *
 * Existe porque `Signature.getInstance("Ed25519")` só está disponível no Android 13+ (API 33) e o
 * minSdk do LagCheck é 26. Sem SDK de terceiros (custo e superfície zero). Não é tempo-constante,
 * o que é irrelevante aqui: verificação usa só dados públicos (chave pública, mensagem e assinatura).
 */
object Ed25519 {
    private val P = BigInteger.ONE.shiftLeft(255) - BigInteger.valueOf(19)
    private val L = BigInteger.ONE.shiftLeft(252) + BigInteger("27742317777372353535851937790883648493")
    private val D = (BigInteger.valueOf(-121665) * BigInteger.valueOf(121666).modInverse(P)).mod(P)
    private val SQRT_M1 = BigInteger.TWO.modPow((P - BigInteger.ONE).shiftRight(2), P)

    private class Point(val x: BigInteger, val y: BigInteger, val z: BigInteger, val t: BigInteger)

    private val identity = Point(BigInteger.ZERO, BigInteger.ONE, BigInteger.ONE, BigInteger.ZERO)

    private val base: Point by lazy {
        val gy = (BigInteger.valueOf(4) * BigInteger.valueOf(5).modInverse(P)).mod(P)
        val gx = recoverX(gy, 0) ?: error("invalid base point")
        Point(gx, gy, BigInteger.ONE, (gx * gy).mod(P))
    }

    fun verify(publicKey: ByteArray, message: ByteArray, signature: ByteArray): Boolean {
        if (publicKey.size != 32 || signature.size != 64) return false
        val a = decompress(publicKey) ?: return false
        val rBytes = signature.copyOfRange(0, 32)
        if (decompress(rBytes) == null) return false
        val s = littleEndian(signature.copyOfRange(32, 64))
        if (s >= L) return false

        val sha = MessageDigest.getInstance("SHA-512")
        sha.update(rBytes)
        sha.update(publicKey)
        sha.update(message)
        val h = littleEndian(sha.digest()).mod(L)

        // [S]B == R + [h]A  <=>  [S]B + [h](-A) == R
        val negA = Point((P - a.x).mod(P), a.y, a.z, (P - a.t).mod(P))
        val candidate = add(multiply(s, base), multiply(h, negA))
        return compress(candidate).contentEquals(rBytes)
    }

    private fun add(p: Point, q: Point): Point {
        val a = ((p.y - p.x) * (q.y - q.x)).mod(P)
        val b = ((p.y + p.x) * (q.y + q.x)).mod(P)
        val c = (BigInteger.TWO * p.t * q.t * D).mod(P)
        val d = (BigInteger.TWO * p.z * q.z).mod(P)
        val e = b - a
        val f = d - c
        val g = d + c
        val h = b + a
        return Point((e * f).mod(P), (g * h).mod(P), (f * g).mod(P), (e * h).mod(P))
    }

    private fun multiply(scalar: BigInteger, point: Point): Point {
        var result = identity
        var addend = point
        var s = scalar
        while (s.signum() > 0) {
            if (s.testBit(0)) result = add(result, addend)
            addend = add(addend, addend)
            s = s.shiftRight(1)
        }
        return result
    }

    private fun recoverX(y: BigInteger, sign: Int): BigInteger? {
        if (y >= P) return null
        val x2 = ((y * y - BigInteger.ONE) * (D * y * y + BigInteger.ONE).modInverse(P)).mod(P)
        if (x2.signum() == 0) return if (sign != 0) null else BigInteger.ZERO
        var x = x2.modPow((P + BigInteger.valueOf(3)).shiftRight(3), P)
        if ((x * x - x2).mod(P).signum() != 0) x = (x * SQRT_M1).mod(P)
        if ((x * x - x2).mod(P).signum() != 0) return null
        if ((if (x.testBit(0)) 1 else 0) != sign) x = P - x
        return x
    }

    private fun decompress(bytes: ByteArray): Point? {
        val value = littleEndian(bytes)
        val sign = if (value.testBit(255)) 1 else 0
        val y = value.clearBit(255)
        val x = recoverX(y, sign) ?: return null
        return Point(x, y, BigInteger.ONE, (x * y).mod(P))
    }

    private fun compress(p: Point): ByteArray {
        val zInv = p.z.modInverse(P)
        val x = (p.x * zInv).mod(P)
        val y = (p.y * zInv).mod(P)
        val value = if (x.testBit(0)) y.setBit(255) else y
        return toLittleEndian(value, 32)
    }

    private fun littleEndian(bytes: ByteArray): BigInteger = BigInteger(1, bytes.reversedArray())

    private fun toLittleEndian(value: BigInteger, size: Int): ByteArray {
        val big = value.toByteArray().reversedArray() // pode ter byte de sinal extra no fim
        val out = ByteArray(size)
        for (i in 0 until minOf(size, big.size)) out[i] = big[i]
        return out
    }
}
