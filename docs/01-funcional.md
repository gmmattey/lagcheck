# LagCheck — documentação funcional

**Status:** referência funcional; escopo atualizado pelas Decisões 67–69 e 88
**Idioma do documento:** PT-BR  
**Sistema mínimo:** iOS 17; Android API 26 (Kotlin/Compose)
**Base:** conversa de concepção do produto compartilhada pela equipe em 7 de setembro de 2026

> **Atualização de reposicionamento (Decisões 50 e 55 — 2026-09-26):** toda referência a Quick Check foi abolida da experiência do usuário e a jornada foi radicalmente simplificada para **Home → Jogo → Check → Veredito**. O veredicto semântico (`GameReadinessVerdict`: *Pronto para jogar*, *Eu evitaria Ranked agora*, etc.) torna-se o protagonista visual imediato. O LagCheck Score (0–100) e as métricas técnicas (ms, jitter, loss) são mantidos para cálculo interno e telemetria, ficando disponíveis sob demanda em "Entender resultado / Ver detalhes". A tab bar passa a ter 2 abas (Início | Jogos), a Conexão Geral atua como fallback em busca sem resultado, e a integridade diagnóstica (Decisão 55) separa com probe isolado enlace local (Wi-Fi/gateway) da rota externa (WAN), avalia bufferbloat multidimensionalmente por perfil, classifica spikes recorrentes, descarta sessões na troca de interface e entrega de 1 a 3 recomendações acionáveis baseadas estritamente em evidência.

> **Decisão de plataforma vigente (67–69):** iPhone continua como plataforma inicial; Android nativo é alvo oficial, com port das regras determinísticas e adaptações de rádio. A influência do gateway no veredito Android é uma divergência autorizada pela Decisão 69. Consulte [Arquitetura Android](./08-arquitetura-android.md) e [evidências locais](auditorias/android-ios-code-parity-2026-10-03.md). Implementação não equivale a publicação.
>
> **Contexto histórico da escolha inicial, anterior às Decisões 67–68 (2026-09-10):** a escolha é de viabilidade de distribuição, não de validação de público-alvo. Testar no Android exige closed testing de 14 dias com 12 usuários antes de qualquer disponibilização mais ampla — fricção desproporcional para um time pequeno validando um conceito. A App Store permite lançar e iterar de forma mais direta. **Isso não significa que o público iPhone BR/US seja quem mais sente a dor que o LagCheck resolve** — jogadores em Android, dados móveis limitados e Wi-Fi doméstico compartilhado provavelmente têm mais incerteza sobre a própria conexão do que o público iPhone típico desses dois mercados. A equipe aceita conscientemente que a V1 valida o conceito e a qualidade técnica nesse subconjunto, não a tese completa de mercado do produto. Quando o Android entrar em escopo, os aprendizados de retenção e comportamento da V1 devem ser tratados como indicativos, não como prova de que funcionam para o público de maior necessidade.

## 1. Visão do produto

LagCheck responde, de forma simples e honesta, a uma pergunta que jogadores fazem antes de entrar em uma partida: **"minha conexão está boa para jogar isso agora?"**

O aplicativo mede a qualidade da rota de rede do dispositivo até regiões de infraestrutura gamer relevantes para o jogo selecionado. Em vez de apresentar um painel técnico de banda larga ou um score numérico abstrato, transforma a medição em um **Veredito de Prontidão (Game Readiness Verdict)** imediato, explica o que foi encontrado e permite investigar detalhes sob demanda.

LagCheck não promete otimizar rota, acelerar a conexão, substituir uma VPN gamer ou medir o ping exato de um jogo quando não houver um destino oficial que permita isso.

## 2. Problema que resolve

Jogadores normalmente descobrem uma conexão ruim no meio da partida. Aplicativos de speed test privilegiam download e upload, métricas que não explicam sozinhas responsividade, picos de latência, instabilidade ou perda de pacotes em jogos.

LagCheck reduz essa incerteza antes da partida. Ele avalia latência, estabilidade e perda sob repouso e sob carga para uma região gamer compatível com o jogo, comunica com clareza o veredicto da partida e indica o que fazer quando a qualidade não for suficiente.

## 3. Público e contexto de uso

O público primário da V1 são pessoas que usam iPhone, especialmente para títulos competitivos e populares. Elas querem uma resposta rápida, sem precisar entender jargão de rede. O Android oficial preserva as regras determinísticas e adapta transporte, rádio, persistência e apresentação à plataforma (Decisões 67–69); a paridade tem limites documentados.

O produto também atende quem joga em PlayStation, Xbox, PC ou Nintendo, desde que trate o resultado como estimativa quando o aparelho testado não for o mesmo que joga. A qualidade da rota de internet pode ser representativa; a conexão local do console ou computador pode não ser.

## 4. Proposta de valor

Em menos de 15 a 30 segundos desde abrir o app, uma pessoa deve conseguir:

1. Escolher um jogo (ou manter o último já selecionado).
2. Tocar em **Check**.
3. Receber imediatamente o **Veredito da Partida** (*Pronto para jogar*, *Eu evitaria Ranked agora*, etc.).
4. Opcionalmente, abrir "Entender resultado" para ver o diagnóstico e detalhes técnicos.

O princípio de interface é: **o veredicto vem antes do score e das métricas**. Os detalhes existem para quem quiser aprofundar, sem bloquear a decisão principal.

## 5. Escopo da V1

A V1 inclui:

- iOS: iPhone (iOS 17+); Android nativo (API 26+), conforme Decisões 67–69;
- oito jogos populares no catálogo inicial: Fortnite, Call of Duty Mobile, Free Fire, PUBG Mobile, Brawl Stars, Roblox, Minecraft e Wild Rift;
- escolha de plataforma: iPhone, PlayStation, Xbox, PC e Nintendo;
- Check único com repouso e carga (Deep Check); Quick Check não é uma opção visível (Decisões 43 e 46);
- LagCheck Score determinístico;
- identificação de causa de lag e recomendação prática;
- detecção de picos de latência;
- comparação entre regiões gamer;
- histórico salvo apenas no dispositivo;
- catálogo remoto de jogos, perfis e regiões;
- interface em PT-BR e inglês. A monetização por anúncios fica explicitamente fora do MVP1 e entra no MVP1.1.

O aplicativo pode ser disponibilizado globalmente na App Store, mas o catálogo com suporte oficial da V1 cobre inicialmente **Brasil e Estados Unidos**. Fora desses mercados, o app não deve prometer disponibilidade de jogo, região ou calibração até que o catálogo inclua o contexto correspondente.

O catálogo é **mobile-first, não mobile-only**. Jogos multiplataforma podem oferecer escolha de PlayStation, Xbox, PC ou Nintendo já na V1. Nesses contextos, o resultado é comunicado como estimativa da rota de internet quando o iPhone não é o aparelho que joga.

Ficam explicitamente fora da V1:

- iPad; distribuição Android depende de validação e autorização próprias, sem prazo de publicação assumido;
- criação obrigatória de conta;
- VPN ou alteração/otimização de rota;
- servidor próprio de speed test;
- promessa de ping exato para jogos sem medição oficial;
- diagnóstico baseado em LLM;
- sincronização em nuvem obrigatória do histórico.

## 6. Conceitos funcionais

| Conceito | Definição para o usuário |
| --- | --- |
| Veredito de Prontidão (`GameReadinessVerdict`) | Resposta principal imediata sobre se a conexão é recomendada para a partida (*Pronto para jogar*, *Eu evitaria Ranked agora*, *Atenção*, *Inconclusivo*). |
| Check | Medição de qualidade de rota do jogo (repouso UDP + estresse sob carga controlada). A nomenclatura "Deep" é detalhe interno. |
| LagCheck Score | Nota técnica de 0 a 100 calculada deterministicamente pelo motor, mantida para histórico, detalhes e telemetria. |
| O que encontramos | Diagnóstico honesto dos sintomas observados (perda de pacotes, oscilação de estabilidade, impacto sob carga) sem alegações causais infundadas. |
| Região gamer | Região de infraestrutura usada como referência para avaliar a rota. Não é necessariamente o servidor do jogo. |
| Confiança | Grau de proximidade entre a medição e a experiência real esperada no jogo. |
| Spike | Pico pontual de latência que pode causar travadas, atraso ou teleporte no jogo. |

## 7. Jornada principal

```text
Primeira vez / Novo jogo:
Abrir app → Escolher jogo → Confirmar plataforma/vínculo → CHECK → VEREDITO
                                                                     ├→ Testar novamente
                                                                     └→ Entender resultado (Diagnóstico + Detalhes Técnicos)

Usuário recorrente:
Abrir app → Último jogo já selecionado → CHECK → VEREDITO
```

Não haverá onboarding longo antes do primeiro teste. Permissões e perguntas aparecem apenas quando forem necessárias para executar ou qualificar a medição.

### 7.1 Home

Objetivo: responder imediatamente à pergunta "posso jogar agora?" e permitir disparar o Check em um toque.

Conteúdo e comportamento, nesta ordem:

1. **Estado Atual / Último jogo testado**: exibe o jogo recente, plataforma anterior memorizada e CTA proeminente para iniciar o **Check**.
2. **Histórico contextual**: link limpo ("Últimos checks ›") levando ao histórico de vereditos do jogo.
3. **Alternar jogo**: acesso direto à aba Jogos.
4. **Menu secundário (`…`)**: acesso aos Ajustes, Suporte e Políticas.

A Home não é um dashboard técnico, não exibe score 0–100 no topo e não disputa a atenção do usuário com shelves de catálogo concorrentes.

### 7.2 Seleção do jogo e do contexto

Ao selecionar um jogo, o usuário escolhe onde joga: iPhone, PlayStation, Xbox, PC ou Nintendo.

O catálogo determina quais plataformas aparecem para cada jogo; o app não oferece uma plataforma que não esteja configurada como compatível. Isso permite suporte a consoles e PC sem fazer alegações de precisão indevidas para todo o catálogo.

Para console ou computador, quando influenciar a interpretação do resultado, o app pergunta de forma curta como o equipamento está conectado: Wi-Fi ou Ethernet.

- Se o jogo ocorre no próprio iPhone, a medição tem a maior representatividade possível: mesmo dispositivo, interface e conexão.
- Se o console/PC usa Wi-Fi, a estimativa é mais próxima da experiência real.
- Se usa Ethernet, o app informa que a rota de internet tem alta confiança, mas que a conexão local é estimada.

O usuário pode iniciar o LagCheck com uma única ação depois dessas escolhas.

### 7.3 Medição ao Vivo: Trilha de Teste (Decisão 34)

Objetivo: demonstrar a rota real dos pacotes em tempo real, eliminando gauges abstratos e identificando com precisão a origem de qualquer instabilidade.

Durante o teste, a tela apresenta a **Trilha Viva de Medição (`MeasurementLiveTrail`)** estruturada em 3 nós verificáveis:
1. `[ Seu iPhone ]`: Origem do tráfego local.
2. `[ Wi-Fi local / Rede móvel ]`: Primeiro salto, aferido via micro-rajadas UDP no gateway local (`en0`) e diagnóstico de frequência (2.4 GHz vs 5 GHz).
3. `[ Servidor / Região Gamer ]`: Destino de infraestrutura de referência (AWS GameLift, Azure PlayFab ou Valve A2S).

A trilha exibe:
- Animação de pacotes fluindo entre os nós com cadência proporcional ao RTT ($P50$);
- Evaporação visual de pacotes em caso de perda (*packet loss*);
- Fase 1 (Repouso, ~15s) e Fase 2 (Sob carga controlada, ~15s via Cloudflare Worker);
- Destaque visual de estresse e saturação de buffer (`MeasurementStressLocation`), discriminando se o gargalo é no enlace sem fio doméstico ou na rota externa da operadora.

Se a conexão de rede mudar durante o teste (ex.: de Wi-Fi para celular), o teste é cancelado e a leitura parcial descartada, garantindo integridade e confiabilidade.

### 7.4 Tela de Resultado: Veredito em Primeiro Lugar (Decisões 35 e 50)

O resultado é centrado na tomada de decisão imediata do jogador competitivo:

1. **Veredito da Partida (Protagonista Visual):**
   - Veredito verbal em destaque absoluto:
     - `PRONTO PARA JOGAR`: *"Sua conexão está estável para [Jogo] agora."*
     - `EU EVITARIA RANKED AGORA`: *"Detectamos perda de pacotes durante o teste."*
     - `CONDIÇÕES INSTÁVEIS`: *"Oscilação de latência ou perda moderada detectada."*
     - `INCONCLUSIVO`: *"Dados insuficientes para avaliar com segurança."*
   - Linha discreta de métricas essenciais logo abaixo:
     `28 ms · 2 ms jitter · 0% perda` (ou o sintoma prejudicial detectado em destaque).

2. **O Que Encontramos (Diagnóstico Honesto):**
   - Substitui a trilha de rede causal por uma prestação de contas dos sintomas observados, sem assumir a culpa de um nó sem evidência isolada:
     - `Perda de pacotes`: 🟢 Nenhuma detectada / 🔴 3,2% (Prejudicial)
     - `Estabilidade`: 🟢 Estável / 🟡 Oscilando
     - `Sob uso da internet`: 🟢 Estável / ⚠️ Degradação relevante
     - `Destino testado`: [Cidade] · referência regional

3. **Barra de Ações:**
   - Botão Primário: **Testar novamente** (reinicia o Check do mesmo jogo).
   - Botão Secundário: **Entender resultado** (expande diagnóstico detalhado e abre detalhes técnicos com Score 0–100, P50/P95, spikes e dados sob carga).
   - *Nota de MVP:* Atalhos para "Otimizar Conexão" ou assistentes por IA (Gemini Connection Booster) ficam ocultos na jornada principal até a validação das hipóteses de retenção.

### 7.5 Unificação do Check e Validação sob Carga (Wi-Fi e Rede Móvel)

A experiência de medição é unificada sob o nome único de **Check** (Decisões 43, 46 e 50):
- **Em Wi-Fi:** Executa rota em repouso por UDP e rota sob carga controlada (até 10 MB via endpoint seguro `/v1/load` do Cloudflare Worker).
- **Em Rede Móvel:** Executa rota em repouso por UDP e rota sob carga controlada com o mesmo limite de 10 MB e até 15 s. Exige **confirmação explícita de uso de dados móveis** antes de iniciar (teto de 10 MB). Sem consentimento, a jornada é cancelada sem dados parciais.
- **Integridade da Execução:** Durante o Check, a interface exibe feedback calmo e contínuo (sem antecipar score, números oscilantes ou explicações prematuras).
- **Troca de Rede:** Transição Wi-Fi ➔ Rede Móvel ou Rede Móvel ➔ Wi-Fi durante a sessão cancela tudo imediatamente, descarta dados parciais da memória sem persistência e não retoma automaticamente.
- **Integridade Diagnóstica:** O app nunca infere que o Wi-Fi é o culpado com base na latência da rota remota (WAN). Diagnósticos de enlace local exigem medição isolada e confirmada.

### 7.6 Detalhes da conexão

Esta área atende pessoas que querem evidência técnica profunda sem poluir o veredicto principal. Pode mostrar:

- LagCheck Score (0–100) calculado internamente;
- série temporal da latência;
- latência mediana (P50), P95 e P99;
- jitter e perda de pacotes;
- quantidade e pior spike;
- região e tipo de destino usado na medição;
- confiança da estimativa;
- comparação entre repouso e sob carga.

### 7.7 Histórico

O histórico é local e organizado por prontidão e títulos de jogos (Decisão 50). Em vez de apresentar uma lista de números e scores abstratos, foca na estabilidade do jogo:
- Lista os últimos vereditos (Ready, Caution, Not Ready) por jogo e plataforma;
- Cada jogo mantém no máximo 100 medições e resultados com mais de 90 dias são removidos automaticamente;
- Para cada jogo, o ritual local de Histórico pode resumir os últimos 7, 14 ou 30 dias somente quando houver pelo menos 3 Checks válidos e comparáveis em 2 dias. O resumo informa a quantidade de vereditos observados; inconclusivos aparecem separados e nunca são tratados como falha ou entram na fração de prontidão. Não prevê a conexão, não aponta causa e não compara contextos distintos;
- A pessoa pode apagar todo o histórico nas configurações;
- Permite disparar um novo Check do jogo a partir de qualquer entrada histórica.

### 7.8 Navegação e abas

A navegação da V1 é enxuta e focada na ação (Decisão 50):
- **Tab Bar de 2 abas:**
  1. **Início:** Estado atual, atalho direto de Check para o último jogo, histórico contextual ("Últimos checks ›") e menu `…` para Ajustes.
  2. **Jogos:** Catálogo com busca e filtros rápidos. No estado vazio de busca ("jogo não encontrado"), exibe o card de assistência com fallback para "Fazer Check Geral".
- **Histórico:** Acessível contextualmente na Home e pelo menu de Ajustes.
- **Ajustes:** Acessível pelo menu `…`, permitindo consultar idioma, apagar histórico local, suporte e políticas de privacidade. A seleção de região é automática pelo motor e oculta da navegação comum.

### 7.9 Widget de prontidão por jogo (Decisão 88)

O widget é um atalho para repetir uma medição, não um monitor em tempo real nem uma promessa sobre a próxima partida. iOS 17+ e Android API 26+ devem mostrar o último **Check válido** daquele app: arte editorial autorizada do jogo, nome, região, P50, veredito semântico e, quando houver, a nota de bufferbloat.

- A arte é sempre a fonte oficial disponível na versão instalada daquela plataforma: no iOS, catálogo assinado validado e cache/asset do iOS; no Android, catálogo assinado validado e cache/resource do Android. Um cliente nunca recebe imagem, cache ou captura do outro.
- O toque é uma intenção explícita de medir. Ele abre o app no mesmo jogo, plataforma e vínculo externo do Check exibido e inicia um novo Check somente após resolver esse contexto no catálogo válido atual. Não mede no background, não reutiliza o veredito antigo e não chama o Worker além do Check normal.
- Se o resultado tiver mais de quatro horas, for inconclusivo, ou o jogo/arte não estiverem mais disponíveis no catálogo válido, o widget não mostra P50 nem veredito antigo. Mantém, quando possível, a arte editorial do jogo com CTA curto para novo Check; sem arte válida, usa identidade neutra do LagCheck.
- A capa não pode ser logo, capa oficial, personagem ou arte licenciada de terceiro. É a arte editorial autoral já autorizada pelo catálogo (Decisões 18, 44 e 71).
- Home Screen usa arte com gradiente escuro e veredito legível; Lock Screen retangular usa miniatura. As famílias iOS circular e inline preservam leitura de telemetria e não são forçadas a exibir arte ilegível. Live Activity/Dynamic Island não faz parte desta entrega.

## 8. Critérios de confiança e modulação da linguagem

LagCheck explicita internamente o tipo de alvo medido e o vínculo do equipamento, modulando o rigor do veredito e a linguagem de apresentação.

| Nível | Situação | Confiança | Impacto no Veredito e Apresentação |
| --- | --- | --- | --- |
| A — jogo oficial | Endpoint oficial do jogo no iPhone. | Muito alta | Linguagem direta: *"Latência medida para [Jogo]"*. Veredito com thresholds nominais. |
| B — infraestrutura do jogo | Infraestrutura oficial dedicada (AWS GameLift, Azure PlayFab, Valve A2S). | Alta | Linguagem confiante: *"Estimativa de alta confiança para [Jogo]"*. |
| C — proxy regional gamer | Região gamer compatível; destino de referência no iPhone. | Média/alta | Linguagem regional: *"Latência regional estimada para [Jogo]"*. |
| D — região genérica / console | Equipamento externo (console/PC) ou rota genérica de referência. | Média | **Veredito mais conservador:** exige margem de segurança de +10% nos limites para emitir `PRONTO PARA RANKED`. Copy cautelosa: *"Estimativa da rota de internet para console/PC"*. |

O app jamais afirma "seu ping no Fortnite é 24 ms" se não mediu um destino oficial ou específico do Fortnite. Nesses casos, usa expressões como **"latência regional: 26 ms"** ou **"estimativa para Fortnite: 24–31 ms"**.

## 9. Métricas, Diagnóstico Honesto e Recomendações Baseadas em Evidência (Decisão 55)

O motor calcula métricas de rede no dispositivo e as transforma em um diagnóstico honesto em **"O que encontramos"**, uma causa primária coerente e até 3 recomendações diretamente acionáveis.

### 9.1 Separação com Evidência Isolada: Enlace Local vs Rota Externa
1. **Probe Local de Gateway:** O app descobre dinamicamente o gateway padrão na interface Wi-Fi (`en0`) via tabela de rotas do sistema operacional. Nunca assume IP fixo `.1`.
2. **Medição Local:** Dispara 5 datagramas UDP com timeout curto (200 ms). Se o gateway responder, calcula RTT, jitter e loss locais. Se não responder (firewall doméstico fechado para UDP local), classifica o enlace local como **"não observável"** (`unobservable`), sem inventar dados nem presumir falha.
3. **Regra de Causalidade:**
   - Só classifica o problema como **"Instabilidade no Wi-Fi/roteador doméstico"** quando o RTT local estiver elevado (>15 ms) ou houver perda/jitter local comprovado pelo probe.
   - Caso o gateway responda estável (ou seja não observável) e o destino gamer apresente oscilação, o problema é classificado com precisão como **"Instabilidade na rota externa / operadora"**.

### 9.2 Diagnóstico de Frequência Wi-Fi (2.4 GHz vs 5 GHz)
- A identificação da frequência Wi-Fi é classificada em 4 níveis de confiança: `.high`, `.medium`, `.low` e `.unknown`.
- **Integridade:** Se o nível for `.low` ou `.unknown`, o app **não afirma a banda** nem gera recomendações de troca. É expressamente proibido usar a latência de servidores remotos para inferir se o Wi-Fi é 2.4 GHz ou 5 GHz.
- Se for confirmado 2.4 GHz com confiança `.high` ou `.medium` em jogos competitivos, gera finding informativo e recomendação prioritária de troca para 5 GHz.

### 9.3 Bufferbloat e Impacto sob Carga Multidimensional por Perfil
A sensibilidade ao estresse de rede (`deep-load-impact-v2`) deixa de usar um corte único e passa a ser proporcional à tolerância do jogo:
- `BATTLE_ROYALE_COMPETITIVE` (ex: Fortnite, COD Mobile, Free Fire): Delta P50 material $\ge 15$ ms; severo $\ge 35$ ms.
- `MOBILE_REALTIME` (ex: Brawl Stars, Wild Rift): Delta P50 material $\ge 25$ ms; severo $\ge 50$ ms.
- `CASUAL_REALTIME` (ex: Roblox, Minecraft): Delta P50 material $\ge 40$ ms; severo $\ge 80$ ms.
Além da mediana P50, a avaliação detecta:
- Jitter sob carga ($> 10$ ms de aumento = material);
- Perda sob carga ($> 2\%$ de perda induzida = severo);
- Spikes induzidos por saturação de buffer.

### 9.4 Spikes Recorrentes vs Isolados e Latência de Cauda
- **Spike Isolado:** 1 a 2 eventos pontuais (ex: scan periódico de Wi-Fi do sistema). Informa no diagnóstico sem rebaixar severamente o veredito.
- **Spikes Recorrentes:** $\ge 3$ spikes durante o teste ou 2 spikes em uma janela de 5 probes. Trata como falha crítica de estabilidade para partidas ranqueadas.
- **Latência de Cauda ($P95/P50$):** Razão $P95/P50 \ge 1.8$ em conexões com P50 aparentemente aceitável sinaliza instabilidade de cauda, alertando que o jogo pode sofrer micro-congelamentos inesperados.

### 9.5 Qualidade da Amostra e Invalidação Precoce
- Exige um mínimo absoluto de 10 respostas UDP válidas.
- **Interrupção Precoce:** Se houver 4 timeouts consecutivos nos primeiros 6 probes ou taxa de perda inicial $\ge 70\%$, a sessão é interrompida como `inconclusive(poorSampleQuality)` em vez de forçar o usuário a esperar 15 segundos para receber um erro previsível.

### 9.6 Hierarquia de Causas e Coocorrência
Quando múltiplos problemas ocorrem em simultâneo, o app seleciona uma **causa principal** e até duas **secundárias**:
1. Perda de pacotes crítica ($>1\%$ em competitivo);
2. Latência incompatível com o perfil;
3. Picos severos recorrentes de latência;
4. Instabilidade contínua (jitter elevado);
5. Rede saturada sob uso simultâneo (Bufferbloat);
6. Latência de cauda elevada ($P95/P50 \ge 1.8$).
- **Regra de Coocorrência:** Jitter alto associado a degradação sob carga é consolidado como *"Instabilidade sob uso da internet"*.

### 9.7 Matriz de Recomendações Baseadas em Evidência
O LagCheck não exibe dicas genéricas. Apresenta de 1 a 3 ações diretamente ligadas às causas confirmadas:

| Evidência Comprovada | Recomendação Prioritária (Voz Direta HIG) |
|---|---|
| Wi-Fi 2.4 GHz confirmado com alta confiança | **Conecte-se à rede Wi-Fi 5 GHz** para evitar interferências. |
| Degradação severa sob carga (Bufferbloat) | **Pause downloads e streaming** em outros aparelhos durante a partida. |
| Perda de pacotes local comprovada no Gateway | **Aproxime-se do roteador** ou reinicie seu equipamento Wi-Fi. |
| Perda de pacotes remota (Gateway estável) | **Instabilidade na rota da operadora.** Evite partidas ranqueadas agora. |
| Spikes recorrentes com enlace local limpo | **Verifique fontes de interferência** próximas ao celular ou roteador. |
| NAT Restrito em jogo P2P / Co-op | **Habilite UPnP no roteador** para evitar falhas de pareamento. |

### 9.8 Topologia de NAT Relevante por Jogo
A informação de NAT (Aberto, Moderado, Restrito ou CGNAT) obtida via STUN leve (RFC 5389) **só é exibida na interface** quando o jogo selecionado possuir arquitetura dependente de NAT (P2P/Co-op). Em jogos com servidores dedicados (Valorant, Fortnite, LoL, etc.), o status de NAT permanece oculto para não gerar alarme falso.

## 10. Catálogo de jogos e regiões

O catálogo remoto define, por jogo e mercado:

- identificador, nome e arte do jogo;
- plataformas compatíveis;
- gênero/perfil de qualidade esperado;
- regiões relevantes;
- tipo de medição e confiança;
- limites usados pelo score e recursos habilitados.

Isso permite atualizar regiões, perfis e limites sem exigir uma nova versão do aplicativo. O catálogo não altera a promessa de medição: ele apenas seleciona o contexto correto e como o resultado deve ser comunicado.

### 10.1 Regras de negócio para classificação dos jogos

A classificação de um jogo tem três objetivos diferentes e não intercambiáveis:

| Classificação | Finalidade | Impacto no produto |
| --- | --- | --- |
| Categoria de descoberta | Ajudar a pessoa a encontrar o jogo. | Organiza busca e Home: FPS, Battle Royale, MOBA, Casual e Cloud. |
| Perfil de exigência de rede | Definir quanto latência, jitter, perda e spikes afetam a experiência. | Seleciona os limites do LagCheck Score, as causas e os textos de recomendação. |
| Estratégia de medição | Definir quais regiões e destinos podem representar o jogo naquele mercado. | Define o alvo do teste, a confiança e a linguagem de precisão permitida. |

Um jogo pode pertencer a uma única categoria principal de descoberta e ter múltiplas etiquetas secundárias, mas deve ter **um único perfil de rede ativo por combinação de jogo, plataforma e mercado**. Isso impede que o mesmo teste seja avaliado contra regras conflitantes.

Os perfis ativos da V1 são:

| Perfil | Uso | Princípio de avaliação |
| --- | --- | --- |
| `BATTLE_ROYALE_COMPETITIVE` | Battle royale competitivo, como Fortnite. | Rigor alto para estabilidade e spikes, além de latência. |
| `MOBILE_REALTIME` | Jogos mobile de ação em tempo real, como COD Mobile, Free Fire e Wild Rift. | Prioriza consistência e resposta rápida no próprio dispositivo. |
| `CASUAL_REALTIME` | Jogos casuais com interação em tempo real. | Aceita limites menos severos, sem ocultar perda ou instabilidade relevantes. |

O mapeamento inicial é: Fortnite, Call of Duty Mobile, Free Fire e PUBG Mobile em `BATTLE_ROYALE_COMPETITIVE`; Brawl Stars e Wild Rift em `MOBILE_REALTIME`; Roblox e Minecraft em `CASUAL_REALTIME`. Perfis de FPS competitivo e Cloud Gaming ficam reservados para uma ampliação futura do catálogo.

Os nomes e os limites numéricos desses perfis serão definidos no catálogo remoto e podem evoluir sem atualização do app. A categoria não define se uma conexão é boa: o perfil de rede é quem define a régua.

### 10.2 Elegibilidade de um jogo no catálogo

Um jogo só pode aparecer como testável em um mercado quando houver, para aquele contexto:

1. Pelo menos uma plataforma suportada;
2. Um perfil de rede ativo;
3. Uma ou mais regiões de referência;
4. Uma estratégia de medição permitida;
5. Um nível de confiança e uma mensagem de precisão compatível;
6. Textos de resultado e recomendação nos idiomas publicados.

Se faltar qualquer um desses elementos, o jogo não inicia teste nesse contexto. Ele pode ser omitido da busca ou aparecer como indisponível, com explicação curta; a decisão de UX será única para todo o catálogo. A V1 não usa destinos obtidos de forma obscura nem testa infraestrutura de terceiros sem autorização/documentação apropriada.

### 10.3 Seleção de região e alvo da medição

Ao iniciar o teste, o app resolve o contexto nesta ordem:

1. Jogo selecionado;
2. Mercado/país do catálogo;
3. Plataforma informada;
4. Perfil de rede;
5. Regiões candidatas permitidas pelo catálogo assinado;
6. Melhor estratégia de medição disponível, de nível A a D;
7. Região de referência escolhida pela pré-leitura UDP ou pela escolha manual da pessoa.

Na V1, o mercado reconhecido para esse processo é Brasil ou Estados Unidos. A localidade do sistema só ordena mercados já publicados; não fixa mercado, região ou destino. A disponibilidade global na App Store não substitui a elegibilidade de catálogo para iniciar uma medição.

A pré-leitura é parte da mesma sessão e escolhe somente a região de referência antes do Quick Check ou do Deep Check. Ela não escolhe servidor do jogo, não muda matchmaking e não autoriza prometer ping oficial.

**Atualização de UX (2026-09-10):** a seleção deixou de ter uma tela de confirmação/escolha no meio da jornada de medição — ao tocar em "Iniciar", a pré-leitura resolve o candidato e a medição já começa, sem segundo toque. A escolha manual não é mais feita por sessão: é uma preferência persistida em Configurações (menu nativo "Região de referência"), aplicada automaticamente a toda sessão futura enquanto o candidato escolhido continuar válido para o jogo/mercado/plataforma medidos. Se deixar de ser válido, a sessão volta para automático em vez de falhar. Sem candidato viável (automático ou preferido), o resultado continua inconclusivo, sem troca silenciosa de destino. A regra de seleção em si (desempate, privacidade, gates) não mudou e está em [Decisão de seleção regional automática](./DECISOES.md#decisão-16).

O Quick Check mede a região assim escolhida. O Deep Check mede essa mesma região no repouso e sob carga; impacto sob carga continua complementar e não altera o score principal. Uma referência mais rápida não altera automaticamente a região real usada pelo jogo e não deve ser apresentada como recomendação de troca de servidor sem evidência de que essa troca é possível no jogo.

### 10.4 Regras de plataforma e representatividade

| Contexto selecionado | Regra funcional de confiança |
| --- | --- |
| iPhone no próprio aparelho | O teste representa diretamente o dispositivo e a interface usados para jogar. É o cenário de maior confiança permitido pela estratégia de medição. |
| Console/PC em Wi-Fi | O teste representa a rota de internet e a conexão local de forma próxima, desde que o telefone esteja na mesma rede Wi-Fi. |
| Console/PC em Ethernet | O teste representa bem a rota de internet; a parte local do equipamento é estimada. |
| Aparelho em outra rede | O teste não é representativo e não deve ser tratado como teste daquele console ou PC. |

Se a pessoa declarar Wi-Fi para o equipamento externo, o app assume que ele está na mesma rede do iPhone até que haja evidência contrária. Essa é uma simplificação consciente da V1 e deve ser comunicada como estimativa quando necessário.

### 10.5 Regras de classificação do resultado

Para cada medição, o motor aplica exclusivamente o perfil ativo do jogo e classifica a qualidade usando latência, jitter, perda, spikes, consistência e, no Deep Check, degradação sob carga.

- O score é determinístico: mesmas amostras e mesmo perfil produzem o mesmo resultado.
- A classificação nominal — por exemplo, Excelente, Bom, Risco de lag — vem do score e dos guardrails do perfil.
- Guardrails prevalecem sobre uma média aparentemente boa. Perda de pacotes, picos severos ou instabilidade sob carga podem limitar a classificação e precisam aparecer na explicação.
- A causa principal é a condição com maior impacto observada. Se houver várias, o resultado principal usa uma só causa e os detalhes mostram as demais.
- O catálogo pode alterar limites por perfil, mas não pode remover a indicação de confiança nem permitir uma promessa de precisão superior ao nível de medição disponível.

### 10.6 Contrato funcional das métricas

Cada resultado precisa guardar e poder exibir as métricas abaixo. Os valores são calculados a partir de amostras válidas do mesmo teste e da mesma rota; não se combinam amostras de redes, regiões ou execuções diferentes.

| Métrica | Cálculo/definição | Unidade | Uso no produto |
| --- | --- | --- | --- |
| Latência por amostra | Tempo de ida e volta de uma transação de probe válida. | ms | Alimenta o gráfico vivo e a distribuição de latência. |
| Latência mediana (P50) | Valor abaixo do qual ficam 50% das amostras válidas. | ms | É o "ping" principal apresentado no resultado. Evita que um pico isolado distorça a leitura. |
| P95 | Valor abaixo do qual ficam 95% das amostras válidas. | ms | Mostra a latência ruim recorrente, mesmo quando a mediana parece boa. Fica em Detalhes e no Deep Check. |
| P99 | Valor abaixo do qual ficam 99% das amostras válidas. | ms | Expõe a cauda mais severa; é diagnóstico avançado em Detalhes. |
| Jitter | Variação entre amostras consecutivas de latência válidas; a V1 usa a média das diferenças absolutas consecutivas. | ms | Indica instabilidade contínua. Pode aparecer no resumo e influencia score/causa. |
| Perda de pacotes | Proporção de probes enviados que não tiveram resposta válida dentro do tempo configurado: `timeouts / probes enviados × 100`. | % | É uma métrica crítica: mesmo baixa, pode limitar a classificação em perfis competitivos. |
| Spike | Amostra válida que ultrapassa o limite de pico do perfil, considerando um limite absoluto e/ou desvio relevante em relação à mediana do próprio teste. | contagem | Mostrado no resumo e no gráfico. A regra exata é configurável por perfil. |
| Spike severo | Spike que ultrapassa o limite severo do perfil. | contagem | Aciona guardrail mais forte e aparece como causa prioritária quando relevante. |
| Taxa de spikes | `spikes / amostras válidas × 100`. | % | Distingue um pico isolado de instabilidade repetida. Fica em Detalhes e alimenta consistência. |
| Pior spike | Maior latência válida observada no teste. | ms | Explica o pior evento no Deep Check/Detalhes. Não substitui P95 ou P99. |
| Consistência | Indicador derivado de jitter, P95/P50, taxa de spikes e perda, normalizado pelo perfil ativo. | 0–100 | Alimenta o score e pode apoiar uma explicação simples como "conexão instável". Não substitui as métricas brutas. |
| Latência sob carga | P50 calculado durante a fase de carga controlada do Deep Check. | ms | Avalia se uso concorrente da rede prejudica a partida. |
| Aumento sob carga | `P50 sob carga − P50 em repouso`. | ms | Identifica degradação sob carga; embasa a recomendação sobre downloads e streaming. |

#### Regras de coleta e validade

- Uma amostra só é válida quando a resposta corresponde ao probe enviado e chega dentro do timeout do teste. Respostas inválidas, duplicadas ou tardias não entram em P50, P95, P99 ou jitter.
- Um timeout conta para perda, mas não recebe uma latência artificial. Isso impede que a mediana esconda perda e evita contaminar percentis com valores inventados.
- O Quick Check planeja até 30 probes, com timeout de 2 segundos por probe. Com pelo menos 10 respostas válidas, gera score e contabiliza os timeouts como perda. Com menos de 10 respostas válidas, o resultado é **inconclusivo**, não uma nota baixa.
- O MVP não troca UDP por HTTP ou ICMP quando os probes falham. Sem respostas UDP suficientes, o app explica que não foi possível medir a rota gamer naquela conexão e sugere tentar outra rede.
- O Deep Check calcula as métricas de repouso e sob carga separadamente. Nunca usa as duas fases como uma única distribuição.
- Mudança de caminho de rede, interrupção explícita, erro do destino ou quantidade insuficiente de amostras torna o teste cancelado ou inconclusivo; não gera LagCheck Score.
- Cada resultado persiste versão do perfil, região, tipo de alvo e versão da fórmula. Isso torna histórico e suporte auditáveis quando o catálogo evoluir.

#### Regras de apresentação

| Superfície | Métricas exibidas | Regra |
| --- | --- | --- |
| Durante o Quick Check | Latência atual, perda acumulada, spikes acumulados e gráfico. | Valores parciais não recebem score nem conclusão antes do encerramento. |
| Resultado principal | P50 como Ping, jitter, perda e número de spikes. | Mostra primeiro a conclusão, depois até quatro métricas. |
| Detalhes | P50, P95, P99, jitter, perda, spikes, pior spike, taxa de spikes, região, alvo e confiança. | Expõe dados brutos e derivados para quem quer investigar. |
| Resultado do Deep Check | Todas as métricas relevantes, score em repouso, P50 em repouso, P50 sob carga e impacto sob carga. | Deve explicar se a carga alterou materialmente a experiência sem reescrever o score de repouso. |

#### Regras de score e guardrails

O **LagCheck Score** varia de 0 a 100 e é uma avaliação do contexto selecionado, não um indicador genérico de internet. Ele combina componentes de latência, estabilidade, perda e spikes, ponderados pelo perfil de rede do jogo.

No Deep Check, o score principal continua representando a conexão em repouso. A fase sob carga gera uma leitura separada de **impacto sob carga**, expressa pelo aumento de latência e pela classificação de estabilidade. Ela nunca reescreve o score de repouso; o resultado pode, por exemplo, mostrar "92 — Excelente em repouso" e "Sob carga: +67 ms, risco de lag".

Os pesos, limites de faixa e valores de guardrail ficam no catálogo remoto versionado. Eles precisam ser publicados por perfil e testáveis, mas não ficam hardcoded na interface. A fórmula-base da V1 atribui 35% à latência (P50), 30% à perda de pacotes, 20% ao jitter e 15% a spikes/consistência. As seguintes regras são invariantes na V1:

1. Perda de pacotes, spikes severos e instabilidade sob carga podem limitar a classificação mesmo com P50 baixa.
2. Um score alto não pode ocultar uma causa crítica observada; a explicação precisa mencioná-la.
3. Confiança da medição não entra no score de qualidade. Ela qualifica quão diretamente o teste representa o jogo.
4. Resultado inconclusivo, cancelado ou sem amostras suficientes não recebe score, classificação positiva nem recomendação de jogar.
5. A classificação textual é derivada do score limitado pelos guardrails do perfil: `90–100 Excelente`, `75–89 Ótimo`, `60–74 Instável` e `0–59 Risco de lag`.

| Faixa | Classificação | Mensagem principal |
| --- | --- | --- |
| 90–100 | Excelente | Pronto para jogar. |
| 75–89 | Ótimo | Pronto para jogar. |
| 60–74 | Instável | Você pode sentir lag. |
| 0–59 | Risco de lag | Vale investigar antes de jogar. |

#### Calibração inicial: `BATTLE_ROYALE_COMPETITIVE`

| Métrica | Excelente | Ótimo | Instável | Risco de lag |
| --- | ---: | ---: | ---: | ---: |
| P50 | ≤ 40 ms | ≤ 60 ms | ≤ 90 ms | > 90 ms |
| Jitter | ≤ 8 ms | ≤ 15 ms | ≤ 25 ms | > 25 ms |
| Perda | 0% | até 1% | até 3% | > 3% |

Guardrails deste perfil:

- Perda acima de 3% limita o resultado a **Risco de lag**.
- Dois ou mais spikes severos limitam o resultado a **Instável**.
- P50 acima de 100 ms limita o resultado a **Risco de lag**.
- Um spike é uma amostra acima de `P50 + 30 ms` e de pelo menos 80 ms.
- Um spike severo é uma amostra acima de `P50 + 80 ms` e de pelo menos 150 ms.

Esses limites são a calibração inicial de lançamento e permanecem versionados no catálogo para validação e ajuste posterior com medições reais.

#### Calibração inicial: `MOBILE_REALTIME`

| Métrica | Excelente | Ótimo | Instável | Risco de lag |
| --- | ---: | ---: | ---: | ---: |
| P50 | ≤ 50 ms | ≤ 80 ms | ≤ 120 ms | > 120 ms |
| Jitter | ≤ 12 ms | ≤ 20 ms | ≤ 35 ms | > 35 ms |
| Perda | 0% | até 1% | até 5% | > 5% |

Guardrails deste perfil:

- Perda acima de 5% limita o resultado a **Risco de lag**.
- Dois ou mais spikes severos limitam o resultado a **Instável**.
- P50 acima de 130 ms limita o resultado a **Risco de lag**.
- Um spike é uma amostra acima de `P50 + 40 ms` e de pelo menos 100 ms.
- Um spike severo é uma amostra acima de `P50 + 100 ms` e de pelo menos 200 ms.

#### Calibração inicial: `CASUAL_REALTIME`

| Métrica | Excelente | Ótimo | Instável | Risco de lag |
| --- | ---: | ---: | ---: | ---: |
| P50 | ≤ 70 ms | ≤ 110 ms | ≤ 170 ms | > 170 ms |
| Jitter | ≤ 20 ms | ≤ 35 ms | ≤ 50 ms | > 50 ms |
| Perda | 0% | até 1% | até 3% | > 3% |

Guardrails deste perfil:

- Perda acima de 3% limita o resultado a **Risco de lag**.
- Três ou mais spikes severos limitam o resultado a **Instável**.
- P50 acima de 180 ms limita o resultado a **Risco de lag**.
- Um spike é uma amostra acima de `P50 + 60 ms` e de pelo menos 140 ms.
- Um spike severo é uma amostra acima de `P50 + 140 ms` e de pelo menos 300 ms.

## 11. Monetização — arco MVP1 → MVP1.1 → MVP2

**Decisão registrada (2026-09-10):** a monetização do LagCheck segue um arco em três etapas, não um modelo único fixado desde já.

1. **MVP1 — sem monetização.** Nenhuma biblioteca de anúncio, SDK de consentimento, unidade de anúncio, identificador publicitário ou preço entra no binário inicial. O objetivo do MVP1 é validar medição, catálogo e qualidade técnica, não receita.
2. **MVP1.1 — anúncios como ponte.** Anúncios nativos em Home, Histórico, Jogos e Resultado no Android e iOS, conforme as Decisões 96 e 97.
3. **MVP2 — assinatura anual como modelo principal.** A intenção é migrar a monetização primária de anúncios para uma assinatura anual, condicionada a recursos que ainda não existem no MVP1/MVP1.1. **O recurso (ou conjunto de recursos) que justifica o pagamento anual é uma decisão pendente** — listada em §14 — e precisa estar definida antes de o MVP2 entrar em escopo de arquitetura. Anúncios podem continuar coexistindo com a assinatura (ex.: removidos para assinantes) ou serem descontinuados; isso também é decisão do MVP2, não desta versão do documento.

Nada neste arco compromete os princípios de §8 e §9: confiança do resultado, causa e recomendação nunca dependem do que o usuário paga.

### 11.1 Publicidade — MVP1.1

Publicidade não faz parte do MVP1 e nenhuma biblioteca de anúncio, SDK de consentimento, unidade de anúncio ou identificador publicitário entra no binário inicial. O app pode ser distribuído sem anúncios enquanto a medição, o catálogo e a promessa de resultado são validados.

No MVP1.1, o LagCheck poderá ser monetizado com anúncios sem comprometer a confiança na medição ou atrasar a resposta que trouxe a pessoa ao app.

Formato vigente pelas Decisões 96 e 97: **AdMob Native Advanced em Home, Histórico, Jogos e Resultado** no Android e iOS, integrado ao fluxo de rolagem e identificado como publicidade. Não haverá anúncio em tela cheia nem anúncio recompensado.

Rede de publicidade: **Google AdMob**, sem mediação. No Android, as unidades nativas substituem os banners adaptativos da Decisão 82; no iOS, são uma integração nova autorizada pela Decisão 97.

Privacidade de publicidade prevista para o MVP1.1: o app usa o **Google User Messaging Platform (UMP)** para obter e gerenciar consentimento quando aplicável ao mercado, expõe "Opções de privacidade" quando necessário e não solicita App Tracking Transparency (ATT). Sem ATT, o app usa anúncios contextuais ou limitados conforme o estado de consentimento e as regras aplicáveis.

Regras do MVP1.1:

- Nenhum anúncio é exibido durante o Quick Check ou o Deep Check.
- Um anúncio nunca cobre latência ao vivo, estado do teste, resultado, causa de lag, recomendação ou ações de "Testar novamente", "Ver detalhes" e "Fazer Deep Check".
- Em ambos os clientes, anúncios só aparecem em Home, Histórico, Jogos e Resultado, depois do conteúdo e das ações essenciais de cada tela. Sem anúncio carregado, não há bloco vazio nem rótulo isolado.
- Publicidade não altera score, classificação, confiança, catálogo de jogos nem recomendação. A mesma medição produz o mesmo resultado com ou sem anúncio.
- O app identifica conteúdos patrocinados de forma clara e não apresenta anúncio como sugestão técnica do LagCheck.
- A experiência UMP de consentimento/privacidade é avaliada antes da inicialização do AdMob quando exigida pelo mercado. Ela preserva as regras acima e está disponível em PT-BR e inglês quando for exibida ao usuário.

Anúncios recompensados e qualquer recurso que venda "otimização" ficam fora de escopo em qualquer versão. Assinatura paga fica fora do MVP1 e do MVP1.1; ela é a aposta de monetização principal do MVP2, conforme §11.

## 12. Requisitos de experiência e linguagem

- Dark mode é a experiência visual principal, sem estética gamer estereotipada, excesso de neon, gauges ou muitos cards.
- O jogo é o protagonista; a ferramenta de rede fica em segundo plano.
- Capas dos jogos trazem cor e contexto. O LagCheck Score é o elemento visual distintivo de resultado.
- A linguagem é direta e útil: o que aconteceu, o que isso significa para a partida e o que fazer agora.
- A interface suporta PT-BR e inglês desde a V1. Isso inclui onboarding eventual, estados de erro, resultados, detalhes, histórico, privacidade/consentimento e identificação publicitária.
- A marca oficial é **LagCheck**. O wordmark é a assinatura principal; o "gg" em forma de infinito é o símbolo compacto da marca.

## 13. Critérios de aceite do MVP

1. Uma pessoa consegue abrir o app, escolher um jogo/plataforma e receber um Quick Check em aproximadamente 15 segundos, sem conta.
2. O resultado traz score, classificação, conclusão em linguagem comum e métricas resumidas.
3. Uma mudança de Wi-Fi para celular durante a medição cancela o teste e não gera resultado misto.
4. Para medições indiretas, a UI deixa claro que o dado é uma estimativa regional, sem alegar ping exato do jogo.
5. Um resultado com risco oferece uma ação clara para novo teste ou investigação por Deep Check.
6. O histórico local permite retestar um jogo e acompanhar sua evolução recente.
7. O catálogo pode mudar jogos, regiões e perfis sem atualização do app.
8. Todas as superfícies do MVP1 funcionam em PT-BR e inglês.

Os requisitos de publicidade acima não são critério de aceite do MVP1; passam a ser critérios do MVP1.1.

Estes oito critérios são exclusivamente funcionais e técnicos. Dados de retenção, engajamento e negócio continuam úteis para priorização, mas não bloqueiam por si só uma evolução de escopo aprovada. Notificação, widget, Live Activity ou outro mecanismo de retorno exigem decisão, Cartão de Missão e evidência proporcionais; sua entrada não altera os critérios de honestidade diagnóstica, custo zero ou consentimento aplicáveis (Decisão 85).

### 13.1 Sinais de priorização após o MVP1

Dados agregados do App Store Connect e a telemetria mínima já autorizada em `POST /v1/telemetry` (retenção e reteste, sem PII/IP, SSID, BSSID, amostras brutas, IDFA ou localização) ajudam a ordenar melhorias. Eles não são gate para iniciar MVP1.1 nem substituem decisão de produto, revisão de privacidade, evidência técnica ou autorização de publicação. A declaração pública e de App Store deve permanecer coerente com esse contrato; ver `docs/62`.

## 14. Decisões pendentes

- Lista inicial dos cerca de dez jogos e seus mercados prioritários.
- Textos de recomendação por causa e por idioma.
- Critérios para oferecer automaticamente o Deep Check.
- Qual recurso (ou conjunto de recursos) do MVP2 justifica cobrança de assinatura anual — ver §11. Sem essa definição, o MVP2 não entra em escopo de arquitetura.
- Priorização e recorte de notificação, widget ou outro mecanismo de retorno; cada um exige decisão registrada e evidência proporcional (Decisão 85).
