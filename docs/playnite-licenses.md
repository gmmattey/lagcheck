# Licenças e Atribuições — Playnite

O LagCheck ORBIT reutiliza conceitos arquiteturais, modelos de integração de launchers e padrões de leitura de manifestos de jogos desenvolvidos originalmente pelo projeto open-source **Playnite** e pelo repositório **PlayniteExtensions**, criados por **Josef Nemec**.

Em conformidade estrita com os termos da Licença MIT, a notificação de direitos autorais e o texto integral da licença estão reproduzidos abaixo.

---

## Playnite — MIT License

```text
The MIT License (MIT)

Copyright (c) 2017 Josef Nemec

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Componentes Reutilizados e Transpostos

Os seguintes componentes e algoritmos do Playnite serviram como especificação e foram transpostos modularmente para a arquitetura Kotlin JVM do LagCheck:

1. **Padrão de Scanner Steam (`SteamScanner`):**
   - Consulta ao Registro do Windows (`HKCU\Software\Valve\Steam\SteamPath`).
   - Parsing de hierarquias Valve KeyValue em arquivos `steamapps/libraryfolders.vdf`.
   - Parsing de manifestos `appmanifest_<appId>.acf` para extração de identificadores, nomes e status de instalação (`StateFlags = 4`).
   - Disparo de inicialização via protocolo de registro `steam://rungameid/<id>`.

2. **Padrão de Scanner Epic Games (`EpicScanner`):**
   - Leitura de manifestos de instalação no diretório `%ProgramData%\Epic\EpicGamesLauncher\Data\Manifests\*.item`.
   - Extração estruturada de `DisplayName`, `AppName`, `InstallLocation` e `LaunchExecutable`.
   - Disparo de inicialização via protocolo de registro `com.epicgames.launcher://apps/<AppName>?action=launch`.

3. **Mapeamento de Plataformas e Launchers (`GameRunner`):**
   - Disparo assíncrono e seguro de jogos através dos esquemas de protocolo registrados no sistema operacional Windows.

---

## Links dos Projetos Oficiais

- **Repositório Principal do Playnite:** [https://github.com/JosefNemec/Playnite](https://github.com/JosefNemec/Playnite)
- **Extensões de Plataforma do Playnite:** [https://github.com/JosefNemec/PlayniteExtensions](https://github.com/JosefNemec/PlayniteExtensions)
- **Site Oficial:** [https://playnite.link](https://playnite.link)
