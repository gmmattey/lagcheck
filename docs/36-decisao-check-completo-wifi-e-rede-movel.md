# LagCheck — Decisão 36: Check Completo em Wi-Fi e Rede Móvel com Consentimento de Dados e Trilha Visual HIG

**Status:** Decisão aprovada pelo Dono do Produto (Luiz); em especificação técnica e implementação  
**Data:** 19 de setembro de 2026  
**Autores / Revisores:** Luiz (Dono do Produto), Marco (Produto), Renan (Design), Iury (Rede), Rian (iOS)  
**Complementa e revisa:** `docs/01-funcional.md`, `docs/02-arquitetura.md`, `docs/03-especificacao-tecnica.md`, `docs/04-design-system.md`, `docs/07-voz-do-produto.md`, `docs/12-decisao-deep-check-piloto.md`, `docs/34-decisao-trilha-viva-medicao-e-estresse.md`, `docs/35-decisao-tela-resultado-hig-trilha-consolidada.md`

> **Atualização de integridade (Decisões 60 e 62):** o candidato atual não inclui Atalho de contexto de rede. Em Wi-Fi, a telemetria local pode apontar condição do enlace somente quando há probe isolado; ela não afirma 2,4 GHz, 5 GHz ou 6 GHz sem uma fonte pública válida do sistema.

---

## 1. Contexto e Motivação de Produto (Marco)

Na versão original do piloto (Decisão 12) e nas diretrizes iniciais de arquitetura (`docs/02` §5.2), o Deep Check (Check Completo) foi restrito exclusivamente a redes Wi-Fi como salvaguarda preventiva contra o consumo acidental de franquias de dados móveis do usuário.

Contudo, a realidade dos jogadores móveis no iPhone exige que a qualidade da conexão possa ser avaliada com precisão tanto no Wi-Fi doméstico quanto em redes celulares (4G/5G), onde bufferbloat e latência sob carga geram frequentes engasgos em partidas online.

Com a presente decisão formalizada pelo Dono do Produto (Luiz):
1. **O Check Completo é liberado tanto em Wi-Fi quanto em rede móvel.**
2. **Em rede móvel, o consentimento explícito e transparente é pré-requisito obrigatório** antes de transferir qualquer byte de carga.
3. **A Trilha Visual ativa é reformulada para o padrão minimalista HIG**, eliminando ruídos técnicos intermediários (números, gráficos, percentuais ou score prévio) e organizando os 5 passos canônicos da rota.
4. **Permanece estritamente inegociável a regra de sessão única ativa com descarte integral de dados parciais** caso haja qualquer transição de caminho de rede durante a execução.

---

## 2. Comportamento por Tipo de Conexão (Iury e Rian)

### 2.1 Conexão Wi-Fi
* **Fase 1 (Repouso):** Executa rota em repouso enviando probes UDP contra o destino de referência (2 probes/s, janela de 15 segundos).
* **Fase 2 (Sob Carga):** Executa rota sob carga combinando probes UDP simultâneos com transferência HTTP controlada via endpoint seguro do Cloudflare Worker (`/v1/load`), limitado a 10 MB e máximo de 15 segundos.
* **Identificação na Trilha:** O primeiro nó da trilha exibe "Wi-Fi", acompanhado do ícone `wifi`.
* **Diagnósticos Locais Permitidos:** Permite coletar telemetria do gateway local para a síntese final. Sem uma fonte pública válida do sistema, a frequência Wi-Fi permanece não confirmada; SSID, RTT, jitter e perda não a determinam.

### 2.2 Conexão em Rede Móvel (Celular)
* **Fase 1 (Repouso):** Executa rota em repouso por probes UDP idênticos ao Wi-Fi.
* **Fase 2 (Sob Carga):** Executa rota sob carga por probes UDP e transferência HTTP controlada (`/v1/load`), sob o mesmo teto técnico de 10 MB e 15 segundos.
* **Consentimento Prévio Obrigatório:**
  - Antes de iniciar o Check Completo em rede móvel, o app deve exibir uma confirmação explícita de consumo de dados:  
    *“O Check Completo usa dados móveis para avaliar sua conexão sob carga.”*
  - A confirmação deve discriminar de forma transparente o limite técnico máximo previsto para a medição (até 10 MB).
  - Sem consentimento do usuário, a jornada é cancelada antes de qualquer probe UDP ou carga. Não há medição alternativa reduzida, resultado, score, histórico ou reteste parcial. Esta regra é consolidada pela decisão 46.
* **Identificação na Trilha:** O primeiro nó exibe "Rede móvel", com o ícone SF Symbol `antenna.radiowaves.left.and.right`.
* **Restrição de Integridade de Diagnóstico:** Em rede celular é **estritamente proibido** inferir ou exibir roteador local, frequência Wi-Fi (2.4 GHz ou 5 GHz), gateway residencial ou suposto gargalo local de Wi-Fi.

---

## 3. Trilha Visual Ativa durante a Medição (Renan)

Durante a execução ativa de uma sessão, a interface exibe a progressão em 5 nós verticais conectados:

```
┌────────────────────────────────────────────────────────┐
│                      LAGCHECK AO VIVO                  │
├────────────────────────────────────────────────────────┤
│                                                        │
│   Wi-Fi  ou  Rede móvel                 [ Conectado ]  │
│   │                                                    │
│   Ping                                  [ Medindo ]    │
│   │                                                    │
│   Perda                                 [ Monitorando ]│
│   │                                                    │
│   Sob carga                             [ Aguardando ] │
│   │                                                    │
│   São Paulo                             [ Ativo ]      │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### Regras de Exibição e Semântica da Trilha:
1. **Nó 1 (Conexão Local):** Exibe "Wi-Fi" (ícone `wifi`) ou "Rede móvel" (ícone `antenna.radiowaves.left.and.right`). Mostra o estado de conectividade validada.
2. **Nó 2 (Ping) e Nó 3 (Perda):** São monitorados e atualizados em paralelo durante ambas as fases (repouso e sob carga).
3. **Nó 4 (Sob carga):**
   - Na **Fase 1 (Repouso)**: exibe estado de espera (*"Aguardando"*).
   - Na **Fase 2 (Sob carga)**: torna-se ativo (*"Medindo impacto"* ou *"Ativo"*).
4. **Nó 5 (Região de Referência):**
   - Nome amigável e legível obtido diretamente do catálogo de infraestrutura (ex.: "São Paulo", "Virgínia", "Frankfurt").
   - Começa a responder já na primeira fase e permanece ativo durante a segunda fase.
   - **Proibição de Promessa Falsa:** Nunca chamar a região de "servidor oficial do jogo" nem prometer rota privada do título.
5. **Silêncio de Ruído Durante a Medição:**  
   É expressamente proibido exibir durante a execução da medição:
   - Números de ping instantâneo em milissegundos pulando.
   - Gráficos oscilantes ou séries temporais abertas.
   - Percentuais contínuos ou contadores numéricos de perda de pacotes.
   - Contagem regressiva de tempo restante.
   - Score preliminar ou explicações intermediárias.  
   A interface deve manter tom calmo, focado e rigorosamente determinístico.

---

## 4. Política Inegociável de Troca de Rede (Iury e Rian)

* **Detecção Imediata:** O `NWPathMonitorNetworkPathObserver` monitora ativamente as transições de caminho de interface (`usesWiFi` e `usesCellular`).
* **Descarte Instantâneo:** Qualquer alteração de interface (Wi-Fi ➔ Rede Móvel ou Rede Móvel ➔ Wi-Fi) ocorrida durante a sessão ativa (seja na fase de repouso ou na fase sob carga) **cancela imediatamente a medição**.
* **Sem Resíduo Parcial:** Amostras colhidas até o momento da troca são sumariamente descartadas da memória. Nenhum dado parcial é gravado no SwiftData nem oferecido como resultado provisório.
* **Sem Retomada Automática:** O app não deve reiniciar a medição sozinho em segundo plano.
* **Recuperação Limpa:** A interface apresenta o estado neutro de cancelamento por alteração de conexão com CTA para iniciar um novo teste na rede atual.

---

## 5. Medição Sob Carga e Histórico de Resultados

1. **Parada Imediata:** Ao cancelar a sessão por ação do usuário, background ou troca de rede, tanto a tarefa HTTP de carga quanto a emissão de probes UDP são abortadas imediatamente no socket/transporte.
2. **Registro Tipado no Histórico:** O modelo de persistência (`MeasurementHistoryEntry`) deve registrar explicitamente o tipo de conexão utilizado (`equipmentConnection`: `.wifi` ou `.cellular`).
3. **Interpretação Desacoplada:** O histórico e as telas de resultado **nunca devem comparar automaticamente um resultado em Wi-Fi com um resultado em rede móvel como se fossem equivalentes**, pois os perfis físicos e latências de base dos meios são fundamentalmente distintos.

---

## 6. Critérios de Aceite e Matriz de Testes Obrigatórios em iPhone Físico

O fechamento desta decisão e a validação de release exigem evidência real nos seguintes cenários:

| ID | Cenário | Ambiente | Critério de Aceite |
|---|---|---|---|
| TC-01 | Check Completo em Wi-Fi (Válido) | iPhone Físico | Executa repouso e carga; trilha exibe "Wi-Fi"; gera resultado válido com impacto de carga. |
| TC-02 | Check Completo em Wi-Fi (Inconclusivo) | iPhone Físico | UDP bloqueado ou sem 10 respostas; exibe estado inconclusivo neutro sem score. |
| TC-03 | Consentimento em Rede Móvel (Aceite) | iPhone Físico | Exibe tela/aviso com texto exato e teto de 10 MB; após aceite, inicia repouso e carga. |
| TC-04 | Consentimento em Rede Móvel (Recusa) | iPhone Físico | Encerra Deep Check sem oferecer alternativa reduzida; não inicia UDP ou carga HTTP, não exibe resultado e não persiste histórico. |
| TC-05 | Check Completo em Rede Móvel (Válido) | iPhone Físico | Trilha exibe "Rede móvel" com `antenna.radiowaves.left.and.right`; sem dados de roteador/2.4GHz; grava no histórico como celular. |
| TC-06 | Wi-Fi ➔ Rede Móvel (Durante Repouso) | iPhone Físico | Desliga Wi-Fi na Central de Controle; sessão cancela na hora; nenhum dado gravado. |
| TC-07 | Wi-Fi ➔ Rede Móvel (Durante Carga) | iPhone Físico | Desliga Wi-Fi durante transferência; carga e UDP param na hora; sessão cancelada. |
| TC-08 | Rede Móvel ➔ Wi-Fi (Durante Repouso) | iPhone Físico | Liga Wi-Fi; cancela imediatamente; sem retomada automática. |
| TC-09 | Rede Móvel ➔ Wi-Fi (Durante Carga) | iPhone Físico | Liga Wi-Fi; cancela imediatamente; sem persistência parcial. |
