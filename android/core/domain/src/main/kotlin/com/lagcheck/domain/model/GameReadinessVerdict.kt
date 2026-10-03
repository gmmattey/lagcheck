package com.lagcheck.domain.model

/**
 * Veredito semântico primário do LagCheck (Decisões 50 e 67).
 * Protagonista visual de maior hierarquia, respondendo: "Dá pra jogar ranked agora?"
 */
enum class GameReadinessVerdict(val rawValue: String) {
    /** Rota lisa, latência P50 ótima, jitter controlado e perda zero. */
    READY("ready"),

    /** Instabilidade moderada, jitter esporádico ou degradação sob carga. */
    CAUTION("caution"),

    /** Perda de pacotes prejudicial (>1%), latência inviável ou instabilidade severa. */
    NOT_READY("notReady"),

    /** Menos de 10 amostras UDP válidas. Proibido inventar score ou fazer fallback HTTP/ICMP. */
    INCONCLUSIVE("inconclusive");

    val isPlayable: Boolean
        get() = this == READY || this == CAUTION
}
