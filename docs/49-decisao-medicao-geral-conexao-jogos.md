# LagCheck — Decisão 49: Medição Geral de Conexão para Jogos

**Status:** decidido pelo Dono do Produto; em implementação  
**Data:** 25 de setembro de 2026  
**Responsáveis:** Luiz (produto), Marco (produto), Renan (design), Rian (iOS), Iury (rede)  
**Complementa:** decisões 14, 18, 28, 35, 41, 42, 43 e 46.

---

## 1. Contexto e Problema

Atualmente, o LagCheck exige obrigatoriamente a escolha de um dos títulos catalogados (ex: Fortnite, COD Mobile, Free Fire, Brawl Stars, Roblox, Minecraft) para iniciar qualquer medição de rota.

Isso gera duas limitações severas de produto e experiência:
1. **Jogos não listados:** jogadores de títulos competitivos no PC, consoles ou mobile cujos jogos não estão no catálogo (como Valorant, CS2, EA Sports FC, Rocket League, League of Legends, Apex Legends, etc.) não encontravam seu jogo e eram forçados a selecionar outro jogo arbitrariamente ou abandonar o aplicativo.
2. **Medição preventiva geral:** usuários que desejam apenas saber se sua conexão de internet e Wi-Fi estão estáveis para jogar qualquer partida online naquele momento, sem querer escolher uma ficha de jogo específica.

## 2. Decisão

1. **Jornada de Conexão Geral para Jogos:** O LagCheck passa a suportar uma medição de Deep Check geral de jogos online, identificada canonicamente pelo identificador de domínio `"generic-gaming"`.
2. **Promessa e Limites de Produto:**
   - O app mede a rota até a infraestrutura regional de referência de jogos online (datacenters onde grande parte dos servidores de jogos operam na região, como AWS GameLift em São Paulo para o Brasil).
   - O app **nunca** inventa ou estima um ping interno da engine de um jogo não listado. O resultado é categorizado com transparência como *“Rota Regional Geral de Jogos (Referência de Datacenter)”*.
   - Estratégia de medição: `genericRegion`; confiança: `medium`; chave de precisão: `regionalReference`.
3. **Plataforma e Vínculo de Equipamento:**
   - A pessoa pode declarar a plataforma pretendida: `iPhone`, `PlayStation`, `Xbox`, `PC` ou `Nintendo Switch`.
   - Para equipamentos externos (Console ou PC), permite declarar o vínculo daquele equipamento com a rede (`Wi-Fi` ou `Cabo Ethernet`), preservando os princípios da Decisão 41.
4. **Pontos de Entrada na Experiência (HIG):**
   - **Empty State na Busca da Aba Jogos:** Ao pesquisar por um jogo não encontrado no catálogo, a interface exibe um card de assistência editorial explicando que o jogo não possui rota dedicada no momento e oferecendo o botão de ação direta: *“Medir Conexão Geral”*.
   - **Card Permanente no Catálogo:** O catálogo de jogos disponibiliza um card de rota neutra para medição geral.
   - **Home:** A Home suporta e reflete o histórico de medições de *"Conexão Geral"* com o mesmo rigor de evidência das decisões 42 e 43.
5. **Custo Operacional Zero:**
   - A rota de referência utiliza a infraestrutura já existente e autorizada (`GlobalProbeRegistry` e beacons UDP regionais GameLift / STUN RFC 5389 / Cloudflare Worker `/v1/load`). Nenhum novo endpoint, serviço pago ou SDK é introduzido.
6. **Critérios de Score:**
   - Aplica o perfil de qualidade `battleRoyaleCompetitive` como referência rigorosa para jogos multiplayer em tempo real, exigindo ao menos 10 respostas UDP válidas para cálculo de score determinístico; caso contrário, o resultado é inconclusivo.

---

## 3. Critérios de Aceite

1. O identificador `"generic-gaming"` é reconhecido pelo `GameContext` e resolvido pelo `RemoteCatalogVerifier` para a região regional prioritária válida.
2. A busca na aba Jogos, quando sem resultados correspondentes, exibe o estado vazio amigável com CTA direto para a medição geral.
3. A medição geral executa o ciclo completo de Deep Check (repouso UDP, teste sob carga com consentimento em celular, STUN e Wi-Fi local).
4. O resultado exibe título "Conexão Geral para Jogos" com visual neutro do LagCheck e badge "Rota Regional de Jogos".
5. O histórico do SwiftData armazena e recupera a medição sem corrupção ou necessidade de migração estrutural.
6. Todos os textos estão localizados em Português (pt-BR), Inglês (en) e Espanhol (es).
