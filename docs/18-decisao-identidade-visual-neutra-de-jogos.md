# Decisão — identidade visual neutra dos jogos

**Status:** aprovada para implementação local  
**Data:** 2026-09-09  
**Donos:** Marco (produto), Renan (design) e Rian (iOS)

## Decisão

O Nolaggy não exibe capa oficial, logo, personagem, cenário, interface, fan art ou imagem obtida na internet para representar jogos. A referência visual externa aprovada nesta decisão informa apenas a densidade e o formato: miniaturas quadradas compactas, listas leves e trilhos horizontais.

O nome localizado do jogo é a identificação primária. A miniatura é uma superfície neutra do Nolaggy, com textura abstrata e símbolo genérico; ela nunca tenta imitar a identidade de uma franquia. Na descoberta, a miniatura mede 72 pt e o alvo de toque continua tendo ao menos 44 pt. Em lista, Histórico e recentes usam a mesma linguagem compacta.

## Fonte de dados e limite técnico

Nenhuma URL, imagem ou metadado de terceiros entra no catálogo para cumprir essa decisão. Enquanto não houver um contrato de identidade abstrata versionada no catálogo assinado, o app usa o componente neutro sem mapeamento por jogo. Isso evita cor, arte ou regra visual hardcoded por título.

O contrato de artes licenciadas anterior fica substituído para a V1. Uma futura integração de arte licenciada exige nova decisão, direitos comprovados, revisão de Renan e Marco e não altera o formato compacto.

## Critérios de aceite

1. Não há IP visual de terceiros no binário, no catálogo ou no fallback.
2. Descoberta usa miniaturas quadradas compactas, sem grid de capas 3:4.
3. A acessibilidade anuncia o nome e a categoria; a miniatura é decorativa.
4. A seleção e a medição funcionam sem asset remoto.
