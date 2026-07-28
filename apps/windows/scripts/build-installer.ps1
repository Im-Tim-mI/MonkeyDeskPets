param(
    [ValidateSet("win-x64", "win-arm64")]
    [string]$Runtime = "win-x64"
)

$ErrorActionPreference = "Stop"
$WindowsDir = Split-Path -Parent $PSScriptRoot
$RepositoryRoot = (Resolve-Path (Join-Path $WindowsDir "..\..")).Path
$Version = (Get-Content (Join-Path $RepositoryRoot "VERSION") -Raw).Trim()
$PublishDir = Join-Path $WindowsDir "dist\$Runtime\MonkeyDeskPets"
$ReleaseDir = Join-Path $RepositoryRoot "release"
$Script = Join-Path $WindowsDir "installer\MonkeyDeskPets.iss"
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
    throw "找不到 Inno Setup 6。請先從 https://jrsoftware.org/isdl.php 安裝。"
}

& $Iscc `
    "/DAppVersion=$Version" `
    "/DRuntime=$Runtime" `
    "/DAllowedArchitectures=$AllowedArchitectures" `
    "/DPublishDir=$PublishDir" `
    "/DOutputDir=$ReleaseDir" `
    $Script

$Installer = Join-Path $ReleaseDir "MonkeyDeskPets-Windows-$Runtime-Setup-v$Version.exe"
$Hash = (Get-FileHash $Installer -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content (Join-Path $ReleaseDir "SHA256SUMS-Windows-$Runtime-Setup.txt") `
    "$Hash  $(Split-Path $Installer -Leaf)" -Encoding ASCII
Write-Host "完成：$Installer"
Write-Host "SHA-256：$Hash"
