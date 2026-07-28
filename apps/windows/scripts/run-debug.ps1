$ErrorActionPreference = "Stop"
$WindowsDir = Split-Path -Parent $PSScriptRoot
$Version = (Get-Content (Join-Path $WindowsDir "VERSION") -Raw).Trim()
$Project = Join-Path $WindowsDir "src\MonkeyDeskPets.Windows\MonkeyDeskPets.Windows.csproj"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "dotnet was not found. Install the .NET 8 SDK from https://dotnet.microsoft.com/download/dotnet/8.0"
}

Write-Host "Build platform: Windows"
Write-Host "Build version: $Version"
dotnet run --project $Project -p:Version=$Version
