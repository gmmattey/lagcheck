# LagCheck: regras de release (R8). O app não usa reflexão própria nem serialização por reflexão.
# Modelos de domínio, catálogo e rede são classes Kotlin simples acessadas diretamente.

# Mantém números de linha nos relatórios de crash sem expor nomes originais.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# kotlinx-serialization-json (só a árvore JsonElement, sem classes @Serializable): nada a manter além do padrão.
-dontwarn kotlinx.serialization.**

# Telemetria de rádio usa APIs do framework por nome em tempo de execução apenas dentro de try/catch.
-dontwarn android.net.wifi.**
