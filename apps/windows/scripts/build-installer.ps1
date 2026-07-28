param(
    [ValidateSet("win-x64", "win-arm64")]
    [string]$Runtime = "win-x64"
)

$ErrorActionPreference = "Stop"
$WindowsDir = Split-Path -Parent $PSScriptRoot
$RepositoryRoot = (Resolve-Path (Join-Path $WindowsDir "..\..")).Path
$Version = (Get-Content (Join-Path $WindowsDir "VERSION") -Raw).Trim()
$PublishDir = Join-Path $WindowsDir "dist\$Runtime\MonkeyDeskPets"
$ReleaseDir = Join-Path $RepositoryRoot "release"
$Script = Join-Path $WindowsDir "installer\MonkeyDeskPets.iss"
$LanguageFile = Join-Path $WindowsDir "installer\ChineseTraditional.isl"
$Installer = Join-Path $ReleaseDir "MonkeyDeskPets-Windows-$Runtime-Setup-v$Version.exe"
$AllowedArchitectures = if ($Runtime -eq "win-arm64") { "arm64" } else { "x64compatible" }
$IsccCandidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
)
$Iscc = $IsccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not (Test-Path (Join-Path $PublishDir "MonkeyDeskPets.exe"))) {
    & (Join-Path $PSScriptRoot "build-release.ps1") -Runtime $Runtime
}
if (-not $Iscc) {
    throw "Inno Setup 6 was not found. Install it from https://jrsoftware.org/isdl.php"
}
if (-not (Test-Path $LanguageFile)) {
    throw "Bundled Traditional Chinese language file was not found: $LanguageFile"
}

Write-Host "Installer platform: Windows ($Runtime)"
Write-Host "Installer version: $Version"

New-Item $ReleaseDir -ItemType Directory -Force | Out-Null
Remove-Item $Installer -Force -ErrorAction SilentlyContinue

& $Iscc `
    "/DAppVersion=$Version" `
    "/DRuntime=$Runtime" `
    "/DAllowedArchitectures=$AllowedArchitectures" `
    "/DPublishDir=$PublishDir" `
    "/DOutputDir=$ReleaseDir" `
    $Script

if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed with exit code $LASTEXITCODE."
}
if (-not (Test-Path $Installer)) {
    throw "Inno Setup reported success, but the installer was not found: $Installer"
}

$Hash = (Get-FileHash $Installer -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content (Join-Path $ReleaseDir "SHA256SUMS-Windows-$Runtime-Setup.txt") `
    "$Hash  $(Split-Path $Installer -Leaf)" -Encoding ASCII
Write-Host "Completed: $Installer"
Write-Host "SHA-256: $Hash"
