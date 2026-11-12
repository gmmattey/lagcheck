[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    # A JDK 17+ is needed because engine-host is compiled for JVM 17. JAVA_HOME is
    # intentionally preferred over a machine-wide Java so the artifact is repeatable.
    [string]$JavaHome = $env:JAVA_HOME,

    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\artifacts\winui"),

    [string]$ExpectedEngineProtocol = "lagcheck-engine-v1"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Resolve-AbsolutePath([string]$Path, [string]$Label) {
    if ([string]::IsNullOrWhiteSpace($Path)) { throw "$Label não foi informado." }
    try { return [System.IO.Path]::GetFullPath($Path) }
    catch { throw "$Label não é um caminho válido: $Path" }
}

function Invoke-Checked([string]$FilePath, [string[]]$Arguments, [string]$Label) {
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Label falhou (código $LASTEXITCODE)." }
}

function Assert-Exists([string]$Path, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "$Label não foi encontrado: $Path" }
}

function Get-DirectoryPrefix([string]$Path) {
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $alternateSeparator = [System.IO.Path]::AltDirectorySeparatorChar
    return $Path.TrimEnd($separator, $alternateSeparator) + $separator
}

function Get-JavaFeatureVersion([string]$Java) {
    $versionText = [string]::Join("`n", (& $Java -version 2>&1))
    if ($LASTEXITCODE -ne 0) { throw "Não foi possível executar o Java em $Java." }
    $match = [regex]::Match($versionText, 'version\s+"(?<feature>\d+)')
    if (-not $match.Success) { throw "Não foi possível identificar a versão do Java: $versionText" }
    return [int]$match.Groups["feature"].Value
}

function Find-BuildPri([string]$ProjectDirectory, [string]$Configuration) {
    # Windows App SDK can build the PRI but omit it from an unpackaged publish.
    # Search only the exact platform/configuration/runtime produced by this script,
    # never a stale PRI from another build configuration.
    $configurationOutput = Join-Path (Join-Path (Join-Path $ProjectDirectory "bin") "x64") $Configuration
    Assert-Exists $configurationOutput "Saída da build WinUI"
    $candidates = @(Get-ChildItem -LiteralPath $configurationOutput -Filter "LagCheck.WinUI.pri" -File -Recurse |
        Where-Object { $_.FullName -match "\\win-x64\\" } |
        Sort-Object LastWriteTimeUtc -Descending)
    if ($candidates.Count -eq 0) {
        throw "O publish não gerou LagCheck.WinUI.pri para x64/$Configuration. A interface não pode ser iniciada sem esse recurso."
    }
    return $candidates[0].FullName
}

function Test-EngineHandshake([string]$Java, [string]$EngineRoot, [string]$ExpectedProtocol, [string]$ScratchHome) {
    $start = [System.Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $Java
    $start.UseShellExecute = $false
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.CreateNoWindow = $true
    [void]$start.ArgumentList.Add("-Duser.home=$ScratchHome")
    [void]$start.ArgumentList.Add("-cp")
    [void]$start.ArgumentList.Add((Join-Path $EngineRoot "lib\*"))
    [void]$start.ArgumentList.Add("com.lagcheck.enginehost.MainKt")
    $start.Environment["APPDATA"] = (Join-Path $ScratchHome "AppData")

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $start
    if (-not $process.Start()) { throw "Não foi possível iniciar a verificação do motor empacotado." }
    $process.StandardInput.WriteLine('{"type":"hello","requestId":"package-check"}')
    $process.StandardInput.Close()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "O motor empacotado não iniciou (código $($process.ExitCode)): $stderr" }

    $helloLine = $stdout -split "`r?`n" | Where-Object { $_ -match '"type"\s*:\s*"hello"' } | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($helloLine)) { throw "O motor empacotado não respondeu ao handshake. Saída: $stdout" }
    try { $hello = $helloLine | ConvertFrom-Json }
    catch { throw "O motor empacotado devolveu um handshake inválido: $helloLine" }
    if ($hello.protocol -ne $ExpectedProtocol) {
        throw "Protocolo incompatível: WinUI espera '$ExpectedProtocol', mas o motor empacotado informou '$($hello.protocol)'."
    }
}

$repoRoot = Resolve-AbsolutePath (Join-Path $PSScriptRoot "..\..") "A raiz do repositório"
$outputRoot = Resolve-AbsolutePath $OutputDirectory "O diretório de saída"
$repoPrefix = Get-DirectoryPrefix $repoRoot
$outputPrefix = Get-DirectoryPrefix $outputRoot
if ($outputRoot.Equals($repoRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
    $repoPrefix.StartsWith($outputPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "O diretório de saída não pode ser a raiz do repositório nem um diretório acima dela."
}
if ((Test-Path -LiteralPath $outputRoot) -and -not (Get-Item -LiteralPath $outputRoot).PSIsContainer) {
    throw "O diretório de saída aponta para um arquivo: $outputRoot"
}
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

$gradleWrapper = Join-Path $repoRoot "android\gradle\wrapper\gradle-wrapper.jar"
$winuiProject = Join-Path $repoRoot "windows\LagCheck.WinUI\LagCheck.WinUI.csproj"
$hostInstall = Join-Path $repoRoot "android\engine-host\build\install\engine-host"
Assert-Exists $gradleWrapper "Gradle Wrapper"
Assert-Exists $winuiProject "Projeto WinUI"

if ([string]::IsNullOrWhiteSpace($JavaHome)) { throw "JAVA_HOME é obrigatório e deve apontar para um JDK 17 ou superior com jlink." }
$javaHomePath = Resolve-AbsolutePath $JavaHome "JAVA_HOME"
$java = Join-Path $javaHomePath "bin\java.exe"
$jlink = Join-Path $javaHomePath "bin\jlink.exe"
Assert-Exists $java "java.exe"
Assert-Exists $jlink "jlink.exe"
$javaFeature = Get-JavaFeatureVersion $java
if ($javaFeature -lt 17) { throw "O JDK $javaFeature é incompatível. O engine-host exige JDK 17 ou superior." }

$dotnetCommand = Get-Command dotnet -ErrorAction SilentlyContinue
if ($null -eq $dotnetCommand) { throw "dotnet não foi encontrado no PATH." }

$packageId = "LagCheck.WinUI-x64-{0:yyyyMMdd-HHmmss}-{1}" -f (Get-Date), ([Guid]::NewGuid().ToString("N").Substring(0, 8))
$stage = Join-Path $outputRoot $packageId
$stagePrefix = Get-DirectoryPrefix $stage
if (-not $stagePrefix.StartsWith($outputPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "O diretório temporário de empacotamento escapou da saída solicitada."
}
if (Test-Path -LiteralPath $stage) { throw "A pasta de saída já existe: $stage" }
New-Item -ItemType Directory -Path $stage | Out-Null

Write-Host "[1/5] Gerando a distribuição local do engine-host"
$previousJavaHome = $env:JAVA_HOME
Push-Location (Join-Path $repoRoot "android")
try {
    # Gradle e jlink usam o mesmo JDK para não gerar um host com bytecode
    # diferente do runtime local que seguirá no pacote.
    $env:JAVA_HOME = $javaHomePath
    Invoke-Checked $java @("-classpath", $gradleWrapper, "org.gradle.wrapper.GradleWrapperMain", ":engine-host:installDist") "Gradle :engine-host:installDist"
}
finally {
    Pop-Location
    if ($null -eq $previousJavaHome) { Remove-Item Env:JAVA_HOME -ErrorAction SilentlyContinue }
    else { $env:JAVA_HOME = $previousJavaHome }
}
Assert-Exists (Join-Path $hostInstall "bin\engine-host.bat") "Inicializador do engine-host"
Assert-Exists (Join-Path $hostInstall "lib") "Bibliotecas do engine-host"

Write-Host "[2/5] Publicando a interface WinUI autocontida"
$appOutput = Join-Path $stage "app"
Invoke-Checked $dotnetCommand.Source @(
    "publish", $winuiProject,
    "--configuration", $Configuration,
    "--runtime", "win-x64",
    "--self-contained", "true",
    "--output", $appOutput,
    "-p:Platform=x64",
    "-p:PublishSingleFile=false"
) "dotnet publish"
Assert-Exists (Join-Path $appOutput "LagCheck.WinUI.exe") "Executável WinUI publicado"
$publishedPri = Join-Path $appOutput "LagCheck.WinUI.pri"
if (-not (Test-Path -LiteralPath $publishedPri)) {
    $buildPri = Find-BuildPri (Split-Path -Parent $winuiProject) $Configuration
    Copy-Item -LiteralPath $buildPri -Destination $publishedPri -ErrorAction Stop
}
Assert-Exists $publishedPri "PRI da interface WinUI publicada"

Write-Host "[3/5] Copiando o motor Kotlin ao lado do executável"
$engineOutput = Join-Path $appOutput "engine"
Copy-Item -LiteralPath $hostInstall -Destination $engineOutput -Recurse -Force
Assert-Exists (Join-Path $engineOutput "bin\engine-host.bat") "Inicializador do motor copiado"
Assert-Exists (Join-Path $engineOutput "lib") "Bibliotecas do motor copiadas"

Write-Host "[4/5] Criando o runtime Java local"
$runtimeOutput = Join-Path $engineOutput "runtime"
$jlinkModules = "java.base,java.datatransfer,java.desktop,java.logging,java.management,java.naming,java.net.http,java.prefs,java.security.jgss,java.sql,java.xml,jdk.crypto.ec,jdk.unsupported"
Invoke-Checked $jlink @(
    "--add-modules", $jlinkModules,
    "--strip-debug",
    "--no-header-files",
    "--no-man-pages",
    "--compress=zip-6",
    "--output", $runtimeOutput
) "jlink"
$packagedJava = Join-Path $runtimeOutput "bin\java.exe"
Assert-Exists $packagedJava "Runtime Java local"

Write-Host "[5/5] Conferindo o contrato WinUI ↔ motor"
$verificationHome = Join-Path $stage "verification-home"
New-Item -ItemType Directory -Path $verificationHome -Force | Out-Null
try { Test-EngineHandshake $packagedJava $engineOutput $ExpectedEngineProtocol $verificationHome }
finally { if (Test-Path -LiteralPath $verificationHome) { Remove-Item -LiteralPath $verificationHome -Recurse -Force } }

Write-Host "Pacote pronto: $appOutput"
Write-Host "Contém: engine\\bin\\engine-host.bat, engine\\lib e engine\\runtime\\bin\\java.exe"
