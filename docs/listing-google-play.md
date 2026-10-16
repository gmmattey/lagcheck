# LagCheck — ficha Google Play (pré-registro Brasil)

Fonte canônica dos metadados e criativos locais do **LagCheck** para a ficha
principal do Google Play. Este documento prepara um rascunho: não confirma
criação no Play Console, revisão, pré-registro ativo ou publicação.

## Estado da campanha

| Campo | Decisão local |
| --- | --- |
| Mercado inicial | Brasil (`pt-BR`) |
| Estado | Rascunho; não ativar pré-registro sem data de produção |
| Janela | Ao ativar em um país, publicar em produção em até 90 dias |
| Recompensa | Nenhuma; o app não oferece produto único/Billing |
| CTA exibido pelo Play | `Fazer pré-registro` |
| Métricas a acompanhar | Pré-registros e conversão em instalação nos 14 dias após o lançamento |

## Dados da aplicação

| Campo | Valor |
| --- | --- |
| Nome | `LagCheck: Rota para Jogos` |
| Tipo | Aplicativo |
| Categoria | Ferramentas |
| Preço | Gratuito |
| Pacote | `com.lagcheck.app` |
| Tags sugeridas | Rede, Velocidade, Jogos multijogador |
| Site | `https://lagcheck.signallq.com` |
| Suporte | `suporte@signallq.com` |
| Privacidade | `https://lagcheck.signallq.com/privacy/` |
| Contém anúncios | Sim — banners AdMob podem aparecer somente em Início e Histórico; nunca no check, resultado ou detalhes |

O nome tem 25 de 30 caracteres. A wordmark nos criativos permanece `lagcheck`
em minúsculas; `LagCheck` é usado em texto corrido e no nome do app.

## Metadados pt-BR

### Nome do app (25/30)

```text
LagCheck: Rota para Jogos
```

### Descrição curta (64/80)

```text
Veja latência, jitter e perda na rota antes de entrar no ranked.
```

### Descrição completa

```text
Antes de entrar na partida, veja como a sua rota está agora.

O LagCheck mede a rota do seu Android até uma infraestrutura de referência. Em vez de transformar números soltos em promessa, ele reúne latência, jitter e perda de pacotes para mostrar uma leitura clara da conexão naquele momento.

O check tem duas fases:
• Em repouso, mede a estabilidade da rota sem tráfego extra.
• Sob carga, observa se a latência muda quando a rede está em uso.

No fim, você recebe um veredito direto:
• Pronto para Ranked quando a rota medida ficou estável.
• Condições instáveis quando houve oscilação relevante.
• Eu evitaria Ranked agora quando a medição encontrou risco maior.
• Inconclusivo quando não houve respostas UDP suficientes para avaliar com segurança.

Abra os detalhes para ver as métricas da sessão e a região de referência usada no check. O LagCheck não reduz ping, não otimiza a rota e não mede diretamente o servidor de uma partida específica.

Use os resultados como leitura da sua conexão neste momento. Uma nova partida, região ou rede pode se comportar de outro jeito.
```

## Criativos locais

O pacote em `store/google-play/pt-BR/pre-registration/` contém a feature graphic
e quatro screenshots Android de uma sessão controlada de **Check Geral** no
emulador. O conjunto não usa capa, logo, personagem, vídeo ou arte de jogos de
terceiros; também não usa Home ou Histórico, que poderiam mostrar anúncio de
teste.

| Peça | Formato | Conteúdo |
| --- | --- | --- |
| Ícone | 512×512 PNG | Ícone clássico, que é o padrão do launcher Android |
| Feature graphic | 1024×500 PNG RGB opaco | Rota celular → Wi-Fi → região de referência; mascote como assinatura lateral |
| Screenshots | 4 × 1080×1920 PNG RGB opaco | Repouso, carga, veredito e detalhes da mesma sessão |

O vídeo com Warzone enviado como referência não integra esta ficha. Ele usa
propriedade de terceiros e o Google Play aceita vídeo de prévia apenas por URL
do YouTube, não por MP4 enviado diretamente.

## Data safety e privacidade — conferência antes do Console

Esta ficha não substitui o formulário do Google Play Console. Antes de enviar
ou ativar pré-registro, conferir o build de distribuição, o comportamento atual
dos SDKs e as declarações dos fornecedores para preencher cada resposta.

- Declarar que o app contém anúncios.
- Revisar AdMob, UMP e a permissão `AD_ID` no formulário de Data safety com a
  documentação atual do Google; não usar a declaração histórica de “sem
  publicidade”.
- Confirmar que dados de publicidade não incluem amostras, score, veredito,
  jogo, região ou telemetria do Worker.
- Conferir a política publicada em `/privacy/` e atualizar qualquer mudança de
  SDK, finalidade ou fluxo de consentimento antes de distribuir um build.
- Usar AAB assinado apenas para declarar dispositivos suportados no pré-registro;
  esse upload não disponibiliza o app para instalação.

## Limites de promessa

- Não chamar a latência medida de “ping do seu jogo”.
- Não atribuir causa a roteador, Wi-Fi ou operadora sem evidência isolada.
- Não prometer eliminar lag, melhorar a conexão, vitória ou desempenho futuro.
- Sem respostas UDP válidas suficientes, o resultado é inconclusivo — sem nota
  inventada ou recomendação para jogar.
