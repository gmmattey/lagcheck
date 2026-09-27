# Decisão 60 — Corte do Atalho de Contexto de Rede

- **Data:** 26 de setembro de 2026
- **Status:** decidido para o candidato a TestFlight
- **Responsáveis:** Marco (integração) e Luiz (decisão de produto)
- **Revisa:** decisão 59, que não entra neste corte

## Decisão

O candidato a TestFlight não inclui o Atalho composto que importaria contexto de rede para o Cockpit. Não haverá payload JSON, ação de importação, botão para adicionar esse Atalho, nem apresentação de frequência, canal, RSSI, operadora ou rádio recebidos por esse fluxo.

Os atalhos nativos já existentes que apenas abrem o LagCheck ou iniciam a medição permanecem fora deste corte: eles não importam contexto adicional nem mudam medição, score ou veredito.

## Efeito no produto

O Cockpit continua mostrando somente leituras observadas pelo próprio app. Quando o iOS não expõe uma frequência Wi-Fi por API pública, o estado continua como **não confirmada**; SSID, RTT, jitter e ausência de dado nunca viram uma banda inferida.

## Não-escopo

- Não muda transporte UDP, score, veredito, histórico, PDF, telemetria, catálogo ou consentimento de dados móveis.
- Não adiciona endpoint, permissão, SDK, coleta de dado ou serviço pago.
- Uma retomada do Atalho exige nova decisão, contrato, testes de integração e validação em iPhone físico antes de entrar em um candidato futuro.
