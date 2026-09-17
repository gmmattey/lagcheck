# Nolaggy — decisão do piloto de Quick Check

**Status:** aprovado para execução local
**Data:** 8 de setembro de 2026
**Responsáveis:** Marco (produto e integração), Renan (experiência), Rian (iOS) e Iury (qualidade de rede)

## Decisão

O desenvolvimento começa por um piloto vertical de **Quick Check**. Ele não é a V1 nem uma promessa de disponibilidade pública. Seu propósito é comprovar, em um iPhone real, que o Nolaggy consegue medir uma rota UDP de referência, interpretar somente dados válidos e comunicar o resultado com honestidade.

O único contexto inicial é **Fortnite no iPhone, mercado BR, região `sa-east-1`**. Até haver evidência específica de infraestrutura do jogo, a interface e a copy tratam a leitura como **estimativa da rota regional de referência para Fortnite**, nunca como ping oficial do jogo.

## Problema e comportamento esperado

Quem quer jogar precisa de uma resposta curta e confiável antes da partida. Em cerca de 15 segundos, o piloto deve medir uma única rota regional de referência e apresentar um resultado determinístico ou assumir claramente que não conseguiu dados suficientes.

O Quick Check envia no máximo 30 probes UDP, com timeout de dois segundos, e exige pelo menos dez respostas válidas correlacionadas à sessão. Com menos que isso, não há score, classificação positiva, recomendação para jogar ou persistência de resultado.

Uma única medição pode ficar ativa. Cancelamento, ida para background ou mudança relevante de caminho de rede encerram a sessão e descartam todos os dados parciais.

## Escopo deste piloto

- Projeto SwiftUI nativo para iPhone, iOS 17 ou posterior.
- Catálogo-base local, estritamente necessário ao único contexto do piloto.
- Domínio determinístico: métricas, score, guardrails, classe, causa e interpretação localizável.
- Orquestração de uma sessão Quick Check, observação de caminho de rede e transporte UDP.
- Telas canônicas de Quick Check em execução e resultado saudável/com risco, com paridade ao protótipo oficial.
- Estados de resultado inconclusivo e cancelado, após composição aprovada por Renan.
- Testes de domínio, sessão e transporte; smoke test em iPhone físico antes de afirmar que a medição funciona.

## Decisões de experiência do piloto

- A referência de composição é o HTML canônico do protótipo iOS. Portanto, o resultado de Quick Check usa o anel de 160 pt mostrado nessa referência; a definição divergente de 216 pt no inventário de componentes será corrigida por Renan.
- Durante a medição, o anel apresenta o RTT atual, sem score. O componente de medição recebe esse valor como dado de apresentação; a regra continua pertencendo ao domínio.
- Inconclusivo e cancelado substituem o score e todas as métricas parciais por uma mensagem neutra, motivo claro e uma única ação de recuperação. Não há nota, insight de desempenho, nem ação de Deep Check.
- O botão de voltar durante a medição é cancelamento explícito: descarta a sessão inteira antes de navegar.
- `Ver detalhes` e `Fazer Deep Check` não aparecem no piloto. A omissão é temporária e existe para não expor ações sem jornada funcional; as telas válidas preservam a hierarquia e os demais elementos do protótipo.

## Fora do escopo

- Deep Check, comparação de regiões, histórico, anúncios, consentimento UMP, Worker remoto, assinatura Ed25519 e catálogo completo de oito jogos/BR-US.
- Conta, telemetria, fallback HTTP/ICMP, VPN ou qualquer otimização de rota.
- Qualquer publicação, TestFlight, configuração no App Store Connect ou criação de infraestrutura externa.

## Gates antes de ligar a medição real

1. Iury registra o contrato verificável do Ping Beacon — payload, resposta, correlação e alvo permitido — e valida-o em iPhone físico.
2. Iury fecha a fórmula de consistência e os vetores que demonstram score, interpolação e guardrails reproduzíveis.
3. Renan aprova a composição dos estados inconclusivo e cancelado, que não existem no protótipo de referência.
4. Rian demonstra, com testes, sessão única, descarte em cancelamento/background/troca de rede e ausência de score com menos de dez respostas UDP válidas.

Enquanto esses gates não forem atendidos, o app pode implementar domínio com vetores controlados e a UI canônica, mas não declara o transporte como funcional nem apresenta resultado de rede como real.

### Registro de evidência física recebida

Em 8 de setembro de 2026, o dono do produto confirmou que o Quick Check foi testado e está funcional em iPhone físico. A confirmação sustenta que houve uma execução física do transporte; ela não informa, por si só, modelo do iPhone, versão de iOS, build, data/hora da execução, tipo de rede, destino efetivamente resolvido, quantidade de probes/respostas ou RTTs observados.

Portanto, o piloto pode ser descrito como **funcional em iPhone físico, conforme confirmação do dono do produto**, mas o registro auditável do gate ainda precisa anexar esses dados mínimos e demonstrar o contrato `NLPG/1` contra o alvo autorizado. Não há inferência desta confirmação para Wi-Fi e celular separadamente, para estabilidade do beacon, nem para ping oficial do Fortnite.

## Critérios de aceite

1. Mesmas amostras, versão de perfil e catálogo retornam o mesmo resultado.
2. O resultado só é mostrado depois de a sessão concluir com dados válidos; nunca durante a coleta.
3. Inconclusivo e cancelado não mostram nota nem recomendação positiva.
4. O app não mistura amostras de redes, sessões ou regiões diferentes.
5. A experiência em execução e os resultados elegíveis têm paridade visual e interativa com o protótipo iOS canônico; os novos estados têm aprovação de design registrada.
6. A validação final do transporte e do ciclo de vida ocorre em iPhone físico, em Wi-Fi e celular. Build local ou simulador não é essa evidência.

## Próximo marco

Ao fechar os quatro gates, o piloto passa a uma demonstração local em iPhone físico. Só então o time decide se expande para o catálogo completo, Worker assinado, Deep Check, histórico e publicidade que formam o MVP.
