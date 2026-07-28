$ErrorActionPreference = "Stop"
$WindowsDir = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $WindowsDir "src\MonkeyDeskPets.Windows\MonkeyDeskPets.Windows.csproj"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "找不到 dotnet。請先安裝 .NET 8 SDK：https://dotnet.microsoft.com/download/dotnet/8.0"
}

dotnet run --project $Project
