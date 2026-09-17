# Nolaggy — revisão de produto: nome, telas, design system e monetização

**Status:** rascunho de auditoria — levantamento e proposta para discussão, nenhuma decisão
tomada, nenhuma implementação autorizada. Vários pontos aqui **contrariam regras fixas do
`AGENTS.md`** (marca, ativos de design aprovados, custo zero) — isso é intencional: o pedido foi
para reabrir essas perguntas, não para segui-las às cegas. Qualquer item marcado "contraria regra
atual" exige decisão explícita de Marco antes de virar trabalho, não só desta revisão.
**Responsáveis por frente:** Marco (produto/marca/prioridade), Renan (design/voz), Rian
(arquitetura/custo técnico), Iury (o que a mudança faz com a precisão da medição).
**Origem:** pedido para revisar o app inteiro visando um "mini-app eficiente e monetizável",
na continuidade da conversa sobre posicionar o Nolaggy como equivalente iOS do módulo "Modo
gamer" do SignallQ (`docs/19-decisao-modo-gamer-signallq.md`).

## Como ler este documento

Cada seção termina em uma tabela de opções, não em uma escolha. Onde uma opção contraria regra
atual do `AGENTS.md`, isso está marcado explicitamente — não é erro deste documento, é o preço
declarado da opção.

---

## 1. Nome

**Regra atual (`AGENTS.md`):** "Marca oficial: Nolaggy, sempre com `nolaggy` em minúsculas na
wordmark. Não usar 'Nologgy'." Ativos de marca (`design-system/assets/brand/`) estão descritos
como "oficiais e aprovados... não há pendência de criação ou aprovação de marca" (`docs/04-design-
system.md` seção 1.1/1.2). Existe inclusive um símbolo de marca desenhado especificamente em torno
do nome ("o `gg` do wordmark é substituído pelo símbolo compacto... lido como infinito").

**Achado incômodo:** a própria pasta do repositório se chama `Nologgy` (o erro que o `AGENTS.md`
pede para nunca cometer), e há cinco `.xcodeproj` no repositório (`Nolaggy.xcodeproj`,
`Nolaggy 2/3/4/5.xcodeproj`) — sinal de retrabalho ou indecisão de setup, não de nome em si, mas
que vale limpar independente da decisão de marca (ver seção 5).

**Avaliação do nome atual:**
- "Nolaggy" comunica a categoria (jogos, lag) com clareza em inglês; em PT-BR soa a portmanteau
  em inglês, o que é comum em apps de nicho gamer brasileiro, mas é uma escolha, não um dado.
- Já tem investimento real: wordmark, símbolo, paleta, App Icon, protótipo iOS canônico, e um
  produto inteiro de identidade textual em torno do trocadilho `gg`/infinito. Trocar o nome não é
  cosmético — descarta ou reaproveita parcialmente todo o sistema de marca da seção 1 do doc 04.
- Não há evidência registrada de teste de nome com usuário real, pesquisa de concorrência de
  nome ou disponibilidade de App Store/domínio verificada neste repositório.

| Opção | Custo de mudar | Quando faz sentido |
| --- | --- | --- |
| **Manter "Nolaggy"** | Zero — já implementado, testado, com marca completa | Se a única motivação para reabrir o nome era a hipótese do "mini-app do SignallQ" (`docs/19`), e essa hipótese não virar posicionamento público de marca (ponto 19.3, já resolvido como "app independente") |
| Ajustar só a grafia/pronúncia, manter símbolo e conceito | Médio — reaproveita símbolo `gg`, troca só wordmark/App Store listing | Se o problema identificado for pronúncia/memorização, não o conceito |
| Nome novo completo | Alto — reescreve marca, App Icon, App Store, prototype canônico, todos os docs 01–18 que citam "Nolaggy" | Só se houver motivo de produto concreto (conflito de marca registrada, teste de usuário ruim, pivot de posicionamento) — nenhum desses está documentado hoje |

**Proposta:** antes de gastar trabalho de design em um nome novo, registrar **qual problema
concreto o nome atual está causando** (motivo real, não preferência estética) — isso é decisão de
Marco, não uma pergunta que este documento resolve.

---

## 2. Telas — revisão de eficiência do fluxo

Fluxo atual mapeado no código (`Sources/NolaggyApp/`): Home (descoberta de jogo) → Quick Check
(medição) → Resultado → [Deep Check opcional] → [Detalhes opcional] → Histórico / Configurações.

### O que já é eficiente (não mexer sem motivo)

- Home já elimina uma tela: não existe passo de "selecionar plataforma" ou "selecionar região"
  manual antes de medir — plataforma é fixa (iPhone) e a região é automática desde a decisão do
  doc 16. Isso já é um mini-app enxuto no critério mais importante: **taps até o resultado**.
  Hoje são 2 taps (escolher jogo → "Testar conexão") no caminho feliz.
- O card "última medição" na Home permite retestar em 1 tap sem passar pela seleção de jogo de
  novo — já é a otimização que a maioria dos apps de utilidade não tem.
- A tela de resultado já segue "conclusão antes de métrica" de forma disciplinada — não há
  fricção de leitura aí.

### Fricções reais encontradas no código

| Tela/fluxo | Fricção observada | Proposta |
| --- | --- | --- |
| Home — busca expandida | Busca por texto libre + filtro de categoria (`CatalogCategory`) para um catálogo hoje pequeno (poucos jogos no piloto) — complexidade de UI para um problema de escala que ainda não existe | Adiar a busca expansível para quando o catálogo remoto passar de ~15-20 jogos; até lá, grid simples já resolve |
| Resultado → Deep Check → Detalhes | Três profundidades empilhadas (resultado → deep check → detalhes técnicos) sem atalho direto entre a 1ª e a 3ª quando o usuário já sabe o que quer (ex.: usuário técnico voltando para conferir jitter de novo) | Se a persona "usuário técnico" for prioridade para o reposicionamento como mini-app gamer, considerar atalho direto Home → Detalhes técnicos recorrentes (mesma ideia do "retestar" já implementado) |
| Configurações — região manual | Região manual é uma `Menu` dentro de Configurações, achada só por quem já sabe que existe | Aceitável para V1; se a expectativa "mini-app eficiente" incluir usuário avançado que troca de região com frequência, vale promover a um atalho de 1 tap perto do resultado, não só em Configurações |
| Ausência de "modo gamer" por categoria (ver `docs/19`) | Hoje a única forma de saber se a conexão serve para o jogo é medir o jogo específico já catalogado; não há veredito rápido "essa conexão serve para FPS competitivo em geral", útil quando o jogo do usuário não está no catálogo | É exatamente a lacuna que a proposta do doc 19 cobre — a taxonomia de categorias resolve isso sem adicionar tela nova (reaproveita `displayCategory`, proposta 19.2) |

### Proposta de fluxo "mini-app eficiente" (não decidido)

Mini-app, por definição, deve caber em **uma sessão de uso de poucos segundos, sem necessidade de
aprender a navegar**. O fluxo atual já está perto disso. A revisão sugerida não é "redesenhar
telas", é **remover o que ainda não é necessário** (busca/filtro avançado para catálogo pequeno) e
**adicionar o mínimo que falta** (veredito por categoria, do doc 19) em vez de abrir novas
profundidades de navegação.

| Tela | Ação proposta |
| --- | --- |
| Home | Manter estrutura atual; adiar busca expansível/filtro de categoria até o catálogo justificar |
| Resultado | Manter; se doc 19 avançar, adicionar só a linha de categoria/veredito direto (proposta 19.5), sem nova tela |
| Deep Check / Detalhes | Manter como estão — já são "opcionais", não fazem parte do caminho feliz |
| Configurações | Manter; revisar promoção de região manual só se dado de uso mostrar necessidade real |
| Histórico | Fora desta revisão — não foi lido com profundidade; sinalizar para revisão futura se entrar no escopo de monetização (banner, seção 4) |

---

## 3. Design system — o que revisar de fato

O sistema atual (`docs/04-design-system.md`) é incomumente maduro para um MVP1: tokens
completos, regras de contraste/Dynamic Type/VoiceOver/Reduzir Movimento já implementadas, marca
com regras de uso rígidas, protótipo canônico com paridade 1:1 exigida. Isso é um ativo raro —
qualquer revisão "completa" que trate isso como ponto de partida genérico jogaria fora trabalho
real, não só estético.

### Pontos que valem revisão de fato

| Ponto | Observação | Risco de mexer |
| --- | --- | --- |
| Fonte Oxanium (títulos/score) | Fonte de destaque "experimental" (o próprio doc chama assim) — vale confirmar se ainda é a escolha certa ou era um placeholder de piloto | Baixo — troca de fonte é a mudança de menor blast radius em todo o sistema, tokens já centralizam isso em `NLTypography` |
| "Sem estética gamer clichê" (regra atual) | Decisão deliberada de se diferenciar de apps gamer com neon/RGB. Se o reposicionamento como "mini-app do modo gamer" (doc 19) mudar a persona-alvo para alguém que já espera estética gamer, essa regra pode estar desalinhada com o público novo | Alto — é um princípio de 3 itens no topo do doc 04, não um detalhe; mudar isso é decisão de marca, não de componente |
| Dark-mode-only | Decisão deliberada ("sala escura, foco no jogo"). Para um mini-app usado em qualquer contexto (não só "sentado para jogar à noite"), tema claro pode importar mais do que fazia sentido no MVP1 original | Médio — tokens já são `core`→`semantic`, então dá para adicionar tema claro sem reescrever componentes, mas é trabalho real, não cosmético |
| Regra "no máximo 1 ocorrência de accent.primary por tela" | Boa regra para calma visual; para um mini-app que quer maximizar conversão (ex.: CTA de upgrade, ver seção 4), pode entrar em tensão com necessidade de destacar oferta comercial | A tensionar só se/quando houver CTA comercial — não mexer preventivamente |
| Ativos de marca "oficiais e aprovados, sem pendência" | Ver seção 1 — travar isso como não-negociável impede a própria revisão de nome que este documento foi pedido para fazer | Depende inteiramente da decisão da seção 1 |

### Proposta

Não recomendo tratar o design system como "tudo em aberto". Ele é o ativo mais caro de refazer e
o que tem menos motivo documentado para mudar (ao contrário do nome e do fluxo, não há fricção
concreta relatada). Proposta: revisar só os itens da tabela acima que têm gatilho real —
persona-alvo (se doc 19 avançar) e tema claro (se dado de uso pedir) — e não os demais.

---

## 4. Monetização

**Regras atuais que qualquer proposta aqui precisa respeitar ou pedir para revogar
explicitamente:**
- `AGENTS.md`: "Custo operacional recorrente zero é uma restrição de produto. Não adicione
  serviço pago, SDK ou infraestrutura sem decisão explícita do dono do produto."
- `AGENTS.md`: "Publicidade é periférica: banner apenas em Home e Histórico; nunca bloqueia
  medição, score, resultado, histórico ou ação essencial."
- `docs/04-design-system.md` seção 11 já tem o contrato de design pronto para banner (MVP1.1):
  área reservada sem layout shift, nunca sobre Quick/Deep Check/Resultado, rótulo "Anúncio"
  sempre visível.

Ou seja: **já existe uma decisão de monetização tomada** (banner discreto em Home/Histórico,
MVP1.1) — "monetizável" pode significar "ativar o que já foi decidido" antes de significar
"inventar modelo novo".

### Opções, ordenadas por compatibilidade com as regras atuais

| Opção | Compatível com custo zero? | Compatível com "nunca bloqueia medição"? | Observação |
| --- | --- | --- | --- |
| **Ativar `BannerAdSlot` (MVP1.1 já especificado)** | Sim — AdMob tem camada gratuita para o app | Sim — já desenhado para isso | Menor esforço: contrato de design já existe, só falta decisão de "autorizar MVP1.1" + implementação + UMP/consentimento |
| Compra única (ex.: "remover anúncios", "detalhes técnicos ilimitados") | Sim — IAP não tem custo recorrente de servidor | Sim, se não gatar nenhuma tela do caminho feliz | Compatível com espírito de "mini-app": sem assinatura, sem conta, sem servidor de billing próprio (usa StoreKit) |
| Assinatura recorrente (histórico estendido, mais jogos, notificações) | **Não, na prática** — assinatura tende a puxar necessidade de conta/sync/servidor para validar entitlement entre reinstalações, o que contraria "sem conta, sem sincronização" do escopo técnico atual (`docs/03-especificacao-tecnica.md`) | Depende do design | **Contraria regra atual** — precisa decisão explícita de Marco antes de sequer prototipar |
| SDK de ads mais agressivo (intersticial, rewarded) | Sim tecnicamente | **Não** — interstitial após medição tende a interromper o momento "quero saber se posso jogar agora", o oposto da promessa do produto (`docs/07-voz-do-produto.md`: "parceiro que ajuda a decidir", não que atrasa a decisão) | Não recomendado independente de regra — contraria a voz do produto, não só o `AGENTS.md` |
| Parceria/afiliado (ex.: indicar roteador, plano de internet) | Sim | Sim, se for um card discreto pós-resultado, não obrigatório | Precisa golpe de cautela: `docs/07-voz-do-produto.md` já veta linguagem publicitária ("libere seu poder", "modo turbo") — uma recomendação comercial precisa parecer tão sóbria quanto o resto do produto, ou quebra a credibilidade que é o diferencial do app |

### Proposta

1. **Primeiro passo de monetização de menor risco:** autorizar formalmente o MVP1.1 já
   especificado (banner Home/Histórico) — é a única opção com contrato de design, regra de
   posicionamento e limite de intrusão já decididos por escrito. Isso não exige revisão nenhuma,
   só autorização.
2. **Segundo passo, se banner não for suficiente:** compra única via StoreKit (não assinatura) —
   mantém "custo zero" e "sem conta" intactos.
3. **Não recomendado sem decisão explícita e documentada de Marco:** assinatura recorrente ou
   ads intersticiais — os dois contrariam regras hoje inegociáveis do produto, não são ajuste de
   detalhe.

---

## 5. Item avulso encontrado durante a revisão (fora do pedido original)

Cinco `.xcodeproj` no repositório raiz (`Nolaggy.xcodeproj`, `Nolaggy 2/3/4/5.xcodeproj`) e a
pasta do projeto chamada `Nologgy` (o erro de grafia que a marca proíbe). Não decidi apagar nada
— pode ser histórico intencional ou trabalho em andamento de outra pessoa (`AGENTS.md`: "não
apague, reverta ou sobrescreva trabalho alheio"). Sinalizo para confirmação: os `.xcodeproj`
extras ainda são necessários, ou são artefato de retrabalho que pode ser limpo?

---

## Gates antes de qualquer implementação

Mesma cadeia do doc 19: Marco decide prioridade e qual das quatro frentes (nome/telas/design/
monetização) realmente abre → Renan revisa qualquer mudança de marca, voz ou composição visual →
Rian avalia custo técnico e o que quebra em `Infrastructure`/persistência (especialmente para
IAP/assinatura) → Iury confirma que nada aqui muda a régua de score ou a precisão da medição.
Nenhum desses gates foi cumprido. Este documento é insumo para decisão, não especificação pronta.
