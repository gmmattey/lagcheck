# Decisão — Detalhes do resultado e Histórico local

**Data:** 8 de setembro de 2026  
**Estado:** decidido para execução do piloto  
**Responsáveis consultados:** Marco (produto), Renan (experiência), Rian (iOS/persistência), Iury (qualidade de rede)

## Problema e resultado esperado

Uma leitura isolada responde à decisão imediata, mas não permite investigar a evidência nem acompanhar medições válidas ao longo do tempo. A entrega cria Detalhes para a medição concluída e Histórico local para retestar o mesmo contexto, sem transformar dados parciais em resultado.

## Decisão entre frentes

- O HTML canônico continua sendo a referência de composição. Seus números de exemplo são ilustrativos: o app só exibe métricas produzidas pelo domínio.
- O conflito do protótipo em que P99 é maior que “Pior spike” não é reproduzido. Pior spike é sempre o maior RTT UDP válido da própria execução.
- Detalhes inclui explicitamente região de referência, alvo medido e confiança. No piloto, o alvo é uma rota regional de referência (`genericRegion`, confiança média), jamais ping oficial de Fortnite.
- Somente uma avaliação `completed` com ao menos dez respostas UDP válidas gera snapshot e tentativa de persistência. Cancelamento, background, mudança de rede e inconclusivo não exibem Detalhes nem entram no Histórico.
- O snapshot é imutável: contexto, data, score bruto/final, classe, métricas agregadas, causa, região, destino/estratégia, confiança, catálogo, perfil e versão de regra. Histórico nunca recalcula uma leitura com catálogo novo.
- A série de RTTs fica apenas na memória para Detalhes imediatamente após a conclusão. Ao abrir um registro histórico, o app mostra os agregados e informa que a série não foi salva.
- SwiftData fica atrás do repositório de aplicação. Ele remove registros com mais de 90 dias e mantém no máximo 100 registros recentes por jogo; apagar tudo continua reservado a Configurações, fora deste recorte.
- Média de sete dias só aparece com ao menos duas medições válidas em dias distintos nesse período. Tendência só compara duas leituras com o mesmo contexto, região e versão de regra; antes disso, a interface mostra somente o último resultado.

## Composição e acessibilidade

Detalhes preserva cabeçalho, região antes do gráfico e lista de métricas do HTML, adicionando alvo e versões como evidência. Histórico apresenta somente resultados válidos, com reteste acessível e área tocável mínima de 44 pt. Labels e resumos de VoiceOver são localizados em PT-BR e inglês. Não há anúncio nesta implementação do piloto.

## Escopo e validação

Este recorte cobre Quick Check do piloto Fortnite / BR / iPhone. Deep Check, sincronização, catálogo remoto, anúncios e exclusão por Configurações permanecem fora. A validação necessária inclui domínio, repositório, integração da jornada, PT-BR/inglês e comparação interativa com o HTML no mesmo viewport; iPhone físico continua necessário para rede, ciclo de vida, VoiceOver e Reduzir Movimento.
