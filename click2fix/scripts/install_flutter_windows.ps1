<#
Installs the latest stable Flutter SDK for Windows from Flutter's official release feed.

Usage:

  ./scripts/install_flutter_windows.ps1
  ./scripts/install_flutter_windows.ps1 -InstallRoot "C:\src" -Force

After the script finishes, close and reopen PowerShell, then run:

  flutter doctor
#>

[CmdletBinding()]
param(
  [string]$InstallRoot = (Join-Path $env:USERPROFILE 'development'),
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$releaseFeedUrl = 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
$installRootPath = [System.IO.Path]::GetFullPath($InstallRoot)
$flutterPath = Join-Path $installRootPath 'flutter'
$flutterBinPath = Join-Path $flutterPath 'bin'
$zipPath = Join-Path ([System.IO.Path]::GetTempPath()) 'flutter_windows_stable.zip'

Write-Host "Reading Flutter release feed..."
$releaseFeed = Invoke-RestMethod -Uri $releaseFeedUrl
$stableHash = $releaseFeed.current_release.stable
$stableRelease = $releaseFeed.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1

if (-not $stableRelease) {
  throw 'Could not find the latest stable Flutter release in the official release feed.'
}

$downloadUrl = "$($releaseFeed.base_url)/$($stableRelease.archive)"
Write-Host "Latest stable Flutter: $($stableRelease.version)"
Write-Host "Download URL: $downloadUrl"

if (Test-Path $flutterPath) {
  if (-not $Force) {
    throw "Flutter already exists at '$flutterPath'. Re-run with -Force to replace it."
  }

  $resolvedFlutterPath = (Resolve-Path $flutterPath).Path
  if (-not $resolvedFlutterPath.StartsWith($installRootPath)) {
    throw "Refusing to remove a path outside the install root: $resolvedFlutterPath"
  }

  Write-Host "Removing existing Flutter SDK at $flutterPath"
  Remove-Item -LiteralPath $resolvedFlutterPath -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $installRootPath | Out-Null

Write-Host "Downloading Flutter SDK. This can take several minutes..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

Write-Host "Extracting Flutter SDK to $installRootPath"
Expand-Archive -LiteralPath $zipPath -DestinationPath $installRootPath -Force
Remove-Item -LiteralPath $zipPath -Force

if (-not (Test-Path (Join-Path $flutterBinPath 'flutter.bat'))) {
  throw "Flutter extraction finished, but flutter.bat was not found at $flutterBinPath"
}

$currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathItems = @()
if ($currentUserPath) {
  $pathItems = $currentUserPath.Split(';') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

$alreadyInPath = $pathItems | Where-Object { $_.TrimEnd('\') -ieq $flutterBinPath.TrimEnd('\') }
if (-not $alreadyInPath) {
  $newUserPath = (@($pathItems) + $flutterBinPath) -join ';'
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
  Write-Host "Added Flutter to your user PATH: $flutterBinPath"
} else {
  Write-Host "Flutter is already in your user PATH."
}

$env:Path = "$env:Path;$flutterBinPath"

Write-Host ""
Write-Host "Flutter installed. Version:"
& (Join-Path $flutterBinPath 'flutter.bat') --version

Write-Host ""
Write-Host "Next step: close and reopen PowerShell, then run flutter doctor."

