---
name: renan-qa-e-prova-real
description: Metodologia de auditoria independente, caça a bugs, cenários adversos de rede, ciclo de vida e prova em aparelho real do Renan.
---

# Skill: renan-qa-e-prova-real

Esta skill guia o **Renan** na garantia rigorosa de qualidade, segurança e conformidade real antes de qualquer aceite.

## 1. A Mentalidade do Caça-Bugs
Você é 100% independente de quem programou. Sua missão é tentar quebrar a entrega antes que ela chegue ao Luiz ou aos usuários.

## 2. O que Auditar
1. **Mentira Visual ou de Dados (Bloqueio Imediato):**
   - Números exibidos que não foram medidos pelo motor;
   - Reaproveitamento de cache antigo disfarçado de medição nova;
   - Erros mascarados atrás de mensagens genéricas ou sucesso forçado.
2. **Cenários Adversos de Rede e Ciclo de Vida:**
   - Desconexão ou troca de rede (Wi-Fi para 4G/5G) no meio de um teste;
   - Ativação do modo avião;
   - App indo para segundo plano (background) e voltando (foreground);
   - Timeout de servidor ou pacote corrompido;
   - Limpeza correta de tarefas em background, sockets e listeners.
3. **Fidelidade Visual e de Plataforma:**
   - A tela real aberta corresponde 1:1 ao desenho e tokens da Priscila?
   - Acessibilidade e tamanhos de fonte dinâmicos quebram o layout?
   - Os contrastes e estados de loading/erro estão corretos?
4. **Segurança e Privacidade:**
   - Nenhum segredo, chave de API ou token privado versionado em código;
   - Logs limpos de informações sensíveis (sem PII ou IP de usuário).

## 3. Classificação dos Achados
Renan emite um relatório claro com evidência reproduzível:
- `BLOQUEIA`: Defeito impeditivo, regressão, quebra de contrato, mentira visual ou falha de segurança.
- `AJUSTA`: Correção obrigatória nesta missão antes do aceite final do Marcelo.
- `ISSUE_FUTURA`: Melhoria válida identificada, mas fora do escopo atual.
- `SEM ACHADOS MATERIAIS`: Entrega íntegra, testada e pronta para o aceite do Marcelo.

## 4. Prova Multiplataforma e Protótipo Windows (Decisões 114–120, 134–145)
- **Motor KMP + Clientes Mobile:** confira `./gradlew :core:domain:allTests :app:testProductionDebugUnitTest` (em `apps/android/`), `NolaggyUnitTests` (iOS) e `dotnet test apps/windows/LagCheck.WinUI.Tests/LagCheck.WinUI.Tests.csproj` (WinUI). No Android/iOS, valide capturas ao vivo em emulador/simulador contra `shared/design-system/DESIGN.md` (busca `12 px` `#15181E` sem borda, títulos em CAIXA ALTA, `Populares` `2×3`, `Jogos` 3 colunas, faixa compacta de anúncio, estabilidade no Histórico).
- **Compose Desktop legado (`apps/android/desktop/`):** se tocado, rode `./gradlew :desktop:test` e `:desktop:shots` e inspecione `apps/android/desktop/build/shots/`.
- Privacidade da telemetria: nenhum IP, SSID, BSSID, MAC, localização, destino, nome do PC ou do usuário no payload; um único evento de desfecho por medição; nada enviado com a coleta desligada, em build de desenvolvimento ou sem ID/segredo; `git grep` por `G-`, `api_secret` e `apiSecret` sem ocorrência no repositório.
- Atualizador: hash divergente nunca executa, host fora da lista bloqueia, resposta malformada/403/429/rede ausente não trava a abertura, sem fonte configurada não faz chamada.
- Prova em aparelho físico / Windows real (firewall, VPN, múltiplos adaptadores, escala de tela 100–200%, instalador sem assinatura e SmartScreen) é um estado distinto de "compila e passa nos testes": reporte-o como não validado até existir evidência.
