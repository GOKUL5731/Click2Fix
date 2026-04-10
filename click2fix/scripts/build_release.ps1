<#
Build installable Click2Fix release artifacts.

Examples:

  ./scripts/build_release.ps1 -ApiBaseUrl https://api.example.com -SocketUrl https://api.example.com -UserAndroidApk
  ./scripts/build_release.ps1 -ApiBaseUrl https://api.example.com -SocketUrl https://api.example.com -All

Notes:

  - Android builds require Flutter, Android SDK, and Java.
  - Windows builds require Flutter desktop support and Visual Studio C++ build tools.
  - iOS builds require macOS, Xcode, signing certificates, and an Apple Developer account.
#>

[CmdletBinding()]
param(
  [string]$ApiBaseUrl = $env:CLICK2FIX_API_BASE_URL,
  [string]$SocketUrl = $env:CLICK2FIX_SOCKET_URL,
  [switch]$All,
  [switch]$UserAndroidApk,
  [switch]$UserAndroidAab,
  [switch]$UserWindows,
  [switch]$UserIos,
  [switch]$WorkerAndroidApk,
  [switch]$WorkerAndroidAab,
  [switch]$WorkerWindows,
  [switch]$AdminWeb,
  [switch]$AllowLocalhost
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$distDir = Join-Path $root 'dist'

function Require-Command {
  param([Parameter(Mandatory = $true)][string]$Name)

  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' was not found on PATH. Install Flutter and platform build tools first."
  }
}

function Test-ReleaseUrl {
  param([Parameter(Mandatory = $true)][string]$Url)

  $isLocal = $Url -match 'localhost|127\.0\.0\.1|0\.0\.0\.0'
  if ($isLocal -and -not $AllowLocalhost) {
    throw "Release builds must use a public HTTPS API URL. Use -AllowLocalhost only for private testing."
  }

  if (-not $AllowLocalhost -and -not $Url.StartsWith('https://')) {
    throw "Release builds should use HTTPS. Received: $Url"
  }
}

function Initialize-FlutterProject {
  param(
    [Parameter(Mandatory = $true)][string]$AppDir,
    [Parameter(Mandatory = $true)][string]$ProjectName,
    [Parameter(Mandatory = $true)][string]$Platforms
  )

  $platformList = $Platforms.Split(',')
  $missing = @()

  foreach ($platform in $platformList) {
    if (-not (Test-Path (Join-Path $AppDir $platform))) {
      $missing += $platform
    }
  }

  if ($missing.Count -gt 0) {
    Write-Host "Generating Flutter platform folders for ${ProjectName}: $($missing -join ', ')"
    Push-Location $AppDir
    try {
      & flutter create --project-name $ProjectName --org com.click2fix "--platforms=$Platforms" .
    } finally {
      Pop-Location
    }
  }
}

function Invoke-Flutter {
  param(
    [Parameter(Mandatory = $true)][string]$AppDir,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  Push-Location $AppDir
  try {
    & flutter @Arguments
  } finally {
    Pop-Location
  }
}

function Restore-FlutterPackages {
  param([Parameter(Mandatory = $true)][string]$AppDir)

  Invoke-Flutter -AppDir $AppDir -Arguments @('pub', 'get')
}

function Get-DartDefines {
  param([switch]$IncludeSocket)

  $defines = @(
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    '--dart-define=ENVIRONMENT=production'
  )

  if ($IncludeSocket) {
    $defines += "--dart-define=SOCKET_URL=$SocketUrl"
  }

  return $defines
}

function Copy-IfExists {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  if (Test-Path $Source) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination -Parent) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "Artifact: $Destination"
  } else {
    Write-Warning "Expected artifact was not found: $Source"
  }
}

function Build-Android {
  param(
    [Parameter(Mandatory = $true)][string]$AppDir,
    [Parameter(Mandatory = $true)][string]$ProjectName,
    [Parameter(Mandatory = $true)][string]$ArtifactName,
    [switch]$Apk,
    [switch]$Aab
  )

  Initialize-FlutterProject -AppDir $AppDir -ProjectName $ProjectName -Platforms 'android'
  Restore-FlutterPackages -AppDir $AppDir
  $defines = Get-DartDefines -IncludeSocket

  if ($Apk) {
    Invoke-Flutter -AppDir $AppDir -Arguments (@('build', 'apk', '--release') + $defines)
    Copy-IfExists `
      -Source (Join-Path $AppDir 'build\app\outputs\flutter-apk\app-release.apk') `
      -Destination (Join-Path $distDir "$ArtifactName-android-release.apk")
  }

  if ($Aab) {
    Invoke-Flutter -AppDir $AppDir -Arguments (@('build', 'appbundle', '--release') + $defines)
    Copy-IfExists `
      -Source (Join-Path $AppDir 'build\app\outputs\bundle\release\app-release.aab') `
      -Destination (Join-Path $distDir "$ArtifactName-android-release.aab")
  }
}

function Build-Windows {
  param(
    [Parameter(Mandatory = $true)][string]$AppDir,
    [Parameter(Mandatory = $true)][string]$ProjectName,
    [Parameter(Mandatory = $true)][string]$ArtifactName
  )

  Initialize-FlutterProject -AppDir $AppDir -ProjectName $ProjectName -Platforms 'windows'
  Restore-FlutterPackages -AppDir $AppDir
  $defines = Get-DartDefines -IncludeSocket

  Invoke-Flutter -AppDir $AppDir -Arguments (@('build', 'windows', '--release') + $defines)
  $source = Join-Path $AppDir 'build\windows\x64\runner\Release'
  $destination = Join-Path $distDir "$ArtifactName-windows"

  if (Test-Path $source) {
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force
    Write-Host "Artifact folder: $destination"
  } else {
    Write-Warning "Expected Windows release folder was not found: $source"
  }
}

function Build-AdminWeb {
  param([Parameter(Mandatory = $true)][string]$AppDir)

  Initialize-FlutterProject -AppDir $AppDir -ProjectName 'click2fix_admin_panel' -Platforms 'web'
  Restore-FlutterPackages -AppDir $AppDir
  $defines = Get-DartDefines

  Invoke-Flutter -AppDir $AppDir -Arguments (@('build', 'web', '--release') + $defines)
  $source = Join-Path $AppDir 'build\web'
  $destination = Join-Path $distDir 'admin-panel-web'

  if (Test-Path $source) {
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force
    Write-Host "Artifact folder: $destination"
  } else {
    Write-Warning "Expected web release folder was not found: $source"
  }
}

function Build-Ios {
  param([Parameter(Mandatory = $true)][string]$AppDir)

  Initialize-FlutterProject -AppDir $AppDir -ProjectName 'click2fix_mobile_app' -Platforms 'ios'
  Restore-FlutterPackages -AppDir $AppDir
  $defines = Get-DartDefines -IncludeSocket
  Invoke-Flutter -AppDir $AppDir -Arguments (@('build', 'ipa', '--release') + $defines)
}

if (-not $All -and -not $UserAndroidApk -and -not $UserAndroidAab -and -not $UserWindows -and -not $UserIos -and -not $WorkerAndroidApk -and -not $WorkerAndroidAab -and -not $WorkerWindows -and -not $AdminWeb) {
  $All = $true
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  throw 'ApiBaseUrl is required. Pass -ApiBaseUrl https://api.your-domain.com or set CLICK2FIX_API_BASE_URL.'
}

if ([string]::IsNullOrWhiteSpace($SocketUrl)) {
  $SocketUrl = $ApiBaseUrl
}

Test-ReleaseUrl -Url $ApiBaseUrl
Test-ReleaseUrl -Url $SocketUrl
Require-Command -Name 'flutter'
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$mobileApp = Join-Path $root 'mobile_app'
$workerApp = Join-Path $root 'worker_app'
$adminPanel = Join-Path $root 'admin_panel'

if ($All -or $UserAndroidApk -or $UserAndroidAab) {
  Build-Android -AppDir $mobileApp -ProjectName 'click2fix_mobile_app' -ArtifactName 'click2fix-user' -Apk:($All -or $UserAndroidApk) -Aab:($All -or $UserAndroidAab)
}

if ($All -or $WorkerAndroidApk -or $WorkerAndroidAab) {
  Build-Android -AppDir $workerApp -ProjectName 'click2fix_worker_app' -ArtifactName 'click2fix-worker' -Apk:($All -or $WorkerAndroidApk) -Aab:($All -or $WorkerAndroidAab)
}

if ($All -or $UserWindows) {
  Build-Windows -AppDir $mobileApp -ProjectName 'click2fix_mobile_app' -ArtifactName 'click2fix-user'
}

if ($All -or $WorkerWindows) {
  Build-Windows -AppDir $workerApp -ProjectName 'click2fix_worker_app' -ArtifactName 'click2fix-worker'
}

if ($All -or $AdminWeb) {
  Build-AdminWeb -AppDir $adminPanel
}

if ($UserIos) {
  Build-Ios -AppDir $mobileApp
}

Write-Host "Release build finished. Check: $distDir"
