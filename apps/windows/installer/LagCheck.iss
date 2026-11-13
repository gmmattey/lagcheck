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
