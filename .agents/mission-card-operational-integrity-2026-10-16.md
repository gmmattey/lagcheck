# Cartão de Missão — Integridade operacional, distribuição e crescimento

**Data:** 16 de outubro de 2026  
**Patrocínio:** Luiz — autorização de execução  
**Aceite operacional:** Giam  
**Estratégia e orquestração:** Marco

## Problema da pessoa

O jogador precisa abrir o LagCheck e receber um Check honesto. O catálogo que
torna esse caminho possível vence em 19/10/2026 às 12h30 BRT; a telemetria de
produto dos dois clientes aponta para um host que responde 404. Crescer,
publicar um novo Android ou prometer precisão por jogo antes de corrigir essas
duas bases aumenta risco sem gerar valor.

## Resultado observável e ordem autorizada

1. **P0 — continuidade global:** antes do vencimento, existe envelope Schema 3
   assinado, validado pelos dois clientes e entregue no Worker público; uma
   instalação sem cache consegue carregar uma base ainda válida. O Check mede
   os beacons regionais assinados e escolhe pela proximidade observada, nunca
   fixa São Paulo por idioma, país ou ordem do catálogo. iOS e Android enviam
   somente a telemetria mínima já autorizada ao host do Worker ativo.
2. **P1 — verdade de distribuição:** o próximo candidato de cada plataforma
   tem link de compartilhamento Android canônico, privacidade/listings coerentes
   com o archive/AAB e uma matriz explícita do que foi ou não provado em
   aparelho físico.
3. **P2 — ganho só depois da base:** preparar, sem publicar, a melhoria de ASO
   centrada no benefício; manter rotas próprias e comparativo de regiões em
   homologação até haver prova de identidade, paridade e assinatura.

## Escopo e não-escopo

- **Inclui:** rotação segura do catálogo aprovado, regiões AWS GameLift
  homologadas no envelope, pré-leitura regional automática e paritária,
  configuração do endpoint de telemetria já existente, testes e vetores
  proporcionais, correção localizada do URL Android, reconciliação
  documental/local de privacidade e ASO preparada.
- **Não inclui:** novo endpoint, schema novo, nova regra de score/veredito,
  servidor pago, rota própria presumida, redesign, ranking, overlay,
  gamificação, publicação de loja ou promoção de track sem checagem e
  confirmação específica.

## Lane e donos

- **P0:** full flow sistêmica; Camillo faz o gate, Iury é dono de catálogo e
  Worker, Rian é dono das configurações dos clientes, Breno valida. Não alterar
  o `.agents/architecture-plan.md` existente: ele é WIP de outra missão; o
  plano desta missão recebe arquivo isolado.
- **P1:** endpoint/link local em fast lane depois do P0; evidência de
  distribuição com Rian, Breno, Renan e Nico. Privacidade/ads permanece no gate
  sistêmico quando afetar o binário ou declarações externas.
- **P2:** Nico prepara ASO; Iury/Camillo mantêm rotas próprias na homologação
  da Decisão 78/79.

## Critérios de aceite e evidência

| Critério | Donos da prova | Evidência mínima |
| --- | --- | --- |
| Envelope renovado sem regressão semântica | Iury / Camillo | assinatura Ed25519, vetores iOS+Android e resposta pública com versão/datas novas |
| Região automática por proximidade | Iury / Rian / Breno | catálogo com beacons autorizados, vetores de P50/desempate/inconclusivo nos dois clientes e caminho de sessão usando a vencedora |
| Cold start não depende de envelope vencido | Rian / Breno | teste de repositório com relógio pós-vencimento e base/cache renovados |
| Telemetria mantém contrato mínimo e chega ao Worker ativo | Rian / Iury / Breno | testes de URL/payload, `POST` controlado sem PII e resposta do host público |
| Android compartilha só o domínio canônico | Rian / Breno | teste de unidade ou inspeção focada e build afetado |
| Claims, App Privacy e Data safety são coerentes | Nico / Breno / Giam | matriz archive/AAB versus docs/listings; console fica explicitamente não alterado até ordem própria |
| Rotas próprias não viram promessa sem prova | Iury / Camillo | PCAP/identidade, paridade, envelope assinado; sem isso, `pending` e referência regional |

## Riscos e rollback

- A rotação ativa os 48 jogos e as referências globais no envelope Schema 3
  assinado das Decisões 89 e 90; não muda schema nem ativa uma rota própria
  pendente.
- Worker e clientes podem voltar ao último envelope ainda válido; depois do
  vencimento, rollback para envelope vencido não é recuperação.
- Telemetria falha de modo silencioso e jamais bloqueia Check, score ou
  histórico.
- Nenhum upload, App Store Connect, Play Console ou publicação é consequência
  automática desta missão.
