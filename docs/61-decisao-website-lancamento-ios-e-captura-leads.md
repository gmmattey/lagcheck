# Decisão 61 — Atualização do Website Oficial: Lançamento em Breve no iOS (iOS 17+) e Captura de Convites (Waitlist)

- **Data:** 26 de setembro de 2026
- **Status:** decidido e em implementação; reconfirmação de escopo registrada em 26 de setembro de 2026
- **Responsáveis:** Marco (integração e produto), Renan (design e Dark Competitive UI), Rian (frontend web e acessibilidade), Iury (infraestrutura de borda e resiliência) e Luiz (aprovação de produto)
- **Revisa / Complementa:** Decisões 50, 51, 52, 53, 55, 56, 57 e 58

---

## 1. Contexto e Motivação

> **Atualização de corte (Decisão 62):** o dono do produto reconfirmou neste corte a inclusão de `/v1/waitlist`, KV e Analytics Engine para a captura de convites. A implementação continua limitada a essa finalidade e requer validação de Iury antes de publicação do Worker.

O LagCheck está concluindo seu ciclo de engenharia e validação técnica para a versão inicial do iPhone (iOS 17+), focado na proposta de valor **Ready for Ranked** (Decisão 50).

No site oficial (`https://lagcheck.signallq.com/` / diretório `web/`), os botões de conversão apontavam genericamente para download na App Store como se o binário já estivesse disponível publicamente. Além de desalinhado com a realidade de pré-lançamento, isso impedia a retenção de jogadores competitivos que chegam ao site com alta intenção de uso.

Por solicitação explícita do Dono do Produto (Luiz), o website oficial deve ser atualizado para:
1. Comunicar com transparência que o **lançamento para iPhone (iOS 17+) será em breve**.
2. Atualizar a vitrine de recursos com base em todas as **funcionalidades reais existentes no app** (Ready Check em 1 toque, medição dual-phase com carga real, detecção de pacotes fora de ordem RFC 4737, Cockpit de rede com probe de gateway isolado, auditoria Wi-Fi e NAT RFC 5389, adequação para voice chat e otimizações de setup).
3. Implementar um **formulário de captura de e-mail para acesso antecipado / convite via TestFlight**, com garantia estrita de persistência de dados ("Obviamente, será salvo :P").

---

## 2. Decisão de Produto (Marco)

1. **Posicionamento de Lançamento**:
   - Manter a marca oficial **LagCheck** (com `lagcheck` em minúsculas na wordmark).
   - Informar de maneira visível: *"Lançamento em breve para iPhone (iOS 17+)"* e *"Acesso antecipado via TestFlight"*.
   - Substituir botões fictícios de download direto por CTA de captura de convite: *"Receber Convite"* / *"Garantir Acesso Antecipado"*.

2. **Funcionalidades Reais em Destaque**:
   - **Veredito "Ready for Ranked"**: Semântico e determinístico (`● PRONTO PARA RANKED`, `▲ EU EVITARIA RANKED AGORA`, `▲ CONDIÇÕES INSTÁVEIS`, `— INCONCLUSIVO`).
   - **Medição Dual-Phase sob Estresse**: Rajadas controladas de pacotes UDP para revelar bufferbloat oculto e picos de jitter.
   - **Detecção de Pacotes Fora de Ordem (RFC 4737)**: Auditoria de reordenação de pacotes que provoca tiros fantasma e micro-stutters.
   - **Cockpit de Rede & Probe Local**: Diagnóstico isolado do roteador doméstico vs provedor/backbone para integridade diagnóstica (nunca culpar a WAN por falhas de Wi-Fi local).
   - **Auditoria Wi-Fi e NAT RFC 5389**: Frequência (2.4 GHz vs 5 GHz), tipo de NAT (1/2/3) e CGNAT.
   - **Adequação para Discord / Voice Chat**: Análise de estabilidade para squads e comunicação em equipe.
   - **Otimização de Setup por Plataforma**: Recomendações acionáveis para iPhone, PC, PlayStation e Xbox.
   - **Privacidade e Zero Contas**: SwiftData local por até 90 dias, zero publicidade, sem login obrigatório.

3. **Estratégia de Persistência Resiliente dos E-mails (Iury & Rian)**:
   - **Camada 1 (Persistência Imediata no Cliente)**: Armazenamento instantâneo em `localStorage` sob a chave `lagcheck_waitlist_leads` com timestamp, e-mail sanitizado, idioma e status de sincronização. A equipe tem acesso à exportação direta via console (`window.LagcheckWaitlist.list()`, `window.LagcheckWaitlist.exportJSON()`, `window.LagcheckWaitlist.exportCSV()`).
   - **Camada 2 (Endpoint de Borda no Worker)**: Endpoint `POST /v1/waitlist` no Cloudflare Worker gratuito (`nolaggy-deep-check`). Valida e-mail por RFC 5322, sanitiza, grava no Cloudflare KV (`env.WAITLIST_KV`) se vinculado, despacha evento para Cloudflare Analytics Engine (`env.ANALYTICS`) e responde `{ status: "ok", email }` com CORS habilitado.

4. **Privacidade e Transparência**:
   - Os e-mails capturados no website destinam-se exclusivamente ao envio do link de acesso antecipado no TestFlight e notificação de lançamento.
   - A Política de Privacidade (`web/privacy.html` e `web/privacy/index.html`) explicita esse tratamento ético e transparente.

---

## 3. Critérios de Aceite e Verificação

1. `npm test` no `worker/`: 100% de testes passando, incluindo testes de validação, CORS, payload e KV do endpoint `/v1/waitlist`.
2. `node web/validate.js`: 100% de aprovação na suite de testes estáticos, incluindo integridade de ativos de marca, paridade de tradução PT/EN, tokens de design system e rotas HTTP locais.
3. Formulário no Hero e no rodapé com labels acessíveis, validação de e-mail e feedback imediato de sucesso.
