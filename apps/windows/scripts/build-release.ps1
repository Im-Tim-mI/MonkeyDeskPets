param(
    [ValidateSet("win-x64", "win-arm64")]
    [string]$Runtime = "win-x64"
)

$ErrorActionPreference = "Stop"
$WindowsDir = Split-Path -Parent $PSScriptRoot
$RepositoryRoot = (Resolve-Path (Join-Path $WindowsDir "..\..")).Path
$Version = (Get-Content (Join-Path $WindowsDir "VERSION") -Raw).Trim()
$Project = Join-Path $WindowsDir "src\MonkeyDeskPets.Windows\MonkeyDeskPets.Windows.csproj"
$PublishDir = Join-Path $WindowsDir "dist\$Runtime\MonkeyDeskPets"
$ReleaseDir = Join-Path $RepositoryRoot "release"
$ZipPath = Join-Path $ReleaseDir "MonkeyDeskPets-Windows-$Runtime-v$Version.zip"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "dotnet was not found. Install the .NET 8 SDK from https://dotnet.microsoft.com/download/dotnet/8.0"
}

Write-Host "Build platform: Windows ($Runtime)"
Write-Host "Build version: $Version"

Remove-Item $PublishDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item $PublishDir -ItemType Directory -Force | Out-Null
New-Item $ReleaseDir -ItemType Directory -Force | Out-Null

dotnet publish $Project `
    --configuration Release `
    --runtime $Runtime `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:Version=$Version `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:DebugType=None `
    -p:DebugSymbols=false `
    --output $PublishDir

$InstallerDir = Join-Path $WindowsDir "installer"
Copy-Item (Join-Path $InstallerDir "README-zh-TW.txt") `
    (Join-Path $PublishDir "README-zh-TW.txt") -Force
Copy-Item (Join-Path $InstallerDir "README-en.txt") `
    (Join-Path $PublishDir "README-en.txt") -Force

Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $PublishDir "*") -DestinationPath $ZipPath -CompressionLevel Optimal
$Hash = (Get-FileHash $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content (Join-Path $ReleaseDir "SHA256SUMS-Windows-$Runtime.txt") `
    "$Hash  $(Split-Path $ZipPath -Leaf)" -Encoding ASCII

Write-Host "Completed: $ZipPath"
Write-Host "SHA-256: $Hash"
