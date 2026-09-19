# Nolaggy — decisão: dicas de otimização de conexão com IA (Gemini Booster pós-Deep Check)

**Status:** decisão aprovada pelo dono do produto (Luiz) para especificação e implementação  
**Data:** 17 de setembro de 2026  
**Complementa:** `docs/12-decisao-deep-check-piloto.md`, `docs/21-decisao-direcao-visual-simplicidade.md`, `docs/22-decisao-jornada-lista-nativa-e-background-check.md`  
**Referência de Tom e Voz:** `docs/07-voz-do-produto.md`

---

## 1. Contexto e Proposta de Valor

Após a realização de um **Deep Check**, o app possui uma fotografia rica da qualidade da rede do usuário:
- Latência em repouso (RTT P50/P95).
- Estabilidade e jitter.
- Perda de pacotes.
- Comportamento e impacto sob carga intensa (bufferbloat / delta P50 sob carga).
- Jogo alvo com seus requisitos de tolerância de rede.
- Plataforma onde o usuário joga (iPhone, PC, PlayStation, Xbox, Switch).

Para transformar esses dados técnicos em valor prático sem complicar o app com jargões incompreensíveis, o usuário terá disponível na tela de resultado do Deep Check um CTA para **obter dicas personalizadas de otimização de conexão** potencializadas pela API do Gemini.

---

## 2. Regras de Produto e Negócio

1. **Disponibilidade do CTA**:
   - Visível na tela de resultado do Deep Check para **qualquer resultado com score válido** (Excelente, Bom, Aceitável ou Baixo).
   - Em conexões excelentes, foca em manter estabilidade e ajustes finos para evitar picos. Em conexões instáveis ou com alto impacto de carga, foca em ações corretivas imediatas.
   - Não é exibido em resultados **inconclusivos** ou **cancelados** (conforme regra de ouro do Nolaggy: sem dados suficientes, não há recomendação).
2. **Contexto de Plataforma do Jogo**:
   - As sugestões consideram a plataforma selecionada pelo usuário no fluxo do jogo (iPhone, PC, PlayStation, Xbox, Nintendo Switch).
   - Um jogador no PC recebe dicas direcionadas ao ambiente de PC (ex.: cabo Ethernet, prioridade QoS no roteador, drivers, fechamento de downloads em background). Um jogador em console recebe dicas pertinentes a consoles (ex.: teste de NAT, cabo, Wi-Fi 5GHz vs 2.4GHz, DNS). Um jogador no iPhone recebe dicas adequadas a redes móveis/Wi-Fi no celular.
3. **Tom de Voz do Retorno (Voz do Produto) e Idioma**:
   - Respeita integralmente o `docs/07-voz-do-produto.md`.
   - Tom: direto, calmo, preciso, gamer natural (usando conceitos compreensíveis do jogo/plataforma em questão), **sem cair no caricato** ("GG", "amassou", "OP") e **sem promessas infundadas** ("zero lag garantido", "ping perfeito").
   - **Localização**: o prompt exige estritamente que a resposta siga o idioma efetivo do app: `pt-BR`, `en` ou `es`. Idioma efetivo é o idioma do sistema, salvo uma escolha explícita e ativa da pessoa no LagCheck.
   - **Contrato de idioma**: instruções, contexto textual e saída devem estar no mesmo idioma alvo. Resposta vazia, fora do JSON ou em idioma incompatível é falha recuperável; o app oferece nova tentativa e não traduz, reescreve ou inventa recomendações localmente.
   - **Guardrail de Vocabulário**: a aplicação implementa validação/filtro client-side para rejeitar termos da tabela "Evitar" do `docs/07` §3 antes de renderizar para o usuário.
4. **Formato das Recomendações**:
   - **Sem textão corrido**: o modelo deve devolver JSON estruturado (`responseMimeType: "application/json"`) mapeado diretamente para uma lista de ações práticas, concisas e acionáveis, agrupadas ou ordenadas por relevância e facilidade (ex.: Equipamento / Roteador, Plataforma / Jogo, Provedor).

---

## 3. Arquitetura, Segurança e Gestão de Chaves

1. **Decisão Transitória de Chave Client-side (Risco Registrado)**:
   - **Autorização explícita do Dono do Produto (Luiz)**: A chamada direta client-side com API key configurada no app foi aprovada de forma proposital e **estritamente temporária** para validação ágil da experiência.
   - **Risco assumido**: Chaves embutidas em binários iOS são extraíveis via engenharia reversa do IPA.
   - **Mitigações imediatas**:
     - A chave **nunca** é commitada em texto plano no repositório git (utiliza `.xcconfig`/variáveis de ambiente locais não versionadas).
     - **Cache & Debounce**: O resultado gerado para uma mesma medição de Deep Check fica em cache em memória durante a sessão. Reabrir a Sheet não reexecuta a chamada externa, prevenindo consumo excessivo de quota.
     - Timeout estrito na requisição HTTP.
   - **Critério de Saída**: Antes de qualquer release público ou TestFlight aberto externo, a chamada deverá migrar para proxy de borda (ex.: endpoint dedicado no Cloudflare Worker ou similar), mediante formalização de nova decisão de infraestrutura.
2. **Camada de Serviço / Integração**:
   - Cliente REST dedicado em `NolaggyInfrastructure` (`GeminiConnectionBoosterService`) consumindo o endpoint do Google Gemini (`generateContent`).
3. **Contratos e Isolamento de Módulos**:
   - Para não violar o determinismo estrito do núcleo do motor de score em `NolaggyDomain`, os contratos do Booster (`ConnectionBoosterRequest`, `ConnectionBoosterAdvice`) residem em arquivo isolado ou na camada de caso de uso (`NolaggyApplication`), com protocolo implementado em `NolaggyInfrastructure`.
4. **Tratamento de Falhas e Erros**:
   - Se a requisição ao Gemini falhar por queda de rede, timeout ou quota: a tela modal exibe um estado de erro amigável (*"Não foi possível carregar as dicas no momento"*) acompanhado de um botão claro de **"Tentar novamente"**.

---

## 4. Experiência de Interface (UI / UX)

1. **CTA no Resultado do Deep Check**:
   - Posicionado de forma harmoniosa na tela de resultado do `DeepCheckFeatureView`, como ação secundária ou de aprofundamento (ex.: *"Como melhorar sua conexão"*).
2. **Apresentação em Sheet Nativa**:
   - Ao tocar no CTA, abre uma `Sheet` modal (`ConnectionBoosterSheet`).
   - **Gate de Design e Tokens**: Por ser um estado novo não contemplado no protótipo original (`AGENTS.md` linha 92) e com o gate de `docs/21` aguardando entrega oficial dos novos tokens de Renan, a Sheet utiliza os tokens vigentes do design system (`docs/04` / `NLColor`, `NLTypography`, `NLSpacing`).
   - **Estado de Carregamento**: Shimmer/Skeleton nativo imitando o checklist enquanto a API do Gemini responde.
   - **Estado de Sucesso**: Checklist limpo com ícones nativos (SF Symbols).
   - **Acessibilidade**: Contraste adequado (`NLColor`), suporte a Dynamic Type e VoiceOver.

---

## 5. Responsáveis e Aceite

- **Luiz (Dono do Produto)**: Autorização da funcionalidade e aprovação explícita da decisão transitória de chave client-side para validação rápida.
- **Marco (Produto)**: Validação do equilíbrio do prompt e garantia do escopo não-invasivo.
- **Renan (Design)**: Validação do componente de Sheet e aprovação da composição do novo estado de tela com tokens vigentes.
- **Rian (iOS)**: Implementação do client de serviço, view model e sheet SwiftUI com cache de sessão.
- **Iury (Rede/Score)**: Validação das variáveis de rede injetadas no prompt para garantir coerência técnica.
