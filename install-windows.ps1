# GitHub CLI Tool - Windows Installer
# Usage: iwr -useb https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-windows.ps1 | iex

[CmdletBinding()]
param(
    [string]$InstallDir = "$env:USERPROFILE\.local\bin",
    [switch]$Force,
    [switch]$Global
)

# Set installation directory based on scope
if ($Global) {
    $InstallDir = "$env:ProgramFiles\GitHub-CLI"
    $RequireAdmin = $true
} else {
    $InstallDir = "$env:USERPROFILE\.local\bin"
    $RequireAdmin = $false
}

# Configuration
$GitHubRepo = "nisxant69/Github-CLI"
$RepoUrl = "https://raw.githubusercontent.com/$GitHubRepo/main"
$BinName = "repo.cmd"

# Colors for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️ $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️ $Message" -ForegroundColor Blue }
function Write-Header { param($Message) Write-Host $Message -ForegroundColor Cyan }

# Check if running as administrator when required
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Display header
Clear-Host
Write-Host ""
Write-Header "🚀 GitHub CLI Tool - Windows Installer"
Write-Header "======================================"
Write-Host ""

Write-Info "🪟 Windows PowerShell installer starting..."

# Check admin requirements
if ($RequireAdmin -and -not (Test-Administrator)) {
    Write-Error "Global installation requires administrator privileges."
    Write-Info "Please run PowerShell as Administrator or use user installation:"
    Write-Host "  iwr -useb https://raw.githubusercontent.com/$GitHubRepo/main/install-windows.ps1 | iex"
    exit 1
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Error "PowerShell 3.0 or higher is required"
    exit 1
}

Write-Success "PowerShell version $($PSVersionTable.PSVersion) detected"

# Check dependencies
Write-Info "🔍 Checking dependencies..."
$dependencies = @("git", "curl")
$missing = @()

foreach ($dep in $dependencies) {
    if (!(Get-Command $dep -ErrorAction SilentlyContinue)) {
        $missing += $dep
    }
}

if ($missing.Count -gt 0) {
    Write-Error "Missing required dependencies: $($missing -join ', ')"
    Write-Host ""
    Write-Host "Please install missing dependencies:"
    if ($missing -contains "git") {
        Write-Host "  • Git for Windows: https://git-scm.com/download/win"
        Write-Host "    Or use winget: winget install Git.Git"
    }
    if ($missing -contains "curl") {
        Write-Host "  • cURL is usually included with Windows 10+. If missing:"
        Write-Host "    Download from: https://curl.se/windows/"
    }
    exit 1
}

Write-Success "All dependencies are available"

# Create installation directory
Write-Info "📁 Creating installation directory: $InstallDir"
if (!(Test-Path $InstallDir)) {
    try {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        Write-Success "Created installation directory"
    } catch {
        Write-Error "Failed to create installation directory: $_"
        exit 1
    }
} else {
    Write-Success "Installation directory already exists"
}

# Download repo script
Write-Info "📥 Downloading repo CLI script..."
$repoScript = "$InstallDir\repo"
$wrapperScript = "$InstallDir\$BinName"

try {
    Invoke-WebRequest -Uri "$RepoUrl/repo" -OutFile $repoScript -UseBasicParsing
    if (!(Test-Path $repoScript) -or (Get-Item $repoScript).Length -eq 0) {
        throw "Downloaded file is empty or missing"
    }
    Write-Success "Downloaded repo script"
} catch {
    Write-Error "Failed to download repo script: $_"
    exit 1
}

# Create Windows batch wrapper
Write-Info "🔧 Creating Windows wrapper script..."
$wrapperContent = @"
@echo off
REM GitHub CLI Tool - Windows Wrapper
REM This script calls the bash version through Git Bash

setlocal enabledelayedexpansion

REM Try to find bash in common locations
set "BASH_PATH="
set "BASH_LOCATIONS=C:\Program Files\Git\bin\bash.exe;C:\Program Files (x86)\Git\bin\bash.exe;%USERPROFILE%\AppData\Local\Programs\Git\bin\bash.exe"

for %%i in (%BASH_LOCATIONS%) do (
    if exist "%%i" (
        set "BASH_PATH=%%i"
        goto :bash_found
    )
)

REM If we can't find bash in common locations, try the PATH
where bash.exe >nul 2>&1
if !errorlevel! equ 0 (
    set "BASH_PATH=bash.exe"
) else (
    echo Error: Git Bash not found. Please install Git for Windows.
    echo Download from: https://git-scm.com/download/win
    echo Or install with: winget install Git.Git
    exit /b 1
)

:bash_found
REM Convert Windows path to Unix-style path for bash
set "REPO_SCRIPT=%~dp0repo"
set "REPO_SCRIPT=!REPO_SCRIPT:\=/!"
if "!REPO_SCRIPT:~1,1!" equ ":" (
    set "DRIVE_LETTER=!REPO_SCRIPT:~0,1!"
    call :tolower DRIVE_LETTER
    set "REPO_SCRIPT=/!DRIVE_LETTER!!REPO_SCRIPT:~2!"
)

REM Execute the bash script
"!BASH_PATH!" "!REPO_SCRIPT!" %*
exit /b !errorlevel!

:tolower
for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do call set "%1=!%1:%%i=%%i!"
goto :eof
"@

try {
    Set-Content -Path $wrapperScript -Value $wrapperContent -Encoding ASCII
    Write-Success "Created Windows wrapper script"
} catch {
    Write-Error "Failed to create wrapper script: $_"
    exit 1
}

# Update PATH
Write-Info "🔧 Updating PATH environment variable..."
$pathScope = if ($Global) { "Machine" } else { "User" }
$currentPath = [Environment]::GetEnvironmentVariable("PATH", $pathScope)

if ($currentPath -notlike "*$InstallDir*") {
    try {
        $newPath = if ($currentPath.EndsWith(";")) { $currentPath + $InstallDir } else { $currentPath + ";" + $InstallDir }
        [Environment]::SetEnvironmentVariable("PATH", $newPath, $pathScope)
        Write-Success "Added $InstallDir to $pathScope PATH"
        Write-Warning "Restart your PowerShell/Command Prompt to use 'repo' command globally"
    } catch {
        Write-Error "Failed to update PATH: $_"
        Write-Info "Please manually add $InstallDir to your PATH environment variable"
    }
} else {
    Write-Success "Installation directory already in PATH"
}

# Verify installation
Write-Info "✅ Verifying installation..."
if (Test-Path $wrapperScript) {
    Write-Success "Installation completed successfully!"
    Write-Host ""
    Write-Header "🎉 GitHub CLI tool 'repo' is now installed!"
    Write-Host ""
    Write-Host "📖 Usage Examples:" -ForegroundColor White
    Write-Host "  repo help              Show help and available commands"
    Write-Host "  repo create <name>     Create a new repository"
    Write-Host "  repo list              List your repositories"
    Write-Host "  repo clone <repo>      Clone a repository"
    Write-Host "  repo delete <repo>     Delete a repository"
    Write-Host ""
    Write-Host "🔧 First Time Setup:" -ForegroundColor White
    Write-Host "  1. Restart your PowerShell/Command Prompt"
    Write-Host "  2. Run 'repo list' to configure GitHub authentication"
    Write-Host ""
    
    # Try to test the installation in current session
    try {
        $env:PATH = $env:PATH + ";" + $InstallDir
        Write-Info "Testing installation..."
        & $wrapperScript help 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Test run successful! The tool is working correctly."
        } else {
            Write-Warning "Test run completed. Restart your shell to use 'repo' globally."
        }
    } catch {
        Write-Warning "Please restart your PowerShell/Command Prompt to use the 'repo' command"
    }
    
    Write-Host ""
    Write-Success "✨ Installation completed! Happy coding! 🚀"
    
} else {
    Write-Error "Installation failed - wrapper script not created"
    exit 1
}
