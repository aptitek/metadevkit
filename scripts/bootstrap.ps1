# =============================================================================
# bootstrap.ps1 — Windows One-Liner MSYS2 + Taskfile Project Bootstrapper
# Automatically provisions MSYS2, go-task, and mise via winget, installs
# UNIX prerequisites (bash, git, jq, curl, tar) inside MSYS2, downloads the
# master Taskfile.yml, and initializes the project.
#
# One-Liner Usage (PowerShell):
#   irm https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.ps1 | iex
#   $env:MODULES="core,lang:python,fw:django"; irm https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.ps1 | iex
# =============================================================================
$ErrorActionPreference = "Stop"

$Modules = if ($env:MODULES) { $env:MODULES } else { "core,lang:ts" }
$RepoUrl = if ($env:REPO_URL) { $env:REPO_URL } else { "https://github.com/aptitek/metadevkit.git" }
$RawTaskfileUrl = "https://raw.githubusercontent.com/aptitek/metadevkit/main/Taskfile.yml"

Write-Host "🚀 [polyglot-guardrails] Bootstrapping Windows environment (MSYS2 + go-task + mise)..." -ForegroundColor Cyan

# 1. Install MSYS2 if not present at C:\msys64
$MsysBash = "C:\msys64\usr\bin\bash.exe"
$MsysPacman = "C:\msys64\usr\bin\pacman.exe"
if (-not (Test-Path $MsysBash)) {
    Write-Host "📦 Installing MSYS2 via winget..." -ForegroundColor Yellow
    winget install -e --id MSYS2.MSYS2 --accept-source-agreements --accept-package-agreements
}

# 2. Ensure core POSIX tools exist inside MSYS2
if (Test-Path $MsysPacman) {
    Write-Host "📦 Installing bash, git, jq, curl, and tar inside MSYS2..." -ForegroundColor Yellow
    & $MsysPacman -S --noconfirm --needed bash git jq curl tar
}

# 3. Install go-task and mise via winget if missing
if (-not (Get-Command task -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing go-task (Task.Task) via winget..." -ForegroundColor Yellow
    winget install -e --id Task.Task --accept-source-agreements --accept-package-agreements
}
if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing mise (jdx.mise) via winget..." -ForegroundColor Yellow
    winget install -e --id jdx.mise --accept-source-agreements --accept-package-agreements
}

# 4. Download the self-bootstrapping master Taskfile.yml into the current directory
Write-Host "📥 Downloading master Taskfile.yml..." -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $RawTaskfileUrl -OutFile "Taskfile.yml"

# 5. Execute task init inside MSYS2 bash with C:\msys64\usr\bin on PATH
$WorkDir = (Get-Location).Path -replace '\\', '/'
& $MsysBash -lc "cd '$WorkDir' && export PATH='/c/msys64/usr/bin:`$PATH' && task init MODULES='$Modules' REPO_URL='$RepoUrl'"
Write-Host "✅ Project initialized with modules: $Modules" -ForegroundColor Green
