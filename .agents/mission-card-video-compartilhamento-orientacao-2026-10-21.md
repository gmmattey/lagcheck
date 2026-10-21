# Cartão de Missão — Vídeo de compartilhamento no Resultado

## Enquadramento

- **Problema da pessoa:** ao compartilhar o resultado no TikTok, o vídeo de 14 segundos chega azul e invertido, tornando a leitura do resultado inviável.
- **Resultado esperado observável:** o MP4 vertical gerado localmente mantém as cores da Dark Competitive UI e a mesma orientação vertical do Resultado antes de ser entregue ao seletor nativo.
- **Fora de escopo:** mudar a timeline, copy, métricas, veredito, áudio, integração com TikTok, os destinos de compartilhamento, Android ou qualquer publicação externa.
- **Lane:** Fast lane.
- **Por que esta lane:** correção confinada à conversão de `CGContext` para `CVPixelBuffer` no renderizador iOS, sem contrato novo, persistência, rede ou regra de medição.
- **Fonte de verdade:** Decisões 103 e 104 em `docs/DECISOES.md`; `ShareVideoRenderer` entrega MP4 H.264 1080×1920, 30 fps e 14 s para TikTok e Instagram.

## Donos, aceite e evidência

- **Responsável pela implementação:** Rian (iOS).
- **Aceite operacional:** Giam.
- **Validação:** build do alvo iOS e inspeção do contrato de pixel (`32BGRA` com contexto little-endian premultiplicado) e da transformação UIKit; a reprodução no TikTok em iPhone físico continua obrigatória antes de release.
- **Risco remanescente:** build/teste não substitui a abertura do arquivo no TikTok real; este fluxo depende de encoder e app de destino.
