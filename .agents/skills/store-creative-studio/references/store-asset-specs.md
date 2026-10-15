# Perfis de exportação e fontes mutáveis

Os perfis locais são guardrails para gerar e testar arquivos. O console e a
documentação oficial no dia do upload prevalecem.

| Perfil Nico | Saída | Regras validadas localmente | Estado |
| --- | --- | --- | --- |
| `appstore-iphone-6.3-portrait` | 1206×2622 PNG RGB | dimensão exata, PNG/JPEG, sem alpha | screenshot iPhone atual |
| `appstore-iphone-6.9-portrait` | 1290×2796 PNG RGB | dimensão exata, PNG/JPEG, sem alpha | screenshot iPhone atual |
| `appstore-product-page-header` | 3840×1646 PNG RGB | dimensão exata, sem alpha | creative asset Apple |
| `google-play-phone-portrait` | 1080×1920 PNG RGB | dentro de 320–3840px, razão ≤2:1, sem alpha | recomendado para promoção; confirmar necessidade |
| `google-play-feature-graphic` | 1024×500 PNG RGB | dimensão exata, PNG/JPEG sem alpha | feature graphic Play |

Referências oficiais consultadas em 15/10/2026:

- Apple: [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), [creative assets](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications) e [upload screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/).
- Google Play: [preview assets](https://support.google.com/googleplay/android-developer/answer/9866151) e [store listing best practices](https://support.google.com/googleplay/android-developer/answer/13393723).

Apple aceita de uma a dez screenshots e não aceita alpha. Google exige ao
menos duas screenshots, permite até oito por tipo de dispositivo, e a feature
graphic é 1024×500, JPEG ou PNG 24-bit sem alpha. Não derive que todo formato
é obrigatório: depende das plataformas que o app efetivamente suporta.
