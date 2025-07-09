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

## 🔐 How Users Login/Authenticate

The GitHub CLI tool uses **GitHub Personal Access Tokens (PAT)** for authentication. Here's how users will log in:

### 🚀 **Automatic Setup (Recommended)**

When users run any command for the first time (like `repo list`), the tool will automatically detect that no credentials are configured and launch an interactive setup:

```bash
# First time running any repo command
repo list
```

**What happens:**
1. ✅ Tool detects no credentials exist
2. 🌐 Opens GitHub token settings page automatically 
3. 📋 Shows step-by-step instructions
4. 💬 Prompts for GitHub username
5. 🔐 Prompts for Personal Access Token
6. ✅ Verifies credentials with GitHub API
7. 💾 Saves credentials securely to `~/.netrc`
8. 🎉 Ready to use all commands!

### 🔧 **Manual Setup**

Users can also run the setup explicitly:

```bash
repo setup
```

### 📋 **Step-by-Step Process for Users:**

1. **Run any repo command** (e.g., `repo list`)
2. **Follow the interactive prompts:**
   - Tool opens https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Give it a name (e.g., "GitHub CLI Tool")  
   - Select the `repo` scope
   - Click "Generate token"
   - Copy the generated token
3. **Enter credentials when prompted:**
   - GitHub username
   - Personal Access Token
4. **Tool verifies and saves credentials**
5. **Start using all repo commands!**

### 🔒 **Security Features:**

- ✅ **Secure Storage**: Credentials stored in `~/.netrc` with 600 permissions
- ✅ **Token Verification**: Validates token before saving
- ✅ **Scope Checking**: Ensures token has required permissions
- ✅ **Username Verification**: Confirms token matches provided username
- ✅ **Backup**: Backs up existing `.netrc` if present

### 🎯 **User Experience:**

**Before (Old System):**
```bash
$ repo list
No GitHub credentials found in ~/.netrc. Please run setup script.
# User gets stuck - no setup script exists!
```

**After (New System):**
```bash
$ repo list
🔐 GitHub credentials not found. Let's set them up!

To use this GitHub CLI tool, you need a Personal Access Token (PAT).

📋 Follow these steps:
1. Go to: https://github.com/settings/tokens
2. Click 'Generate new token (classic)'
3. Give it a name like 'GitHub CLI Tool'
4. Select the 'repo' scope (full control of private repositories)
5. Click 'Generate token'
6. Copy the generated token

🌐 Opening GitHub token settings page...

Enter your GitHub username: myusername
Enter your GitHub Personal Access Token: [hidden]

🔍 Verifying credentials...
✅ Credentials verified for user: myusername
💾 Saving credentials...
✅ Setup complete!

🎉 You can now use all repo commands:
  repo list              # List your repositories
  repo create <name>     # Create a new repository
  repo clone <repo>      # Clone a repository
```

### 📱 **Commands Available:**

```bash
repo setup              # Manual authentication setup
repo help               # Show all commands
repo list               # List repositories (triggers setup if needed)
repo create <name>      # Create new repository
repo clone <repo>       # Clone repository
repo delete <repo>      # Delete repository
repo open <repo>        # Open in browser
repo push               # Push changes
```

---

Choose the installer that matches your operating system and enjoy using the GitHub CLI tool! 🎉
