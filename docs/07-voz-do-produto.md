# LagCheck — voz do produto

**Status:** regra de comunicação da V1  
**Idiomas:** PT-BR, inglês e espanhol
**Documentos relacionados:** [Funcional](./01-funcional.md) · [Sistema de design](./04-design-system.md) · [Governança](./05-governanca-e-fluxo-de-trabalho.md)

## 1. A voz do LagCheck

LagCheck fala de forma **direta, calma e precisa**. É um parceiro que entende que a pessoa quer jogar, traduz o que a rede mostrou e ajuda a decidir o próximo passo — sem dramatizar uma oscilação e sem inventar uma certeza.

Não fala como operadora de internet, streamer, gamer caricato ou painel técnico. Não precisa provar que é inteligente usando jargão. Sua credibilidade vem de dizer com clareza o que foi medido, o que isso pode significar na partida e o que vale fazer agora.

## 2. Princípios de escrita

1. **Comece pela conclusão.** Primeiro diga se a condição parece boa, instável, arriscada ou inconclusiva. Métricas entram como evidência em seguida.
2. **Fale da medição, não de uma promessa.** Use “nesta medição”, “pode causar”, “parece” e “estimativa” quando forem necessários. Não garanta desempenho em uma partida futura.
3. **Diga o que aconteceu, o que isso significa e o próximo passo.** Uma boa mensagem quase sempre resolve essas três perguntas em duas frases curtas.
4. **Seja otimista quando houver evidência.** Resultado saudável merece uma resposta positiva e simples: “Pronto para jogar.” Não transforme clareza em cautela vazia.
5. **Seja honesto no inconclusivo.** Dados insuficientes não são uma nota baixa e não recebem recomendação positiva. Explique o limite e ofereça uma ação possível.
6. **Traduza antes de detalhar.** “Sua conexão ficou instável” vem antes de “jitter alto”. Termos técnicos aparecem nos detalhes ou quando ajudam diretamente a agir.
7. **Use frases curtas e verbos ativos.** Prefira “Tente novamente” a “Uma nova tentativa poderá ser realizada”.
8. **Mantenha a mesma personalidade nos três idiomas.** Inglês e espanhol não são tradução palavra por palavra; precisam manter a mesma clareza, sobriedade e confiança.

### 2.1 Diretriz Inegociável: Zero Cara de IA e o Gamer Não Lê (Decisão 64)

- **O Gamer NÃO LÊ:** O jogador competitivo está no lobby com a call do Discord aberta. Ele tem pressa, adrenalina e zero paciência para parágrafos explicativos.
- **Proibição de Cardlização em Excesso:** Nada de interface com 10 cards flutuantes empilhados parecendo dashboard corporativo ou gerado por prompt de IA. A interface é um cockpit esportivo contínuo, limpo e escuro.
- **Proibição de Textão e Floreios:** É proibido blocos didáticos, duplas de título com subtítulo longo, ou introduções com "Dicas gentis para melhorar sua experiência".
- **A Regra do Discord:** Qualquer status, aviso ou alerta na tela precisa poder ser dito em uma frase curta pelo jogador para os amigos na call:
  - *Certo:* "Minha rota pro Valorant tá lisa" ou "Meu boneco vai ficar voltando no tempo (micro-teleporte)".
  - *Errado:* "Foi detectada uma modulação adversa na rota primária decorrente de oscilações no enlace local".
- **Visual, Rápido e na Veia:** Bateu o olho, entendeu em 1 segundo. Métricas profundas ficam guardadas sob demanda em "Dados da Rede".

## 3. Vocabulário

### Preferir

| Contexto | Vocabulário preferido |
| --- | --- |
| Decisão | pronto para jogar, vale investigar, tente novamente |
| Medição | conexão, rede, região selecionada, medição, resultado |
| Impacto | pode causar lag, ficou instável, piorou durante o uso da rede |
| Ação | testar de novo, ver detalhes, fazer Deep Check |
| Precisão | estimativa, região de referência, dados suficientes, não foi possível medir |

### Evitar

| Evitar | Por quê |
| --- | --- |
| “Zero lag”, “rede perfeita”, “garantido”, “nunca mais lag” | Promete algo que o produto não controla |
| “Sua internet está péssima”, “jogo impossível”, “crítico” sem contexto | É alarmista e não ajuda a agir |
| “Packet loss”, “throughput”, “handshake” sem tradução | Cria jargão sem ajudar a decisão |
| “Amassou”, “OP”, “GG easy” | Envelhece rápido e exclui parte do público |
| “Libere seu poder”, “domine o servidor”, “modo turbo” | Soa publicitário e contradiz a proposta confiável |
| “Ping do seu jogo” quando a rota é de referência | Induz precisão que a medição não tem |

## 4. Estrutura por estado (Ready for Ranked — Decisão 50)

O veredicto semântico é a manchete de maior hierarquia visual; o score numérico (0–100) e os números isolados deixam de ser protagonistas.

### Pronto para jogar (`.ready`)

**Estrutura:** Veredito afirmativo → resumo contextual de estabilidade → telemetria compacta.

> **● PRONTO PARA RANKED**  
> Sua conexão está estável para Valorant agora.  
> `28 ms PING · 2 ms JITTER · 0% PERDA`  
> `Estabilidade ━━━━━━━━━━━━━━━━━━━●`  
> Nenhuma oscilação relevante foi encontrada durante o teste.

### Evitaria Ranked agora (`.notReady`)

**Estrutura:** Recomendação honesta sobre partida competitiva → sintoma prejudicial observado → telemetria compacta e achados.

> **▲ EU EVITARIA RANKED AGORA**  
> Detectamos perda de pacotes durante o teste.  
> `41 ms PING · 18 ms JITTER · 3,2% PERDA`  
> ▲ Perda de pacotes detectada  
> ▲ Picos de latência  
> ● Resposta do destino normal

Usamos deliberadamente **“Eu evitaria Ranked agora”** ou **“Condições ruins para Ranked”**, em vez de prometer que uma partida vai necessariamente funcionar ou falhar. Não decretamos o futuro; apontamos o risco concreto no jogo.

### Atenção / Condições instáveis (`.caution`)

**Estrutura:** Alerta de oscilação → causa de estresse observada → convite para entender o resultado.

> **▲ CONDIÇÕES INSTÁVEIS**  
> Sua conexão oscilou durante o teste ou piorou sob uso simultâneo da internet.  
> `Picos de latência detectados · Jitter elevado`

### Inconclusivo, cancelado ou indisponível (`.inconclusive`)

**Estrutura:** Limite claro sem emitir veredicto → orientação simples.

> **— INCONCLUSIVO**  
> Não recebemos respostas suficientes para avaliar sua rota com segurança. Tente novamente em instantes.

Nunca mostrar score, “pronto para jogar” ou recomendação de partida em um estado inconclusivo.

## 5. Biblioteca de microcopy

| Situação | PT-BR | Inglês | Espanhol |
| --- | --- | --- | --- |
| Home (Headline) | PRONTO PRA JOGAR? | READY TO PLAY? | ¿LISTO PARA JUGAR? |
| CTA Principal (Check) | FAZER CHECK | RUN CHECK | HACER CHECK |
| Check em andamento | VERIFICANDO SUA ROTA | CHECKING YOUR ROUTE | COMPROBANDO TU RUTA |
| Micro-telemetria 1 | Verificando estabilidade… | Checking stability… | Verificando estabilidad… |
| Micro-telemetria 2 | Procurando perda de pacotes… | Looking for packet loss… | Buscando pérdida de paquetes… |
| Micro-telemetria 3 | Testando a conexão sob uso… | Testing connection under load… | Probando conexión bajo uso… |
| Micro-telemetria 4 | Comparando com o perfil do jogo… | Comparing with game profile… | Comparando con el perfil del juego… |
| Veredito Ready | ● PRONTO PARA RANKED | ● READY FOR RANKED | ● LISTO PARA RANKED |
| Veredito Not Ready | ▲ EU EVITARIA RANKED AGORA | ▲ I'D AVOID RANKED RIGHT NOW | ▲ EVITARÍA RANKED AHORA |
| Veredito Caution | ▲ CONDIÇÕES INSTÁVEIS | ▲ UNSTABLE CONDITIONS | ▲ CONDICIONES INESTABLES |
| Veredito Inconclusivo | — INCONCLUSIVO | — INCONCLUSIVE | — INCONCLUSO |
| Reteste | TESTAR NOVAMENTE | RETEST | PROBAR DE NUEVO |
| Entender conexão (Ready) | Entender minha conexão > | Understand my connection > | Entender mi conexión > |
| Entender problema (Not Ready) | Entender o problema > | Understand the problem > | Entender el problema > |
| Fallback busca vazia | Não encontrou seu jogo? Fazer Check Geral | Didn’t find your game? Run General Check | ¿No encontraste tu juego? Hacer Check General |
| Histórico contextual | Último check | Recent check | Último check |
| Trilho rápido | SEUS JOGOS | YOUR GAMES | TUS JUEGOS |

## 6. Regras de localização

- PT-BR é a referência de intenção e precisa soar natural no Brasil; inglês e espanhol são escritos para soar naturais, não espelhados literalmente. O espanhol é pan-hispânico, claro e formal sem rigidez.
- O idioma efetivo é o idioma do sistema, salvo escolha explícita e ativa da pessoa no LagCheck. Nenhum texto apresentado, inclusive VoiceOver, erro, formatação textual e retorno da IA, pode consultar outro locale.
- Nomes de produto permanecem: `LagCheck Score` e `Deep Check`. `Quick Check` pode existir somente como nome técnico interno, nunca em copy para a pessoa.
- Unidade e número seguem a localidade do sistema quando aplicável. Siglas técnicas, como `ms` e `%`, permanecem estáveis.
- Texto de ação é curto. A interface deve acomodar PT-BR como caso de expansão, mas a copy não pode depender de truncamento.
- Toda string nova passa por revisão de produto e design quando altera conclusão, risco, recomendação, consentimento ou confiança.

## 7. Checklist de aprovação de copy

Antes de publicar um texto novo, confirme:

1. A mensagem deixa claro o que foi observado?
2. Ela explica a consequência para a partida sem prometer demais?
3. Há uma próxima ação quando a pessoa precisa agir?
4. O texto continua verdadeiro em console/PC, região de referência e resultado inconclusivo?
5. PT-BR, inglês e espanhol mantêm a mesma intenção e cabem no componente?
6. Ele pode ser entendido sem conhecer jargão de rede?
