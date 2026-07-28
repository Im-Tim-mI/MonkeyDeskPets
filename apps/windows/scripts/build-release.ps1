param(
    [ValidateSet("win-x64", "win-arm64")]
    [string]$Runtime = "win-x64"
)

$ErrorActionPreference = "Stop"
$WindowsDir = Split-Path -Parent $PSScriptRoot
$RepositoryRoot = (Resolve-Path (Join-Path $WindowsDir "..\..")).Path
$Version = (Get-Content (Join-Path $RepositoryRoot "VERSION") -Raw).Trim()
$Project = Join-Path $WindowsDir "src\MonkeyDeskPets.Windows\MonkeyDeskPets.Windows.csproj"
$PublishDir = Join-Path $WindowsDir "dist\$Runtime\MonkeyDeskPets"
$ReleaseDir = Join-Path $RepositoryRoot "release"
$ZipPath = Join-Path $ReleaseDir "MonkeyDeskPets-Windows-$Runtime-v$Version.zip"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "找不到 dotnet。請先安裝 .NET 8 SDK：https://dotnet.microsoft.com/download/dotnet/8.0"
}

Remove-Item $PublishDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item $PublishDir -ItemType Directory -Force | Out-Null
New-Item $ReleaseDir -ItemType Directory -Force | Out-Null

dotnet publish $Project `
    --configuration Release `
    --runtime $Runtime `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:DebugType=None `
    -p:DebugSymbols=false `
    --output $PublishDir

$Readme = @"
MonkeyDeskPets Windows v$Version
Copyright © 2026 廷廷小教室、廷廷的家（Tim945）

使用方法：
1. 解壓縮整個資料夾。
2. 執行 MonkeyDeskPets.exe。
3. 若 Windows SmartScreen 顯示警告，請先確認檔案來源與 SHA-256。

授權文件位於 Licenses 資料夾。
"@
Set-Content (Join-Path $PublishDir "使用說明.txt") $Readme -Encoding UTF8

Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $PublishDir "*") -DestinationPath $ZipPath -CompressionLevel Optimal
$Hash = (Get-FileHash $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content (Join-Path $ReleaseDir "SHA256SUMS-Windows-$Runtime.txt") `
    "$Hash  $(Split-Path $ZipPath -Leaf)" -Encoding ASCII

Write-Host "完成：$ZipPath"
Write-Host "SHA-256：$Hash"
