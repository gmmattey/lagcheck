# Windows: testes e validação da biblioteca

> Estado em 11 de novembro de 2026 (Decisão 118). Separa o que foi executado do que depende de Windows físico.

## Executado

A lógica da biblioteca (sem Compose) foi compilada com o compilador Kotlin 2.0.20 e rodada com JUnit 4. O Gradle do projeto não resolve plugins no ambiente de desenvolvimento remoto, então esta é a evidência disponível lá. **Rodar `./gradlew :desktop:test` em uma máquina com acesso ao Google Maven continua sendo o gate oficial.**

| Teste | O que prova |
| --- | --- |
| `HeroSelectorTest` (6) | Sem jogo, sem destaque; jogo não instalado nunca é destaque; prioridade último iniciado, depois último executado, depois instalado recentemente, depois título; ordem estável. |
| `LibraryStoreTest` (4) | Salvar e carregar favoritos e último iniciado (inclui ids com espaço e símbolos); arquivo ausente ou corrompido não derruba; migração do arquivo antigo de favoritos sem apagá-lo. |
| `LibraryRepositoryTest` (7) | Biblioteca vazia; scanner com falha não derruba os outros; escolha do usuário prevalece sobre o destaque padrão; favorito sobrevive a reabrir; Jogar registra o último iniciado; falha ao iniciar não registra; filtros e busca. |
| `LibraryCoreTest` (3) | Parsers de manifesto da Steam, `libraryfolders.vdf` e `.item` da Epic. |

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
- Compilação e capturas da camada de interface (Compose) após as Etapas 0 e 1: não foram compiladas no ambiente remoto.

## Ainda sem teste (etapas futuras)

Reconciliação (novo, removido, alterado, duplicado), resolvedor e cache de imagens, diagnóstico contextual, Xbox e jogo manual.
