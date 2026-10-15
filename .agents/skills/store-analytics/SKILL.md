---
name: store-analytics
description: Analisa métricas disponíveis de descoberta, conversão, ativação, retenção, receita e qualidade de lojas sem comparar definições incompatíveis ou inventar KPIs.
---

# Analytics de loja

Use quando houver exportações autorizadas, CSVs, capturas verificáveis ou APIs
já conectadas. Registre para cada KPI: fonte, período, definição, segmento e
qualidade do dado.

## Regras

- Não calcule CAC, LTV, ARPU, ARPPU ou retenção sem denominador e período
  definidos. Instalação, download, primeira abertura e usuário ativo não são
  sinônimos.
- Não misture dados de Apple, Play e analytics do produto sem preservar a
  definição original. Quando não há dado privado, entregue o esquema de coleta
  e as perguntas a responder, não números estimados.
- Investigue mudança de métrica com versão, país, origem, experimento e
  qualidade (crash/ANR) antes de afirmar causa.

## Saída

Use o contrato de `store-audit`. Inclua: o que mudou, o que os números mostram,
hipóteses alternativas, próxima ação e como invalidá-la.

Um relatório executivo começa pelos dois maiores riscos e traz: (1) variação
observada, (2) definição e qualidade da métrica, (3) causas possíveis, (4)
oportunidade, (5) ação e (6) critério de verificação. Ausência de acesso é um
resultado útil: peça o menor export ou screenshot que elimina a maior incerteza.
