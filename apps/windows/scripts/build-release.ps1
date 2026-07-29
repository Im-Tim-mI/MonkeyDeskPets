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

if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish failed with exit code $LASTEXITCODE."
}

# Copy external shared assets and license files explicitly. Linked Content
# items outside the project directory are not copied consistently by every
# .NET SDK publish configuration, especially with single-file publishing.
$AssetsDir = Join-Path $PublishDir "Assets"
$LicensesDir = Join-Path $PublishDir "Licenses"
New-Item $AssetsDir -ItemType Directory -Force | Out-Null
New-Item $LicensesDir -ItemType Directory -Force | Out-Null

Copy-Item (Join-Path $RepositoryRoot "shared\assets\person-sprites.png") `
    (Join-Path $AssetsDir "person-sprites.png") -Force
Copy-Item (Join-Path $RepositoryRoot "shared\assets\author-avatar.png") `
    (Join-Path $AssetsDir "author-avatar.png") -Force
Copy-Item (Join-Path $RepositoryRoot "shared\assets\logitech-ad.jpeg") `
    (Join-Path $AssetsDir "logitech-ad.jpeg") -Force
Copy-Item (Join-Path $WindowsDir "src\MonkeyDeskPets.Windows\Assets\MonkeyDeskPets.ico") `
    (Join-Path $AssetsDir "MonkeyDeskPets.ico") -Force

Copy-Item (Join-Path $RepositoryRoot "LICENSE") `
    (Join-Path $LicensesDir "LICENSE.txt") -Force
Copy-Item (Join-Path $RepositoryRoot "NOTICE") `
    (Join-Path $LicensesDir "NOTICE.txt") -Force
Copy-Item (Join-Path $RepositoryRoot "ADDITIONAL-TERMS-zh-TW.txt") `
    (Join-Path $LicensesDir "ADDITIONAL-TERMS-zh-TW.txt") -Force
Copy-Item (Join-Path $RepositoryRoot "ADDITIONAL-TERMS-en.txt") `
    (Join-Path $LicensesDir "ADDITIONAL-TERMS-en.txt") -Force
Copy-Item (Join-Path $RepositoryRoot "POLYFORM-NONCOMMERCIAL-1.0.0.txt") `
    (Join-Path $LicensesDir "POLYFORM-NONCOMMERCIAL-1.0.0.txt") -Force

$InstallerDir = Join-Path $WindowsDir "installer"
Copy-Item (Join-Path $InstallerDir "README-zh-TW.txt") `
    (Join-Path $PublishDir "README-zh-TW.txt") -Force
Copy-Item (Join-Path $InstallerDir "README-en.txt") `
    (Join-Path $PublishDir "README-en.txt") -Force

$RequiredPublishFiles = @(
    "MonkeyDeskPets.exe",
    "Assets\person-sprites.png",
    "Assets\author-avatar.png",
    "Assets\logitech-ad.jpeg",
    "Assets\MonkeyDeskPets.ico",
    "Licenses\LICENSE.txt",
    "Licenses\NOTICE.txt",
    "Licenses\ADDITIONAL-TERMS-zh-TW.txt",
    "Licenses\ADDITIONAL-TERMS-en.txt",
    "Licenses\POLYFORM-NONCOMMERCIAL-1.0.0.txt",
    "README-zh-TW.txt",
    "README-en.txt"
)
foreach ($RelativePath in $RequiredPublishFiles) {
    $RequiredPath = Join-Path $PublishDir $RelativePath
    if (-not (Test-Path $RequiredPath -PathType Leaf)) {
        throw "Required publish file is missing: $RequiredPath"
    }
}

Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $PublishDir "*") -DestinationPath $ZipPath -CompressionLevel Optimal
$Hash = (Get-FileHash $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content (Join-Path $ReleaseDir "SHA256SUMS-Windows-$Runtime.txt") `
    "$Hash  $(Split-Path $ZipPath -Leaf)" -Encoding ASCII

Write-Host "Completed: $ZipPath"
Write-Host "SHA-256: $Hash"
