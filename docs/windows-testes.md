# Windows: testes e validação da biblioteca

> Estado em 11 de novembro de 2026, após as Etapas 0 a 2 (Decisão 118). Separa o que foi executado do que depende de Windows físico.

## Executado

A lógica da biblioteca (sem a camada de interface) foi compilada com o compilador Kotlin 2.0.20 e rodada com JUnit 4, com o runtime do Compose no classpath. O Gradle do projeto não resolve plugins no ambiente de desenvolvimento remoto, então esta é a evidência disponível lá. **Rodar `./gradlew :desktop:test` em uma máquina com acesso ao Google Maven continua sendo o gate oficial.**

| Teste | O que prova |
| --- | --- |
| `HeroSelectorTest` (6) | Sem jogo, sem destaque; jogo não instalado nunca é destaque; prioridade último iniciado, depois último executado, depois instalado recentemente, depois título; ordem estável. |
| `LibraryStoreTest` (6) | Favoritos e último iniciado; ids com símbolos; arquivo ausente ou corrompido não derruba; migração do arquivo antigo sem apagá-lo; jogos conhecidos persistidos; entrada inválida ignorada sem derrubar as outras. |
| `LibraryReconcilerTest` (14) | Jogo novo entra; jogo sumido vira "conhecido, não instalado" e mantém favorito; launcher indisponível, disco desconectado, manifesto ilegível ou varredura incompleta nunca contam como remoção; varredura só afeta a própria plataforma; instalação alterada atualiza e preserva histórico; reinstalado volta; manual intocado; deduplicação por título normalizado e por pasta, instalado vence, títulos diferentes não se mesclam, resultado independe da ordem. |
| `NetworkSupportResolverTest` (7) | Casa por id de loja e por nome exato; **não** casa por trecho de título; sem catálogo vira conexão geral; jogo solo verificado não recebe diagnóstico; todo id da tabela existe no `catalog-base.json` real. |
| `LibraryRepositoryTest` (12) | Biblioteca vazia; scanner com falha; escolha do usuário; favorito e último iniciado sobrevivem a reabrir; desinstalado continua conhecido e não abre; launcher fora do ar não apaga; conhecidos sobrevivem a reabrir; duplicata aparece uma vez e favorito vale no grupo; rede vem do resolvedor; filtros e busca. |
| `LibraryCoreTest` (6) | Parsers de manifesto da Steam e da Epic; `Found` versus `Unavailable`; biblioteca Steam inacessível; manifesto ilegível versus ferramenta filtrada; linhas `appid`/tamanho do VDF não viram pasta. |

| `ArtworkDiskCacheTest` (8) | Guardar e recuperar por jogo e tipo; id com símbolos vira nome seguro; falha "não existe" dura dias e passageira dura minutos; sucesso limpa o lembrete; teto de 200 MB remove o menos usado; imagem maior que o teto não se apaga; atualizar apaga só aquele jogo; pasta inexistente não lança. |
| `GameArtworkResolverTest` (12) | Baixa, guarda e depois usa o cache sem novo download; cache do launcher vence a internet; arquivo local que não é imagem é ignorado; segunda URL quando a primeira não existe; "não existe" e falha passageira lembradas com prazos diferentes; resposta que não é imagem não vira cache; download desligado usa só o que já está no disco; jogo sem fonte remota vai direto à miniatura; 8 pedidos simultâneos fazem 1 download; atualizar busca a versão nova; exceção de fonte vira miniatura. |
| `HttpArtworkFetcherTest` (10) | Contra um servidor HTTP local: imagem válida, 404, erro 503, resposta que não é imagem, imagem acima do limite, redirecionamento não seguido, host fora da lista nem contatado, HTTP sem TLS recusado, endereço inválido e servidor fora do ar sem lançar. |
| `SteamArtworkSourcesTest` (4) | URLs do CDN só para Steam e só com id numérico; cache do cliente nos formatos antigo e novo. |
| `LruCacheTest` (3) | Expulsa o menos usado; item maior que o cache não entra nem expulsa os outros; substituir atualiza o peso. |

Total: 88 testes, todos verdes.

## Rodar localmente

```bash
cd android
./gradlew :desktop:test          # testes do módulo
./gradlew :desktop:shots         # capturas em android/desktop/build/shots/
```

As capturas usam jogos de exemplo declarados só em `Shots.kt`; eles não entram na biblioteca do app.

## Pendente (exige Windows físico)

- Scan com Steam e Epic reais instalados, incluindo bibliotecas em vários discos.
- Lançamento por launcher (`steam://`, `com.epicgames.launcher://`) e por executável.
- DPI, redimensionamento, navegação por teclado e movimento reduzido.
- Desempenho com biblioteca grande.
- Compilação e capturas da camada de interface (Compose) após as Etapas 0 a 2: não foram compiladas no ambiente remoto.
- **Etapa 3 em máquina real:** as URLs do CDN da Steam seguem o padrão público conhecido, mas **não foram confirmadas ao vivo** (a rede do ambiente remoto bloqueia o CDN). Confirmar que capa e banner baixam para alguns jogos reais, que jogos sem banner caem na capa emoldurada, e que a Epic cai na miniatura neutra.
- Etapa 3, interface: carregamento assíncrono sem travar a rolagem, placeholder, banner com degradê, botão "Atualizar imagem" e o interruptor em Ajustes.
- Etapa 2 em máquina real: Steam com biblioteca em disco externo desconectado, desinstalar um jogo e reabrir, Steam fechada durante a varredura.

## Ainda sem teste (etapas futuras)

Diagnóstico contextual, Xbox e jogo manual.
