# Empacotamento Windows — LagCheck (Compose Desktop)

> **Status:** Protótipo local de avaliação (Decisões 114, 115 e 116). **Nada foi publicado.**
> Não há distribuição pública, Microsoft Store, release em repositório nem alteração do Worker em produção.

---

## 1. Como Gerar o App

Executar a partir da pasta `android/` com JDK 21 (`JAVA_HOME` apontando para o JDK 21):

```bash
# 1. Pasta executável descompactada (aplicação pronta para execução local direta)
./gradlew :desktop:createDistributable

# 2. Instalador executável Windows (.exe)
./gradlew :desktop:packageExe

# 3. Pacote MSI Windows (.msi)
./gradlew :desktop:packageMsi
```

### Saídas Geradas no Build
- **Pasta da aplicação (`createDistributable`):**
  `android/desktop/build/compose/binaries/main/app/LagCheck/`
  Contém `LagCheck.exe`, `runtime/` (JVM customizada jlink) e `app/` (~190 MB no total).
- **Instalador EXE (`packageExe`):**
  `android/desktop/build/compose/binaries/main/exe/LagCheck-<versão>.exe` (~124 MB).
- **Pacote MSI (`packageMsi`):**
  `android/desktop/build/compose/binaries/main/msi/LagCheck-<versão>.msi` (~124 MB).

---

## 2. Parâmetros de Versão e Telemetria (GA4)

### Versão do Pacote
Controlada por **uma única propriedade**: `lagcheck.version` (padrão: `0.1.0`).
> **Atenção:** O empacotador do Windows (`jpackage` / WiX) exige estritamente formato numérico `MAJOR.MINOR.BUILD` (ex: `0.1.0` ou `1.0.0`).

```bash
./gradlew :desktop:packageExe -Plagcheck.version=0.1.0
```

### Telemetria GA4 (Measurement Protocol)
Os identificadores de telemetria nunca ficam versionados no código. Devem ser passados no momento do build via propriedade Gradle ou variável de ambiente:

- Propriedades Gradle (linha de comando ou `~/.gradle/gradle.properties`):
  `-Plagcheck.ga4.measurementId=G-XXXXXXXXXX`
  `-Plagcheck.ga4.apiSecret=YYYYYYYYYYYYYY`
- Variáveis de ambiente:
  `LAGCHECK_GA4_MEASUREMENT_ID=G-XXXXXXXXXX`
  `LAGCHECK_GA4_API_SECRET=YYYYYYYYYYYYYY`

**Comportamento de ativação:**
- A coleta só é habilitada em builds empacotados (`createDistributable`, `packageExe`, `packageMsi`) **E** se ambos `measurementId` e `apiSecret` estiverem preenchidos e não em branco.
- Em desenvolvimento (`run`, `shots`, `runCli`, testes) ou na ausência de credenciais, a telemetria permanece **completamente inerte** (`analytics.enabled=false`), sem nenhuma chamada de rede.

---

## 3. O Que Falta para um Release Real

1. **Assinatura de Código (Authenticode):** Os executáveis e instaladores gerados não possuem assinatura digital. No Windows, a execução de binários não assinados exibe o alerta do Windows Defender SmartScreen. É necessário certificado digital de assinatura de código (EV ou OV) configurado no pipeline.
2. **WiX Toolset / Customizações Avançadas:** O build atual utiliza o utilitário interno do Compose Multiplatform. Customizações adicionais de telas de instalação, termos de licença e atalhos customizados dependem de configuração estendida.
3. **Decisão e Autorização de Distribuição:** Nenhuma loja (Microsoft Store), canal de download ou repositório de release foi criado ou autorizado.

---

## 4. Como publicar uma release (procedimento usado na `windows-v0.1.0`)

1. A partir da `main` atualizada, com JDK 21. **Passe o ID e o segredo do GA4 por variáveis de ambiente** (`LAGCHECK_GA4_MEASUREMENT_ID` e `LAGCHECK_GA4_API_SECRET`): em máquinas com `GRADLE_USER_HOME` diferente de `~/.gradle`, as propriedades de `~/.gradle/gradle.properties` **não são lidas** e o instalador sai com a telemetria desligada. Confira antes de publicar: `unzip -p android/desktop/build/libs/desktop.jar lagcheck-runtime.properties` deve mostrar `analytics.enabled=true`.
2. `./gradlew :desktop:clean :desktop:packageExe :desktop:packageMsi -Plagcheck.version=X.Y.Z`.
3. Renomeie para `LagCheck-Windows-X.Y.Z-x64-setup.exe` e `LagCheck-Windows-X.Y.Z-x64.msi` (nomes que a página e o atualizador esperam) e gere `SHA256SUMS.txt` e `LagCheck-Windows-X.Y.Z-x64-setup.exe.sha256`.
4. `gh release create windows-vX.Y.Z --target main --latest=false` com o **`.exe` primeiro**; depois `gh release upload` do `.msi` e dos checksums. O `.exe` precisa ser o primeiro asset: o atualizador lê o primeiro `.exe/.msi` e o primeiro `digest` do bloco da release. Não marque como prerelease (a página e o atualizador ignoram).
5. Publicação de release e deploy do site exigem autorização expressa do Luiz. O segredo do GA4 fica dentro do binário público (próprio do Measurement Protocol); restrinja o uso no GA4 se houver abuso.
