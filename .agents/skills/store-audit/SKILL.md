---
name: store-audit
description: Audita por que um app pode não crescer nas lojas, reunindo evidências de produto, ficha, aquisição, conversão e retenção sem fabricar dados privados.
---

# Auditoria Nico

Use para “por que o app não cresce?”, diagnóstico de distribuição ou plano de
prioridades. Carregue somente as skills de profundidade que a evidência pedir;
esta skill não substitui ASO, publicação ou analytics.

## Método

1. Descubra o produto e as plataformas com
   `python3 tools/nico_validate.py discover --root .`; confirme no
   repositório, pois o comando não vê console nem produção.
2. Separe o funil em descoberta → página → instalação → primeira abertura /
   ativação → retenção → receita. Marque o estágio sem dado como **não
   disponível**, não como diagnóstico.
3. Compare a promessa da ficha com funcionalidades e limites comprovados do
   app. Para LagCheck, a medição é do aparelho até infraestrutura de referência;
   não prometa ping de jogo, resultado futuro, causa de operadora ou zero lag.
4. Priorize no máximo cinco oportunidades por impacto esperado, confiança,
   esforço, custo, dependência e métrica. Proposta não é resultado.

Use [o contrato de relatório](references/report-contract.md) e a
[matriz de evidência](references/evidence.md). Para validação de textos, use
`tools/nico_validate.py validate` com um JSON de metadados.

## Limite

Não conclua que a causa é ASO, retenção ou qualidade sem dados que distingam
essas hipóteses. Uma ficha pública pode ser pesquisada; dados privados só são
consultados quando a conexão já estiver autorizada.
