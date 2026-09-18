# LagCheck — voz do produto

**Status:** regra de comunicação da V1  
**Idiomas:** PT-BR e inglês  
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
8. **Mantenha a mesma personalidade nos dois idiomas.** Inglês não é tradução palavra por palavra; ele precisa manter a mesma clareza, sobriedade e confiança.

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

## 4. Estrutura por estado

### Resultado saudável

**Estrutura:** conclusão positiva → evidência breve → ação opcional.

> **92 — Excelente**  
> Pronto para jogar. Sua conexão ficou estável nesta medição.

Quando houver detalhe relevante, ele é proporcional:

> Encontramos um pico curto que não deve ser perceptível na partida.

Não usar cautela automática como “não podemos garantir…” depois de toda leitura saudável. A limitação já é contextualizada onde realmente importa, como em estimativas para console/PC e regiões de referência.

### Resultado instável ou com risco

**Estrutura:** impacto provável → causa observada → próxima ação.

> **58 — Risco de lag**  
> Pode haver lag nesta partida. A perda de pacotes apareceu durante a medição.

> Vale investigar antes de jogar. Faça um Deep Check para ver se o uso da rede piora a conexão.

O tom aponta risco sem decretar fracasso. “Pode haver” é diferente de “vai travar”.

### Inconclusivo, cancelado ou indisponível

**Estrutura:** limite claro → motivo simples → ação segura.

> Não conseguimos dados suficientes para avaliar sua conexão. Tente novamente em instantes.

> A conexão mudou durante a medição. Reinicie o teste para termos um resultado confiável.

> Esta região não está disponível agora. Tente novamente mais tarde.

Nunca mostrar score, “pronto para jogar” ou conselho de performance em um estado inconclusivo.

### Deep Check

**Estrutura:** explicar o que será comparado → duração/custo relevante → benefício.

> Vamos comparar sua rede em repouso e durante uso intenso. Leva cerca de 30 segundos e usa Wi-Fi.

> Sua conexão piora quando a rede está ocupada. Downloads ou streaming podem causar lag.

Não chamar o achado de “bufferbloat” na mensagem principal. O termo técnico pode aparecer em detalhes, acompanhado de explicação.

### Estimativa para console ou PC

**Estrutura:** o que foi medido → limite honesto → utilidade do resultado.

> Esta é uma estimativa da rota de internet para sua região de jogo. A conexão do seu console ou PC também pode influenciar a partida.

## 5. Biblioteca inicial de microcopy

| Situação | PT-BR | Inglês |
| --- | --- | --- |
| Home | Veja como sua rede está para jogar. | See how your network is doing for gaming. |
| CTA principal | Testar conexão | Check connection |
| Medindo | Medindo sua conexão com a região selecionada… | Measuring your connection to the selected region… |
| Resultado saudável | Boa condição para jogar agora. Sua conexão ficou estável nesta medição. | Looking good to play now. Your connection was stable in this check. |
| Risco | Pode haver lag nesta partida. Esta medição encontrou instabilidade. | You may experience lag in this match. This check found instability. |
| Inconclusivo | Não conseguimos dados suficientes para avaliar sua conexão. Tente novamente em instantes. | We didn’t get enough data to assess your connection. Try again shortly. |
| Deep Check antes de iniciar | Vamos comparar sua rede em repouso e durante uso intenso. Leva cerca de 30 segundos. | We’ll compare your network at rest and under load. It takes about 30 seconds. |
| Rede mudou | A conexão mudou durante a medição. Reinicie o teste. | Your connection changed during this check. Start again. |
| Histórico vazio | Seus testes aparecerão aqui. | Your checks will appear here. |

## 6. Regras de localização

- PT-BR é a referência de intenção e precisa soar natural no Brasil; inglês é escrito para soar natural, não espelhado literalmente.
- Nomes de produto permanecem: `LagCheck Score`, `Quick Check` e `Deep Check`.
- Unidade e número seguem a localidade do sistema quando aplicável. Siglas técnicas, como `ms` e `%`, permanecem estáveis.
- Texto de ação é curto. A interface deve acomodar PT-BR como caso de expansão, mas a copy não pode depender de truncamento.
- Toda string nova passa por revisão de produto e design quando altera conclusão, risco, recomendação, consentimento ou confiança.

## 7. Checklist de aprovação de copy

Antes de publicar um texto novo, confirme:

1. A mensagem deixa claro o que foi observado?
2. Ela explica a consequência para a partida sem prometer demais?
3. Há uma próxima ação quando a pessoa precisa agir?
4. O texto continua verdadeiro em console/PC, região de referência e resultado inconclusivo?
5. PT-BR e inglês mantêm a mesma intenção e cabem no componente?
6. Ele pode ser entendido sem conhecer jargão de rede?

