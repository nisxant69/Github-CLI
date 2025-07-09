# GitHub CLI Tool - Windows Installer (Fixed Version)
# Usage: iwr -useb https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-windows.ps1 | iex

[CmdletBinding()]
param(
    [string]$InstallDir = "",
    [switch]$Force,
    [switch]$Global,
    [switch]$Uninstall,
    [string]$Version = "latest",
    [switch]$SkipPathUpdate,
    [switch]$Verbose
)

# Constants
$GITHUB_REPO = "nisxant69/Github-CLI"
$REPO_URL = "https://raw.githubusercontent.com/$GITHUB_REPO/main"
$BIN_NAME = "repo.cmd"
$SCRIPT_NAME = "repo"
$MIN_POWERSHELL_VERSION = [Version]"5.1"
$MAX_PATH_LENGTH = 8100  # Windows PATH limit with safety margin
$DOWNLOAD_TIMEOUT = 30
$RETRY_COUNT = 3

# Set TLS to 1.2 minimum for security
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Logging functions with consistent formatting
function Write-Success { 
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
    if ($Verbose) { Write-Verbose $Message }
}

function Write-Warning { 
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
    Write-Verbose $Message
}

function Write-Error { 
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
    Write-Verbose $Message
}

function Write-Info { 
    param([string]$Message)
    Write-Host "ℹ️ $Message" -ForegroundColor Blue
    if ($Verbose) { Write-Verbose $Message }
}

function Write-Header { 
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Magenta
}

# Utility functions
function Test-Administrator {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        Write-Verbose "Failed to check administrator status: $_"
        return $false
    }
}

function Get-InstallationDirectory {
    param([bool]$IsGlobal)
    
    if ($IsGlobal) {
        return "$env:ProgramFiles\GitHub-CLI"
    } else {
        # Create user-specific directory in a standard location
        $localBin = "$env:USERPROFILE\.local\bin"
        if (!(Test-Path "$env:USERPROFILE\.local")) {
            New-Item -ItemType Directory -Path "$env:USERPROFILE\.local" -Force | Out-Null
        }
        return $localBin
    }
}

function Test-NetworkConnectivity {
    param([string]$Url)
    
    try {
        $request = [System.Net.WebRequest]::Create($Url)
        $request.Method = "HEAD"
        $request.Timeout = 5000
        $response = $request.GetResponse()
        $response.Close()
        return $true
    } catch {
        return $false
    }
}

function Invoke-SecureDownload {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$ExpectedHash = $null
    )
    
    $attempt = 0
    while ($attempt -lt $RETRY_COUNT) {
        try {
            Write-Verbose "Download attempt $($attempt + 1) for $Url"
            
            # Use Invoke-WebRequest with security settings
            $progressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue'
            
            Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -TimeoutSec $DOWNLOAD_TIMEOUT
            
            $ProgressPreference = $progressPreference
            
            # Verify file was downloaded and is not empty
            if (!(Test-Path $OutputPath) -or (Get-Item $OutputPath).Length -eq 0) {
                throw "Downloaded file is empty or missing"
            }
            
            # Verify hash if provided
            if ($ExpectedHash) {
                $actualHash = (Get-FileHash -Path $OutputPath -Algorithm SHA256).Hash
                if ($actualHash -ne $ExpectedHash) {
                    throw "Hash verification failed. Expected: $ExpectedHash, Got: $actualHash"
                }
            }
            
            Write-Verbose "Download successful: $OutputPath"
            return $true
            
        } catch {
            $attempt++
            Write-Verbose "Download attempt $attempt failed: $_"
            
            if (Test-Path $OutputPath) {
                Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
            }
            
            if ($attempt -ge $RETRY_COUNT) {
                throw "Failed to download after $RETRY_COUNT attempts: $_"
            }
            
            Start-Sleep -Seconds (2 * $attempt)
        }
    }
    
    return $false
}

function Test-DependencyFunctionality {
    param([string]$Command)
    
    try {
        switch ($Command) {
            "git" {
                $result = & git --version 2>&1
                return $LASTEXITCODE -eq 0 -and $result -like "*git version*"
            }
            "curl" {
                $result = & curl --version 2>&1
                return $LASTEXITCODE -eq 0 -and $result -like "*curl*"
            }
            default {
                $cmd = Get-Command $Command -ErrorAction SilentlyContinue
                return $null -ne $cmd
            }
        }
    } catch {
        Write-Verbose "Dependency test failed for $Command: $_"
        return $false
    }
}

function Update-PathEnvironment {
    param(
        [string]$Directory,
        [bool]$IsGlobal,
        [bool]$Remove = $false
    )
    
    try {
        $pathScope = if ($IsGlobal) { "Machine" } else { "User" }
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", $pathScope)
        
        if ([string]::IsNullOrEmpty($currentPath)) {
            $currentPath = ""
        }
        
        # Normalize path separators
        $currentPath = $currentPath.TrimEnd(';')
        $pathEntries = $currentPath -split ';' | Where-Object { $_ -ne "" }
        
        if ($Remove) {
            # Remove the directory from PATH
            $pathEntries = $pathEntries | Where-Object { $_ -ne $Directory }
            $newPath = $pathEntries -join ';'
        } else {
            # Add directory to PATH if not already present
            if ($pathEntries -notcontains $Directory) {
                $newPath = ($pathEntries + $Directory) -join ';'
                
                # Check PATH length limit
                if ($newPath.Length -gt $MAX_PATH_LENGTH) {
                    throw "PATH would exceed maximum length ($MAX_PATH_LENGTH characters)"
                }
            } else {
                Write-Info "Directory already in PATH: $Directory"
                return $true
            }
        }
        
        [Environment]::SetEnvironmentVariable("PATH", $newPath, $pathScope)
        
        # Update current session PATH
        $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [Environment]::GetEnvironmentVariable("PATH", "Machine")
        
        if ($Remove) {
            Write-Success "Removed $Directory from $pathScope PATH"
        } else {
            Write-Success "Added $Directory to $pathScope PATH"
        }
        
        return $true
        
    } catch {
        Write-Error "Failed to update PATH: $_"
        return $false
    }
}

function New-WindowsWrapper {
    param(
        [string]$WrapperPath,
        [string]$ScriptPath
    )
    
    # Fixed batch wrapper with proper path conversion
    $wrapperContent = @"
@echo off
setlocal enabledelayedexpansion

REM GitHub CLI Tool - Windows Wrapper
REM This script calls the bash version through Git Bash

REM Find bash executable
set "BASH_PATH="

REM Check common Git installation paths
set "GIT_PATHS=C:\Program Files\Git\bin\bash.exe"
set "GIT_PATHS=!GIT_PATHS!;C:\Program Files (x86)\Git\bin\bash.exe"
set "GIT_PATHS=!GIT_PATHS!;%USERPROFILE%\AppData\Local\Programs\Git\bin\bash.exe"
set "GIT_PATHS=!GIT_PATHS!;%LOCALAPPDATA%\Programs\Git\bin\bash.exe"

for %%i in (!GIT_PATHS!) do (
    if exist "%%i" (
        set "BASH_PATH=%%i"
        goto :bash_found
    )
)

REM Try to find bash in PATH
where bash.exe >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('where bash.exe 2^>nul') do (
        set "BASH_PATH=%%i"
        goto :bash_found
    )
)

echo Error: Git Bash not found. Please install Git for Windows.
echo Download from: https://git-scm.com/download/win
echo Or install with: winget install Git.Git
exit /b 1

:bash_found
REM Convert Windows path to Unix-style path for bash
set "REPO_SCRIPT=$ScriptPath"
set "REPO_SCRIPT=!REPO_SCRIPT:\=/!"

REM Handle drive letter conversion (C: -> /c)
if "!REPO_SCRIPT:~1,1!" equ ":" (
    set "DRIVE_LETTER=!REPO_SCRIPT:~0,1!"
    
    REM Convert to lowercase
    if "!DRIVE_LETTER!" equ "A" set "DRIVE_LETTER=a"
    if "!DRIVE_LETTER!" equ "B" set "DRIVE_LETTER=b"
    if "!DRIVE_LETTER!" equ "C" set "DRIVE_LETTER=c"
    if "!DRIVE_LETTER!" equ "D" set "DRIVE_LETTER=d"
    if "!DRIVE_LETTER!" equ "E" set "DRIVE_LETTER=e"
    if "!DRIVE_LETTER!" equ "F" set "DRIVE_LETTER=f"
    if "!DRIVE_LETTER!" equ "G" set "DRIVE_LETTER=g"
    if "!DRIVE_LETTER!" equ "H" set "DRIVE_LETTER=h"
    if "!DRIVE_LETTER!" equ "I" set "DRIVE_LETTER=i"
    if "!DRIVE_LETTER!" equ "J" set "DRIVE_LETTER=j"
    if "!DRIVE_LETTER!" equ "K" set "DRIVE_LETTER=k"
    if "!DRIVE_LETTER!" equ "L" set "DRIVE_LETTER=l"
    if "!DRIVE_LETTER!" equ "M" set "DRIVE_LETTER=m"
    if "!DRIVE_LETTER!" equ "N" set "DRIVE_LETTER=n"
    if "!DRIVE_LETTER!" equ "O" set "DRIVE_LETTER=o"
    if "!DRIVE_LETTER!" equ "P" set "DRIVE_LETTER=p"
    if "!DRIVE_LETTER!" equ "Q" set "DRIVE_LETTER=q"
    if "!DRIVE_LETTER!" equ "R" set "DRIVE_LETTER=r"
    if "!DRIVE_LETTER!" equ "S" set "DRIVE_LETTER=s"
    if "!DRIVE_LETTER!" equ "T" set "DRIVE_LETTER=t"
    if "!DRIVE_LETTER!" equ "U" set "DRIVE_LETTER=u"
    if "!DRIVE_LETTER!" equ "V" set "DRIVE_LETTER=v"
    if "!DRIVE_LETTER!" equ "W" set "DRIVE_LETTER=w"
    if "!DRIVE_LETTER!" equ "X" set "DRIVE_LETTER=x"
    if "!DRIVE_LETTER!" equ "Y" set "DRIVE_LETTER=y"
    if "!DRIVE_LETTER!" equ "Z" set "DRIVE_LETTER=z"
    
    set "REPO_SCRIPT=/!DRIVE_LETTER!!REPO_SCRIPT:~2!"
)

REM Execute the bash script with all arguments
"!BASH_PATH!" "!REPO_SCRIPT!" %*
exit /b !errorlevel!
"@

    try {
        # Use UTF8 encoding for better compatibility
        $wrapperContent | Out-File -FilePath $WrapperPath -Encoding UTF8
        Write-Success "Created Windows wrapper script"
        return $true
    } catch {
        Write-Error "Failed to create wrapper script: $_"
        return $false
    }
}

function Remove-Installation {
    param(
        [string]$InstallDir,
        [bool]$IsGlobal
    )
    
    Write-Header "🗑️ Uninstalling GitHub CLI Tool"
    
    $success = $true
    
    # Remove files
    if (Test-Path $InstallDir) {
        try {
            $filesToRemove = @(
                "$InstallDir\$BIN_NAME",
                "$InstallDir\$SCRIPT_NAME"
            )
            
            foreach ($file in $filesToRemove) {
                if (Test-Path $file) {
                    Remove-Item $file -Force
                    Write-Success "Removed $file"
                }
            }
            
            # Remove directory if empty
            $remainingFiles = Get-ChildItem $InstallDir -ErrorAction SilentlyContinue
            if ($remainingFiles.Count -eq 0) {
                Remove-Item $InstallDir -Force
                Write-Success "Removed installation directory"
            }
            
        } catch {
            Write-Error "Failed to remove installation files: $_"
            $success = $false
        }
    }
    
    # Remove from PATH
    if (!(Update-PathEnvironment -Directory $InstallDir -IsGlobal $IsGlobal -Remove)) {
        $success = $false
    }
    
    if ($success) {
        Write-Success "✨ Uninstallation completed successfully!"
    } else {
        Write-Error "Uninstallation completed with errors"
    }
    
    return $success
}

function Test-Installation {
    param([string]$WrapperPath)
    
    try {
        Write-Step "Testing installation..."
        
        # Test if wrapper script exists and is executable
        if (!(Test-Path $WrapperPath)) {
            throw "Wrapper script not found at $WrapperPath"
        }
        
        # Try to run the help command
        $result = & $WrapperPath help 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Installation test passed"
            return $true
        } else {
            Write-Warning "Installation test returned non-zero exit code: $LASTEXITCODE"
            Write-Verbose "Test output: $result"
            return $false
        }
        
    } catch {
        Write-Warning "Installation test failed: $_"
        return $false
    }
}

# Main installation function
function Install-GitHubCLI {
    # Display header
    Clear-Host
    Write-Host ""
    Write-Header "🚀 GitHub CLI Tool - Windows Installer (Fixed Version)"
    Write-Header "====================================================="
    Write-Host ""
    
    Write-Info "🪟 Windows PowerShell installer starting..."
    Write-Verbose "PowerShell version: $($PSVersionTable.PSVersion)"
    Write-Verbose "Parameters: Global=$Global, Force=$Force, InstallDir='$InstallDir', Version='$Version'"
    
    # Validate PowerShell version
    if ($PSVersionTable.PSVersion -lt $MIN_POWERSHELL_VERSION) {
        Write-Error "PowerShell $MIN_POWERSHELL_VERSION or higher is required. Current version: $($PSVersionTable.PSVersion)"
        return $false
    }
    Write-Success "PowerShell version $($PSVersionTable.PSVersion) is supported"
    
    # Determine installation scope and directory
    $requireAdmin = $Global
    $installDir = if ($InstallDir) { $InstallDir } else { Get-InstallationDirectory -IsGlobal $Global }
    
    Write-Info "📍 Installation scope: $(if ($Global) { 'Global (All Users)' } else { 'User Only' })"
    Write-Info "📁 Installation directory: $installDir"
    
    # Check admin requirements
    if ($requireAdmin -and -not (Test-Administrator)) {
        Write-Error "Global installation requires administrator privileges."
        Write-Info "Please run PowerShell as Administrator or use user installation (remove -Global flag)"
        return $false
    }
    
    # Check network connectivity
    Write-Step "🌐 Checking network connectivity..."
    if (!(Test-NetworkConnectivity -Url $REPO_URL)) {
        Write-Error "Cannot connect to GitHub repository. Please check your internet connection."
        return $false
    }
    Write-Success "Network connectivity verified"
    
    # Check dependencies
    Write-Step "🔍 Checking dependencies..."
    $dependencies = @("git", "curl")
    $missing = @()
    
    foreach ($dep in $dependencies) {
        Write-Verbose "Testing dependency: $dep"
        if (!(Test-DependencyFunctionality -Command $dep)) {
            $missing += $dep
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Error "Missing or non-functional dependencies: $($missing -join ', ')"
        Write-Host ""
        Write-Host "Please install missing dependencies:" -ForegroundColor Yellow
        if ($missing -contains "git") {
            Write-Host "  • Git for Windows: https://git-scm.com/download/win"
            Write-Host "    Or use winget: winget install Git.Git"
        }
        if ($missing -contains "curl") {
            Write-Host "  • cURL is usually included with Windows 10+. If missing:"
            Write-Host "    Download from: https://curl.se/windows/"
        }
        return $false
    }
    
    Write-Success "All dependencies are functional"
    
    # Create installation directory
    Write-Step "📁 Creating installation directory..."
    if (Test-Path $installDir) {
        if ($Force) {
            Write-Info "Force flag specified - removing existing installation"
            try {
                Remove-Item "$installDir\$BIN_NAME" -Force -ErrorAction SilentlyContinue
                Remove-Item "$installDir\$SCRIPT_NAME" -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Verbose "Error removing existing files: $_"
            }
        } else {
            Write-Info "Installation directory already exists"
        }
    }
    
    try {
        if (!(Test-Path $installDir)) {
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        }
        Write-Success "Installation directory ready"
    } catch {
        Write-Error "Failed to create installation directory: $_"
        return $false
    }
    
    # Download repo script
    Write-Step "📥 Downloading repo CLI script..."
    $repoScript = "$installDir\$SCRIPT_NAME"
    
    try {
        if (!(Invoke-SecureDownload -Url "$REPO_URL/repo" -OutputPath $repoScript)) {
            throw "Download failed"
        }
        Write-Success "Downloaded repo script"
    } catch {
        Write-Error "Failed to download repo script: $_"
        return $false
    }
    
    # Create Windows wrapper
    Write-Step "🔧 Creating Windows wrapper script..."
    $wrapperScript = "$installDir\$BIN_NAME"
    
    if (!(New-WindowsWrapper -WrapperPath $wrapperScript -ScriptPath $repoScript)) {
        return $false
    }
    
    # Update PATH
    if (!$SkipPathUpdate) {
        Write-Step "🔧 Updating PATH environment variable..."
        if (!(Update-PathEnvironment -Directory $installDir -IsGlobal $Global)) {
            Write-Warning "PATH update failed - you may need to manually add $installDir to your PATH"
        }
    } else {
        Write-Info "Skipping PATH update (SkipPathUpdate flag specified)"
    }
    
    # Test installation
    if (!(Test-Installation -WrapperPath $wrapperScript)) {
        Write-Warning "Installation test failed - the tool may not work correctly"
    }
    
    # Success message
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
    Write-Host "🔧 Next Steps:" -ForegroundColor White
    Write-Host "  1. Restart your PowerShell/Command Prompt (if PATH was updated)"
    Write-Host "  2. Run 'repo help' to see all available commands"
    Write-Host "  3. Run 'repo list' to configure GitHub authentication"
    Write-Host ""
    Write-Host "🛠️ Troubleshooting:" -ForegroundColor White
    Write-Host "  • If 'repo' command not found: Add $installDir to your PATH"
    Write-Host "  • For uninstallation: Run this script with -Uninstall flag"
    Write-Host "  • For help: Visit https://github.com/$GITHUB_REPO"
    Write-Host ""
    Write-Success "✨ Installation completed successfully! Happy coding! 🚀"
    
    return $true
}

# Main execution
try {
    if ($Uninstall) {
        $installDir = if ($InstallDir) { $InstallDir } else { Get-InstallationDirectory -IsGlobal $Global }
        
        if ($Global -and -not (Test-Administrator)) {
            Write-Error "Global uninstallation requires administrator privileges."
            exit 1
        }
        
        if (Remove-Installation -InstallDir $installDir -IsGlobal $Global) {
            exit 0
        } else {
            exit 1
        }
    } else {
        if (Install-GitHubCLI) {
            exit 0
        } else {
            Write-Error "Installation failed"
            exit 1
        }
    }
} catch {
    Write-Error "Script execution failed: $_"
    Write-Verbose $_.ScriptStackTrace
    exit 1
}