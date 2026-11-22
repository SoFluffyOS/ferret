# Builds Ferret's Windows packages from packaging/windows into
# build\windows-packages:
#
#   powershell -ExecutionPolicy Bypass -File scripts\package_windows.ps1 [inno|msix|all]   (default: inno)
#
# Runs on Windows only (x64 or arm64): Flutter can't cross-build a Windows
# app from macOS or Linux. Every target first builds the release bundle
# (fvm flutter build windows) and ferret-cli (dart compile exe).
#
# Needs: fvm, Visual Studio 2022 with "Desktop development with C++", and
#   inno   Inno Setup 6 (winget install JRSoftware.InnoSetup), or set ISCC
#          to ISCC.exe
#   msix   the Windows 10/11 SDK (makeappx.exe, signtool.exe). Set
#          FERRET_MSIX_PUBLISHER to the certificate's subject ("CN=...");
#          set FERRET_MSIX_CERT (a .pfx) and FERRET_MSIX_CERT_PASSWORD to sign.
#          An unsigned .msix won't install outside developer mode.
#
# FERRET_WINDOWS_CERT (a .pfx) and FERRET_WINDOWS_CERT_PASSWORD sign
# ferret.exe, ferret-cli.exe and the setup with Authenticode. Ferret's
# updater installs a new setup only when it is validly signed by the same
# publisher as the running ferret.exe, so release builds need them.
#
# Every run writes SHA256SUMS next to the packages; merge it with the other
# platforms' into the one SHA256SUMS the release carries.
[CmdletBinding()]
param(
  [ValidateSet('inno', 'msix', 'all')]
  [string]$Target = 'inno'
)

$ErrorActionPreference = 'Stop'

if ([System.Environment]::OSVersion.Platform -ne 'Win32NT') {
  Write-Error "package_windows.ps1 builds on Windows only. Flutter can't cross-build a Windows app: run it on a Windows machine or VM."
  exit 1
}

$Root = Split-Path -Parent $PSScriptRoot
$Packaging = Join-Path $Root 'packaging\windows'
$Out = Join-Path $Root 'build\windows-packages'
# Scratch trees go to fresh temp folders, and an old stage is moved there, so
# nothing is deleted.
$Stage = Join-Path $Out 'stage'
$AppId = 'io.sofluffy.ferret'

switch ($env:PROCESSOR_ARCHITECTURE) {
  'AMD64' { $Arch = 'x64' }
  'ARM64' { $Arch = 'arm64' }
  default { Write-Error "Unsupported machine: $($env:PROCESSOR_ARCHITECTURE)"; exit 1 }
}

$Pubspec = Get-Content (Join-Path $Root 'apps\ferret\pubspec.yaml')
$Version = ($Pubspec | Select-String -Pattern '^version:\s*([^+\s]+)').Matches[0].Groups[1].Value

function Invoke-Checked {
  param([string]$FilePath, [string[]]$Arguments)
  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$FilePath exited with $LASTEXITCODE"
  }
}

function New-TempFolder {
  $path = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
  New-Item -ItemType Directory -Path $path | Out-Null
  return $path
}

function Build-Stage {
  Write-Host "==> Flutter bundle and ferret-cli ($Version, $Arch)"
  Push-Location (Join-Path $Root 'apps\ferret')
  try {
    Invoke-Checked 'fvm' @('flutter', 'build', 'windows', '--release')
  } finally {
    Pop-Location
  }

  if (Test-Path $Stage) {
    Move-Item $Stage (New-TempFolder)
  }
  New-Item -ItemType Directory -Path $Stage -Force | Out-Null

  $bundle = Join-Path $Root "apps\ferret\build\windows\$Arch\runner\Release"
  Copy-Item -Path (Join-Path $bundle '*') -Destination $Stage -Recurse

  Push-Location (Join-Path $Root 'apps\ferret_cli')
  try {
    Invoke-Checked 'fvm' @('dart', 'compile', 'exe', 'bin\ferret.dart', '-o', (Join-Path $Stage 'ferret-cli.exe'))
  } finally {
    Pop-Location
  }

  Set-Signature (Join-Path $Stage 'ferret.exe')
  Set-Signature (Join-Path $Stage 'ferret-cli.exe')

  # Flutter's runner links the MSVC runtime dynamically. Shipping the DLLs
  # next to ferret.exe (app-local) spares users the VC++ redistributable.
  $system = Join-Path $env:SystemRoot 'System32'
  foreach ($dll in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
    $source = Join-Path $system $dll
    if ((Test-Path $source) -and -not (Test-Path (Join-Path $Stage $dll))) {
      Copy-Item $source $Stage
    }
  }
}

function Set-Signature {
  param([string]$Path)
  if (-not $env:FERRET_WINDOWS_CERT) {
    Write-Warning "FERRET_WINDOWS_CERT not set: $Path is unsigned, and Ferret's updater won't install it."
    return
  }
  Invoke-Checked (Find-SdkTool 'signtool.exe') @(
    'sign', '/fd', 'SHA256', '/tr', 'http://timestamp.digicert.com', '/td', 'SHA256',
    '/f', $env:FERRET_WINDOWS_CERT, '/p', $env:FERRET_WINDOWS_CERT_PASSWORD, $Path
  )
}

function Write-Sums {
  $lines = Get-ChildItem -Path $Out -File |
    Where-Object { $_.Name -like "*$Version*" -or $_.Name -like 'Ferret-windows-*-setup.exe' } |
    Sort-Object Name |
    ForEach-Object { "$((Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower())  $($_.Name)" }
  $text = ($lines -join "`n") + "`n"
  [System.IO.File]::WriteAllText((Join-Path $Out 'SHA256SUMS'), $text, (New-Object System.Text.UTF8Encoding $false))
  Write-Host $text
}

function Find-Iscc {
  $candidates = @(
    $env:ISCC,
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
  )
  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }
  throw 'Inno Setup 6 not found. Install it (winget install JRSoftware.InnoSetup) or set ISCC to ISCC.exe.'
}

function Find-SdkTool {
  param([string]$Name)
  $kits = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
  $tool = Get-ChildItem -Path $kits -Filter $Name -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\\x64\\$Name$" } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
  if (-not $tool) {
    throw "$Name not found. Install the Windows 10/11 SDK."
  }
  return $tool.FullName
}

function Build-Inno {
  Write-Host '==> Inno Setup installer'
  $iscc = Find-Iscc
  Invoke-Checked $iscc @(
    "/DAppVersion=$Version",
    "/DArch=$Arch",
    "/DSourceDir=$Stage",
    "/DOutputDir=$Out",
    (Join-Path $Packaging 'ferret.iss')
  )
  $installer = Join-Path $Out "Ferret-$Version-$Arch-setup.exe"
  Set-Signature $installer
  # The landing page's Download button points at a name that never changes:
  # releases/latest/download/Ferret-windows-x64-setup.exe.
  Copy-Item -Force $installer (Join-Path $Out "Ferret-windows-$Arch-setup.exe")
  $hash = (Get-FileHash $installer -Algorithm SHA256).Hash
  Write-Host "    $installer"
  Write-Host "    SHA256 $hash (InstallerSha256 in the winget manifest)"
}

function Build-Msix {
  Write-Host '==> MSIX'
  $publisher = $env:FERRET_MSIX_PUBLISHER
  if (-not $publisher) {
    $publisher = 'CN=SoFluffy'
    Write-Warning "FERRET_MSIX_PUBLISHER isn't set; using $publisher. It must match the signing certificate's subject."
  }

  $layout = New-TempFolder
  Copy-Item -Path (Join-Path $Stage '*') -Destination $layout -Recurse
  Copy-Item -Path (Join-Path $Packaging 'msix\Assets') -Destination $layout -Recurse
  $manifest = Get-Content (Join-Path $Packaging 'msix\AppxManifest.xml') -Raw
  $manifest = $manifest.Replace('@VERSION@', "$Version.0")
  $manifest = $manifest.Replace('@ARCH@', $Arch)
  $manifest = $manifest.Replace('@PUBLISHER@', [System.Security.SecurityElement]::Escape($publisher))
  [System.IO.File]::WriteAllText((Join-Path $layout 'AppxManifest.xml'), $manifest, (New-Object System.Text.UTF8Encoding $false))

  $msix = Join-Path $Out "Ferret-$Version-$Arch.msix"
  Invoke-Checked (Find-SdkTool 'makeappx.exe') @('pack', '/o', '/d', $layout, '/p', $msix)

  if ($env:FERRET_MSIX_CERT) {
    Invoke-Checked (Find-SdkTool 'signtool.exe') @(
      'sign', '/fd', 'SHA256', '/tr', 'http://timestamp.digicert.com', '/td', 'SHA256',
      '/f', $env:FERRET_MSIX_CERT, '/p', $env:FERRET_MSIX_CERT_PASSWORD, $msix
    )
  } else {
    Write-Warning 'FERRET_MSIX_CERT not set: the .msix is unsigned and installs only in developer mode.'
  }
  Write-Host "    $msix"
}

New-Item -ItemType Directory -Path $Out -Force | Out-Null
Build-Stage

switch ($Target) {
  'inno' { Build-Inno }
  'msix' { Build-Msix }
  'all' { Build-Inno; Build-Msix }
}

Write-Sums
Write-Host "Done: $Out"
