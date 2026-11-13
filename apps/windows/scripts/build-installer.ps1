[CmdletBinding()]
param(
    # Versão no formato X.Y.Z. Precisa coincidir com <Version> do csproj e com UpdateSource.installedVersion (X.Y).
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    # Pasta "app" já gerada por package-winui.ps1. Sem ela, o script gera um pacote novo.
    [string]$PackageDirectory,

    [string]$JavaHome = $env:JAVA_HOME,

    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\artifacts\release"),

    # Caminho do ISCC.exe; por padrão procura as instalações usuais do Inno Setup 6.
    [string]$InnoCompiler
)

# Gera o instalador e os checksums. NÃO publica nada: tag, push e GitHub Release são passos
# separados e exigem autorização expressa (ver apps/android/desktop/PACKAGING.md, seção 4).

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$windowsRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$repoRoot = (Resolve-Path (Join-Path $windowsRoot "..\..")).Path
$csproj = Join-Path $windowsRoot "LagCheck.WinUI\LagCheck.WinUI.csproj"
$updateSource = Join-Path $repoRoot "apps\android\desktop\src\main\kotlin\com\lagcheck\desktop\update\UpdateSource.kt"
$iss = Join-Path $windowsRoot "installer\LagCheck.iss"
$icon = Join-Path $windowsRoot "LagCheck.WinUI\Assets\lagcheck.ico"

# 1. A versão do instalador, do app e do atualizador não podem divergir.
$csprojVersion = [regex]::Match((Get-Content -LiteralPath $csproj -Raw), '<Version>([^<]+)</Version>').Groups[1].Value
if ($csprojVersion -ne $Version) { throw "O csproj declara a versão '$csprojVersion', diferente de $Version. Ajuste LagCheck.WinUI.csproj." }
$installed = [regex]::Match((Get-Content -LiteralPath $updateSource -Raw), 'installedVersion\s*=\s*"([^"]+)"').Groups[1].Value
$shortVersion = ($Version -split '\.')[0..1] -join '.'
if ($installed -ne $shortVersion) { throw "UpdateSource.installedVersion é '$installed', esperado '$shortVersion'. O app ofereceria a si mesmo como atualização." }

# 2. Compilador do Inno Setup.
if ([string]::IsNullOrWhiteSpace($InnoCompiler)) {
    $InnoCompiler = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
        (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $InnoCompiler -or -not (Test-Path -LiteralPath $InnoCompiler)) {
    throw "ISCC.exe não encontrado. Instale com: winget install --id JRSoftware.InnoSetup -e"
}

# 3. Pacote WinUI + motor (gera um novo quando não foi informado).
$packageRoot = Join-Path $windowsRoot "artifacts\winui"
if ([string]::IsNullOrWhiteSpace($PackageDirectory)) {
    $before = @(if (Test-Path -LiteralPath $packageRoot) { Get-ChildItem -LiteralPath $packageRoot -Directory | ForEach-Object Name })
    $packageArgs = @{}
    if ($JavaHome) { $packageArgs.JavaHome = $JavaHome }
    & (Join-Path $PSScriptRoot "package-winui.ps1") @packageArgs
    $created = Get-ChildItem -LiteralPath $packageRoot -Directory | Where-Object { $before -notcontains $_.Name } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $created) { throw "package-winui.ps1 não gerou uma pasta nova em $packageRoot." }
    $PackageDirectory = Join-Path $created.FullName "app"
}
$PackageDirectory = (Resolve-Path -LiteralPath $PackageDirectory).Path
foreach ($required in @("LagCheck.WinUI.exe", "LagCheck.WinUI.pri", "engine\bin\engine-host.bat", "engine\runtime\bin\java.exe")) {
    if (-not (Test-Path -LiteralPath (Join-Path $PackageDirectory $required))) { throw "Pacote incompleto: falta $required em $PackageDirectory" }
}

# 4. Instalador. Caminhos com espaço vão por variável de ambiente (o ISCC não trata /D com espaço).
$output = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $output -Force | Out-Null
$env:LAGCHECK_PKG_APP = $PackageDirectory
$env:LAGCHECK_PKG_OUT = $output
$env:LAGCHECK_PKG_ICON = $icon
Write-Host "Compilando o instalador $Version"
& $InnoCompiler "/DAppVersion=$Version" $iss
if ($LASTEXITCODE -ne 0) { throw "ISCC falhou (código $LASTEXITCODE)." }

$setupName = "LagCheck-Windows-$Version-x64-setup.exe"
$setup = Join-Path $output $setupName
if (-not (Test-Path -LiteralPath $setup)) { throw "O instalador esperado não foi gerado: $setup" }

# 5. Checksums nos nomes que a página e o atualizador esperam.
$hash = (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash.ToLowerInvariant()
$line = "$hash  $setupName"
Set-Content -LiteralPath (Join-Path $output "$setupName.sha256") -Value $line -Encoding ascii
Set-Content -LiteralPath (Join-Path $output "SHA256SUMS.txt") -Value $line -Encoding ascii

Write-Host ""
Write-Host "Instalador: $setup ($([math]::Round((Get-Item -LiteralPath $setup).Length / 1MB, 1)) MB)"
Write-Host "SHA-256:    $hash"
Write-Host ""
Write-Host "Antes de publicar: instale em uma pasta temporária e abra o app instalado."
Write-Host "  setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOICONS /DIR=<pasta>"
Write-Host "Publicar (autorização expressa): gh release create windows-v$Version <setup.exe> <.sha256> <SHA256SUMS.txt> --target main --latest=false"
Write-Host "O .exe precisa ser o primeiro asset: o atualizador lê o primeiro .exe/.msi da release."
