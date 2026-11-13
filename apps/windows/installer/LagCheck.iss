; Instalador do LagCheck para Windows (WinUI 3). Gerado por scripts/build-installer.ps1.
; Sem assinatura de código: o SmartScreen pode avisar de fornecedor desconhecido.
#ifndef AppVersion
  #error Informe /DAppVersion=X.Y.Z
#endif
; Caminhos com espaço chegam por variável de ambiente (o ISCC não aceita /D com espaços de forma confiável).
#define SourceDir GetEnv("LAGCHECK_PKG_APP")
#define OutputDir GetEnv("LAGCHECK_PKG_OUT")
#define IconFile GetEnv("LAGCHECK_PKG_ICON")
#if SourceDir == "" || OutputDir == "" || IconFile == ""
  #error Defina LAGCHECK_PKG_APP, LAGCHECK_PKG_OUT e LAGCHECK_PKG_ICON
#endif

[Setup]
AppId={{6F1B7C52-3E0A-4D55-9C1F-5A2B8E4D7A31}
AppName=LagCheck
AppVersion={#AppVersion}
AppPublisher=LagCheck
DefaultDirName={autopf}\LagCheck
DefaultGroupName=LagCheck
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=LagCheck-Windows-{#AppVersion}-x64-setup
SetupIconFile={#IconFile}
UninstallDisplayIcon={app}\LagCheck.WinUI.exe
Compression=lzma2/normal
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\LagCheck"; Filename: "{app}\LagCheck.WinUI.exe"
Name: "{autodesktop}\LagCheck"; Filename: "{app}\LagCheck.WinUI.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\LagCheck.WinUI.exe"; Description: "{cm:LaunchProgram,LagCheck}"; Flags: nowait postinstall skipifsilent

[CustomMessages]
brazilianportuguese.OldFound=Encontramos uma versão anterior do LagCheck neste computador.%n%nPara não ficar com duas cópias do app, vamos removê-la agora. Suas configurações e seu histórico são mantidos.%n%nO Windows pode pedir permissão de administrador para isso. Remover a versão anterior?
english.OldFound=We found a previous version of LagCheck on this computer.%n%nTo avoid keeping two copies of the app, we will remove it now. Your settings and history are kept.%n%nWindows may ask for administrator permission to do this. Remove the previous version?
spanish.OldFound=Encontramos una versión anterior de LagCheck en este equipo.%n%nPara no tener dos copias de la app, la vamos a quitar ahora. Tus ajustes y tu historial se conservan.%n%nWindows puede pedir permiso de administrador para esto. ¿Quitar la versión anterior?

[Code]
// A versão 0.1.x (Compose Desktop) foi instalada como pacote MSI e fica em %LOCALAPPDATA%\LagCheck.
// Só entram na remoção entradas MSI chamadas "LagCheck" cuja pasta de instalação é essa. O desinstalador do
// MSI remove a pasta do app inteira (por isso o ui_settings.json é salvo e restaurado abaixo); os dados em
// %APPDATA%\LagCheck (biblioteca, favoritos, preferências) ficam fora do pacote e não são tocados.
function OldInstallDir(): String;
begin
  Result := ExpandConstant('{localappdata}\LagCheck');
end;

procedure CollectOld(Root: Integer; var Codes: TArrayOfString);
var
  Names: TArrayOfString;
  I, N: Integer;
  Base, Display, Uninstall, Location: String;
begin
  Base := 'Software\Microsoft\Windows\CurrentVersion\Uninstall';
  if not RegGetSubkeyNames(Root, Base, Names) then Exit;
  for I := 0 to GetArrayLength(Names) - 1 do
  begin
    if (Length(Names[I]) < 3) or (Names[I][1] <> '{') then Continue;
    if not RegQueryStringValue(Root, Base + '\' + Names[I], 'DisplayName', Display) then Continue;
    if Display <> 'LagCheck' then Continue;
    if not RegQueryStringValue(Root, Base + '\' + Names[I], 'UninstallString', Uninstall) then Continue;
    if Pos('msiexec.exe /x{', Lowercase(Uninstall)) <> 1 then Continue;
    if not RegQueryStringValue(Root, Base + '\' + Names[I], 'InstallLocation', Location) then Continue;
    if CompareText(RemoveBackslashUnlessRoot(Location), OldInstallDir()) <> 0 then Continue;
    N := GetArrayLength(Codes);
    SetArrayLength(Codes, N + 1);
    Codes[N] := Names[I];
  end;
end;

procedure RemoveOldVersion();
var
  Codes, Seen: TArrayOfString;
  I, J, N, ResultCode: Integer;
  Duplicate: Boolean;
  SettingsFile, SettingsBackup: String;
begin
  if ExpandConstant('{param:KeepOld|0}') = '1' then
  begin
    Log('Remoção da versão anterior ignorada (/KeepOld=1).');
    Exit;
  end;
  CollectOld(HKLM64, Codes);
  CollectOld(HKLM32, Codes);
  for I := 0 to GetArrayLength(Codes) - 1 do
  begin
    Duplicate := False;
    for J := 0 to GetArrayLength(Seen) - 1 do
      if CompareText(Seen[J], Codes[I]) = 0 then Duplicate := True;
    if not Duplicate then
    begin
      N := GetArrayLength(Seen);
      SetArrayLength(Seen, N + 1);
      Seen[N] := Codes[I];
    end;
  end;
  if GetArrayLength(Seen) = 0 then
  begin
    Log('Nenhuma versão anterior (MSI) encontrada.');
    Exit;
  end;
  Log(Format('Versões anteriores encontradas: %d', [GetArrayLength(Seen)]));
  if MsgBox(CustomMessage('OldFound'), mbConfirmation, MB_YESNO) <> IDYES then Exit;
  // O MSI antigo apaga a pasta inteira, inclusive o ui_settings.json (idioma e tema do app novo): guarda e devolve.
  SettingsFile := OldInstallDir() + '\ui_settings.json';
  SettingsBackup := ExpandConstant('{tmp}\ui_settings.json');
  if FileExists(SettingsFile) then FileCopy(SettingsFile, SettingsBackup, False);
  for I := 0 to GetArrayLength(Seen) - 1 do
  begin
    // runas: o MSI antigo foi registrado para toda a máquina, então remover pede elevação.
    if ShellExec('runas', 'msiexec.exe', '/x ' + Seen[I] + ' /passive /norestart', '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then
      Log(Format('msiexec /x %s terminou com código %d', [Seen[I], ResultCode]))
    else
      Log(Format('Não foi possível iniciar a remoção de %s (erro %d)', [Seen[I], ResultCode]));
  end;
  if FileExists(SettingsBackup) then
  begin
    ForceDirectories(OldInstallDir());
    FileCopy(SettingsBackup, SettingsFile, False);
    Log('ui_settings.json restaurado.');
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then RemoveOldVersion();
end;
