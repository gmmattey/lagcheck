# LagCheck — pacote local de pré-registro (Google Play, Brasil)

Pacote de revisão local para a ficha `pt-BR` do Google Play. Ele não foi
enviado ao Play Console, não inicia pré-registro e não comprova aprovação ou
publicação.

## Conteúdo

- `source/`: capturas 1080×2400 do emulador Android e fontes da feature graphic.
- `final/`: quatro screenshots 1080×1920 PNG RGB opacos e uma feature graphic
  1024×500 PNG RGB opaca.
- `manifest.json`: proveniência e hipótese de cada screenshot.
- `manifest-feature-graphic.json`: proveniência da feature graphic.
- `previews/`: galeria local de revisão.
- `reports/`: validação mecânica de formato e dimensões.

As telas mostram uma única sessão controlada de **Check Geral**: repouso,
carga, veredito `CONDIÇÕES INSTÁVEIS` e detalhes. Não representam resultado de
jogo específico, não mostram arte de jogos e não são evidência de hardware
físico, distribuição ou aprovação do Google.

## Antes de usar no Console

1. Definir data de produção antes de ativar o pré-registro no Brasil; o Play
   exige lançamento em até 90 dias por país ativo.
2. Conferir o AAB de distribuição e os dispositivos suportados; o AAB de
   pré-registro só declara compatibilidade e não instala o app.
3. Preencher Data safety com a configuração vigente de AdMob, UMP e `AD_ID`, e
   conferir que a política em `https://lagcheck.signallq.com/privacy/` está
   publicada antes de distribuir um build com anúncios.
4. Fazer a revisão visual humana: sem cortes, dados pessoais, notificações,
   IP de terceiros ou promessa de ping de jogo.
