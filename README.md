# GitHub CLI Tool 🚀

A powerful command-line tool for managing GitHub repositories with ease. Create, clone, delete, and manage repositories directly from your terminal.

## ✨ Features

- 🆕 **Create repositories** with custom settings (private/public, descriptions, licenses, .gitignore)
- 📋 **List all your repositories** with visibility and descriptions
- 📥 **Clone repositories** with optional clean mode (no git history)
- 🗑️ **Delete repositories** with confirmation prompts
- 🌐 **Open repositories** in browser
- 📤 **Push changes** to remote repositories
- 🔐 **Secure authentication** using GitHub Personal Access Tokens
- 🎯 **Cross-platform** support (Linux, macOS, Windows)

## 🚀 Quick Installation

### One-Line Install (Recommended)

**🐧 Mac/Linux/WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-unix.sh | bash
```

**🪟 Windows PowerShell:**
```powershell
iwr -useb https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-windows.ps1 | iex
```

### Alternative Installation Methods

**📋 Manual Installation:**
1. **Download the repository:**
   ```bash
   git clone https://github.com/nisxant69/Github-CLI.git
   cd Github-CLI
   ```

2. **Run the appropriate installer:**
   ```bash
   # Mac/Linux/WSL
   ./install-unix.sh
   ```
   ```powershell
   # Windows PowerShell
   .\install-windows.ps1
   ```

> 📖 **For detailed installation instructions and troubleshooting**, see [INSTALLERS.md](INSTALLERS.md)

3. **Follow the prompts** to configure GitHub authentication

## ⚙️ Installation Requirements

### System Requirements
- **Linux**: Any modern distribution with bash
- **macOS**: 10.9+ (with Xcode Command Line Tools)
- **Windows**: 
  - Windows 10+ with PowerShell 3.0+, OR
  - Git for Windows (includes Git Bash and curl)
  - Windows Subsystem for Linux (WSL) supported

### Required Dependencies
| Dependency | Purpose | Auto-installed |
|------------|---------|---------------|
| **git** | Version control and GitHub operations | ✅ Yes |
| **curl** | HTTP requests for GitHub API | ✅ Yes |
| **jq** | JSON processing | ✅ Yes |
| **bash** | Shell environment | ⚠️ Manual (Windows) |

### Installation Troubleshooting

**🔧 Windows Users:**
- If you get "bash not found": Install [Git for Windows](https://git-scm.com/download/win)
- If PowerShell is restricted: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Alternative: Use WSL (Windows Subsystem for Linux)

**🐧 Linux Users:**
- If installation fails: Ensure you have `curl` and `git` installed
- For jq installation issues: Install manually via your package manager
- Permission issues: The installer will use `sudo` when needed

**🍎 macOS Users:**
- Install Xcode Command Line Tools: `xcode-select --install`
- For Homebrew users: Dependencies install automatically
- Permission issues: Installer uses `/usr/local/bin` with Homebrew

## 📖 Usage

### 🔐 First Time Setup (Authentication)

When you run any repo command for the first time, the tool will automatically set up GitHub authentication:

```bash
repo list  # Triggers interactive setup if not authenticated
```

**What happens:**
1. Opens GitHub token settings page automatically
2. Guides you through creating a Personal Access Token  
3. Prompts for your GitHub username and token
4. Verifies and saves credentials securely
5. You're ready to use all commands!

**Manual setup:**
```bash
repo setup  # Run authentication setup manually
```

### 📚 Commands

#### Create a Repository
```bash
# Basic repository
repo create my-awesome-project

# Advanced repository with all options
repo create my-project -p --desc "My awesome project" --gitignore Node --license mit --topics cli,tool -d ~/projects -push
```

### List Your Repositories
```bash
repo list
```

### Clone a Repository
```bash
# Clone your own repository
repo clone my-project

# Clone someone else's repository
repo clone username/repository-name

# Clone without git history
repo clone -clean username/repo -d ~/downloads
```

### Delete a Repository
```bash
repo delete my-old-project
```

### Open Repository in Browser
```bash
repo open my-project
```

### Push Changes
```bash
repo push
```

### Get Help
```bash
repo help
```

## 🔐 Authentication Setup

The tool uses GitHub Personal Access Tokens for authentication:

1. **Generate a token** at: https://github.com/settings/tokens/new
2. **Required scopes:**
   - `repo` (Full control of private repositories)
   - `delete_repo` (Delete repositories)
3. **Follow the setup prompts** when first running any command

## 🌍 Platform Support

| Platform | Status | Installation Method |
|----------|--------|-------------------|
| **Ubuntu/Debian** | ✅ Full Support | One-line bash installer |
| **RHEL/Fedora/CentOS** | ✅ Full Support | One-line bash installer |
| **Arch Linux** | ✅ Full Support | One-line bash installer |
| **openSUSE** | ✅ Full Support | One-line bash installer |
| **Alpine Linux** | ✅ Full Support | One-line bash installer |
| **macOS** | ✅ Full Support | One-line bash installer |
| **Windows (WSL)** | ✅ Full Support | One-line bash installer |
| **Windows (Git Bash)** | ✅ Full Support | One-line bash installer |
| **Windows (PowerShell)** | ✅ Full Support | PowerShell installer |

## 🛠️ Dependencies

- **git** - Version control
- **curl** - HTTP requests
- **jq** - JSON processing
- **bash** - Shell environment

*Dependencies are automatically installed by the setup script on most platforms.*

## 📝 Examples

### Create a Node.js Project
```bash
repo create my-node-app --desc "My Node.js application" --gitignore Node --license mit --topics nodejs,javascript -push
```

### Create a Private Python Project
```bash
repo create my-python-lib -p --desc "Private Python library" --gitignore Python --license apache-2.0 --topics python,library
```

### Clone and Clean
```bash
repo clone -clean someone/awesome-project -d ~/learning/projects
```

## 🔍 Troubleshooting

### Command Not Found
If `repo` command is not found after installation:
```bash
# Reload your shell configuration
source ~/.bashrc   # Linux/WSL
source ~/.zshrc    # macOS with zsh
```

### Authentication Issues
```bash
# Re-run setup to reconfigure authentication
repo list  # Will prompt for new credentials if needed
```

### Permission Errors
```bash
# For manual installation without sudo (Mac/Linux)
./install-unix.sh  # Will use local installation directory

# For Windows without admin privileges  
.\install-windows.ps1  # Will install in user directory
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- GitHub API for repository management
- The open-source community for inspiration and tools

---

**⭐ Star this repository if you find it useful!**

**Manage your GitHub repositories directly from the terminal — create, delete, clone, list, open, and push — all with one simple CLI!** ✨

## ✨ Features

- 🆕 Create public/private GitHub repositories with description, license, `.gitignore`, and topics  
- ❌ Delete repositories safely with confirmation prompt  
- 📥 Clone any GitHub repository, optionally removing the `.git` folder for a clean start  
- 📋 List all your GitHub repositories with URLs  
- 🌐 Open repository page in your default browser  
- 📤 Push local commits to remote `main` branch  
- ⚙️ Automated setup — zero hassle!

## 🛠️ Requirements

- Git Bash (Windows) or Terminal (macOS/Linux)
- `bash` shell  
- `git`, `curl`, and `jq` (auto-installed by setup script if missing)  
- GitHub Personal Access Token (PAT) with **`repo`** scope 🔐  

## 🚀 Installation

Choose the installer for your operating system:

**Mac/Linux/WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-unix.sh | bash
```

**Windows PowerShell:**
```powershell
iwr -useb https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-windows.ps1 | iex
```

This will:
- 📦 Install dependencies if missing (git, curl, jq)
- 📥 Download and install the repo CLI script
- 🔐 Prompt you for GitHub username & PAT, saving credentials securely

## 🔑 Setting Up Your GitHub Personal Access Token (PAT)

1. Visit [GitHub Token Settings](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Select the `repo` scope (for full control of private repositories)
4. Generate the token and copy it immediately
5. You will be prompted to enter this token during installation

## 💡 Usage

Type the following command to get help and see available commands:

```bash
repo help
```

### Common Commands

```bash
# Create a new GitHub repository (public by default)
repo create MyRepo

# Create a private repository with description, gitignore, license, topics, push initial commit
repo create MyRepo -p --desc "My private repo" --gitignore Node --license mit --topics cli,tool -d ~/projects -push

# Delete a repository with confirmation prompt
repo delete MyRepo

# Clone a repository (default your username)
repo clone MyRepo
repo clone username/OtherRepo

# Clone and remove the .git folder (clean clone)
repo clone username/OtherRepo -clean -d ~/Downloads

# List all your GitHub repositories
repo list

# Open a repository page in your default browser
repo open MyRepo

# Push local commits to the remote main branch
repo push
```

## 🔒 Security Notes

- Credentials are stored securely in your `~/.netrc` file with strict 600 permissions
- Your Personal Access Token must have `repo` scope to enable repo creation, deletion, and pushing
- Never share your Personal Access Token publicly to avoid unauthorized access

## 🐞 Troubleshooting

- If dependencies (git, curl, jq) are missing, run the setup script again
- Authentication errors? Re-run the setup script and carefully re-enter your GitHub username and PAT
- For API issues, check GitHub rate limits and network connectivity
- Make sure your token has the necessary permissions (repo scope)

## 🤝 Contribution & Support

Contributions, bug reports, and feature requests are very welcome!
Please open issues or pull requests at the [GitHub repository](https://github.com/nisxant69/Github-CLI).

## 📄 License

This project is licensed under the MIT License © 2024 nisxant69

---

Ready to get started? Choose your installer:

**Mac/Linux/WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-unix.sh | bash
```

**Windows PowerShell:**
```powershell
iwr -useb https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-windows.ps1 | iex
```

Then use the `repo` command anywhere in your terminal!

Happy coding! 🎉

