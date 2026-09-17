# Decisão — navegação e configurações da V1

**Status:** aprovada e implementada  
**Data:** 2026-09-09 (revisada em 2026-09-09 para refletir a implementação aprovada)  
**Donos:** Marco (produto), Renan (experiência) e Rian (iOS)

## Problema

A Home não tinha caminho para configurações, suporte ou política de privacidade, e o atalho para Histórico abria uma apresentação modal.

## Decisão

Home e Histórico são os dois destinos de `AppDestination`; Configurações é uma tela empilhada na mesma `NavigationStack`, não um destino modal nem um item de menu lateral. O cabeçalho mantém a wordmark alinhada à esquerda; a ação de Configurações (ícone de reticências) e, na Home, a ação de busca ficam à direita. Não há botão de menu lateral nem indicador visual de destino ativo — a navegação é uma pilha linear: Home ⇄ Configurações ⇄ Histórico, com "voltar" à esquerda nos fluxos internos, preservando a wordmark.

Configurações é alcançada pelo ícone de reticências a partir de Home ou de Histórico. A partir de Configurações, a linha "Histórico" navega para o Histórico e fecha Configurações; a partir do Histórico, o mesmo ícone de reticências no cabeçalho volta a abrir Configurações.

Configurações contém o idioma do sistema como informação, exclusão confirmada do histórico local, versão do app, Suporte e Política de privacidade. Suporte e privacidade são URLs vindas da configuração do build, nunca URLs inventadas na interface ou no código. Sem URLs públicas configuradas e testadas, o build não passa o gate de App Store.

## Fora do escopo

Não há seletor de idioma próprio, notificações, publicidade, UMP, ATT ou “Opções de privacidade” nesta entrega. Esses itens exigem decisão específica do MVP1.1. Não há conta, portanto não há exclusão de conta; apagar histórico remove somente os registros locais. Um menu lateral com indicação de destino ativo, se algum dia for retomado do protótipo original, exige nova decisão de Renan — não está no escopo desta.

## Critérios de aceite

1. Configurações é alcançável a partir de Home e de Histórico pelo ícone de reticências, e permite navegar para Histórico a partir dela.
2. Histórico não é modal e o reteste retorna à Home sem inferir novo contexto de medição.
3. Apagar histórico exige confirmação e atualiza a tela após concluir.
4. Suporte e privacidade só abrem URLs HTTPS válidas configuradas no build.
5. PT-BR e inglês, Dynamic Type, VoiceOver e o viewport iPhone são revisados contra o protótipo canônico.

## Evidência exigida antes de release

Validação manual em iPhone dos destinos, da exclusão e dos links publicados; revisão de App Store Connect para URLs de suporte e privacidade e declaração de privacidade coerente com o binário.
