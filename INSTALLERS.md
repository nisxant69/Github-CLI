# GitHub CLI Installers

This repository contains two optimized installer scripts for the GitHub CLI tool:

## 🪟 Windows Installer (`install-windows.ps1`)

**Optimized for Windows PowerShell environments**

### Features:
- ✅ PowerShell-native installation
- ✅ Automatic dependency checking (Git, cURL)
- ✅ Smart PATH management (User/System scope)
- ✅ Windows batch wrapper creation
- ✅ Admin privilege detection for global installs
- ✅ Beautiful colored output with emojis
- ✅ Comprehensive error handling

### Usage:

**Standard Installation (Current User):**
```powershell
iwr -useb https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-windows.ps1 | iex
```

**Global Installation (Requires Admin):**
```powershell
# Run PowerShell as Administrator
iwr -useb https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-windows.ps1 | iex -Global
```

**Custom Installation Directory:**
```powershell
iwr -useb https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-windows.ps1 | iex -InstallDir "C:\MyTools"
```

---

## 🍎🐧 Mac/Linux Installer (`install-unix.sh`)

**Universal installer for macOS, Linux, and WSL**

### Features:
- ✅ Auto-detects OS (macOS, Linux distros, WSL)
- ✅ Smart installation directory selection
- ✅ Automatic dependency checking and installation
- ✅ Optional jq installation for enhanced functionality
- ✅ Shell profile auto-configuration (.bashrc, .zshrc, etc.)
- ✅ Beautiful colored output with emojis
- ✅ Privilege escalation handling (sudo when available)
- ✅ Works on all major Linux distributions

### Usage:

**One-line Installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-unix.sh | bash
```

**Download and Run:**
```bash
# Download
curl -O https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-unix.sh

# Make executable
chmod +x install-unix.sh

# Run
./install-unix.sh
```

---

## 🚀 What Gets Installed

Both installers will:

1. **Download** the main `repo` script from the GitHub repository
2. **Install** it to an appropriate location:
   - **Windows**: `%USERPROFILE%\.local\bin\` or `%ProgramFiles%\GitHub-CLI\`
   - **Mac/Linux**: `/usr/local/bin/` (global) or `~/.local/bin/` (user)
3. **Create** necessary wrapper scripts (Windows batch file)
4. **Update** your system PATH automatically
5. **Verify** the installation works correctly

## 📖 Usage After Installation

After installation, you can use the `repo` command:

```bash
# Show help
repo help

# Create a new repository
repo create my-awesome-project

# List your repositories
repo list

# Clone a repository
repo clone username/repository

# Delete a repository
repo delete username/repository

# Open repository in browser
repo open username/repository
```

## 🔧 First-Time Setup

1. Run `repo list` to initiate GitHub authentication
2. Create a GitHub Personal Access Token when prompted
3. Follow the on-screen instructions to configure the tool

## 🛠️ Troubleshooting

### Windows Issues:
- **"PowerShell execution policy"**: Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **"Git not found"**: Install Git for Windows from https://git-scm.com/download/win
- **"Admin required"**: Run PowerShell as Administrator for global installation

### Mac/Linux Issues:
- **"Permission denied"**: Use `sudo` or ensure you have write access to the installation directory
- **"curl not found"**: Install curl using your package manager (`brew install curl`, `apt install curl`, etc.)
- **"Command not found after install"**: Restart your shell or run `source ~/.bashrc` (or equivalent)

## 📝 Notes

- **Windows**: The installer creates a batch wrapper that calls the bash script through Git Bash
- **Mac/Linux**: Direct bash script installation with automatic shell profile configuration
- **Dependencies**: Both installers check for and help install required dependencies
- **PATH**: Both installers automatically update your PATH environment variable
- **Permissions**: Smart privilege handling - uses sudo when available, falls back to user installation

## 🆚 Differences from Original Installers

These new installers are:
- **More focused**: One optimized for Windows, one for Unix-like systems
- **More robust**: Better error handling and dependency checking
- **More user-friendly**: Clearer output messages and progress indication
- **More flexible**: Multiple installation options and automatic fallbacks
- **More reliable**: Comprehensive verification and testing steps

---

Choose the installer that matches your operating system and enjoy using the GitHub CLI tool! 🎉
