#!/bin/bash
# GitHub CLI Tool - Mac/Linux Universal Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-unix.sh | bash

set -e

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions with emojis
log() { echo -e "${GREEN}✅${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1"; }
info() { echo -e "${BLUE}ℹ️${NC} $1"; }
header() { echo -e "${CYAN}$1${NC}"; }

# Configuration
GITHUB_REPO="nisxant69/Github-CLI"
REPO_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
BIN_NAME="repo"
INSTALL_DIR=""
USE_SUDO=false

# Display header
clear
echo ""
header "🚀 GitHub CLI Tool - Mac/Linux Installer"
header "========================================"
echo ""

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -n "$WSL_DISTRO_NAME" ]]; then
            OS="wsl"
            DISTRO="WSL: $WSL_DISTRO_NAME"
            info "🪟 Windows Subsystem for Linux detected: $WSL_DISTRO_NAME"
        else
            OS="linux"
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO="$PRETTY_NAME"
            else
                DISTRO="Unknown Linux"
            fi
            info "🐧 Linux detected: $DISTRO"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macOS $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
        info "🍎 macOS detected: $DISTRO"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        DISTRO="Git Bash/MSYS2"
        info "🪟 Windows (Git Bash) detected"
    else
        OS="unknown"
        DISTRO="Unknown OS: $OSTYPE"
        warn "❓ Unknown operating system detected: $OSTYPE"
        warn "Proceeding with generic Unix installation..."
    fi
}

# Determine the best installation directory
set_install_dir() {
    # Check if we have global installation privileges
    if [[ "$EUID" -eq 0 ]] || (command -v sudo >/dev/null && sudo -n true 2>/dev/null); then
        # Can install globally
        case "$OS" in
            "macos")
                if command -v brew >/dev/null; then
                    INSTALL_DIR="/opt/homebrew/bin"
                    if [[ ! -d "/opt/homebrew/bin" ]]; then
                        INSTALL_DIR="/usr/local/bin"
                    fi
                else
                    INSTALL_DIR="/usr/local/bin"
                fi
                USE_SUDO=true
                ;;
            "linux"|"wsl"|*)
                INSTALL_DIR="/usr/local/bin"
                USE_SUDO=true
                ;;
        esac
    else
        # User installation
        INSTALL_DIR="$HOME/.local/bin"
        USE_SUDO=false
        mkdir -p "$INSTALL_DIR"
    fi
    
    info "📁 Installation directory: $INSTALL_DIR"
    if [[ "$USE_SUDO" == true ]]; then
        info "🔒 Using sudo for global installation"
    else
        info "👤 Installing for current user only"
    fi
}

# Check if required dependencies are available
check_dependencies() {
    info "🔍 Checking required dependencies..."
    
    local deps=("curl" "git" "bash")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Please install them first:"
        case "$OS" in
            "linux"|"wsl")
                echo "  • Ubuntu/Debian: sudo apt update && sudo apt install -y ${missing[*]}"
                echo "  • RHEL/Fedora:   sudo dnf install -y ${missing[*]}"
                echo "  • Arch Linux:    sudo pacman -S --noconfirm ${missing[*]}"
                echo "  • Alpine:        sudo apk add ${missing[*]}"
                ;;
            "macos")
                echo "  • Using Homebrew: brew install ${missing[*]}"
                echo "  • Or install Xcode Command Line Tools: xcode-select --install"
                ;;
            *)
                echo "  • Please install using your system's package manager"
                ;;
        esac
        exit 1
    fi
    
    log "All required dependencies are available"
}

# Install jq for JSON processing (optional but recommended)
install_jq() {
    if command -v jq >/dev/null 2>&1; then
        log "jq is already installed"
        return
    fi
    
    info "📦 Installing jq (recommended for enhanced functionality)..."
    
    case "$OS" in
        "linux"|"wsl")
            if command -v apt >/dev/null && [[ "$USE_SUDO" == true ]]; then
                sudo apt update >/dev/null 2>&1 && sudo apt install -y jq
            elif command -v dnf >/dev/null && [[ "$USE_SUDO" == true ]]; then
                sudo dnf install -y jq
            elif command -v pacman >/dev/null && [[ "$USE_SUDO" == true ]]; then
                sudo pacman -S --noconfirm jq
            elif command -v apk >/dev/null && [[ "$USE_SUDO" == true ]]; then
                sudo apk add jq
            else
                warn "Could not install jq automatically. The tool will work without it."
                return
            fi
            ;;
        "macos")
            if command -v brew >/dev/null; then
                brew install jq
            else
                warn "Homebrew not found. Install jq manually: https://github.com/stedolan/jq"
                return
            fi
            ;;
        *)
            warn "Cannot auto-install jq on this system. Install manually if needed."
            return
            ;;
    esac
    
    if command -v jq >/dev/null 2>&1; then
        log "jq installed successfully"
    else
        warn "jq installation failed, but repo tool will still work"
    fi
}

# Download and install the main repo script
install_repo_script() {
    info "📥 Downloading GitHub CLI repo script..."
    
    local temp_file
    temp_file=$(mktemp)
    
    # Download with progress bar if possible
    if curl --help 2>/dev/null | grep -q "\-\-progress-bar"; then
        if ! curl --progress-bar -fSL "${REPO_URL}/repo" -o "$temp_file"; then
            error "Failed to download repo script from ${REPO_URL}/repo"
            error "Please check your internet connection and try again"
            exit 1
        fi
    else
        if ! curl -fsSL "${REPO_URL}/repo" -o "$temp_file"; then
            error "Failed to download repo script"
            exit 1
        fi
    fi
    
    # Verify the downloaded file
    if [ ! -s "$temp_file" ]; then
        error "Downloaded file is empty or corrupted"
        exit 1
    fi
    
    # Verify it's a valid bash script
    if ! head -n1 "$temp_file" | grep -q "#!/bin/bash"; then
        error "Downloaded file is not a valid bash script"
        error "File contents: $(head -n3 "$temp_file")"
        exit 1
    fi
    
    info "🔧 Installing repo script..."
    
    # Install the script with appropriate permissions
    if [ "$USE_SUDO" = true ]; then
        sudo cp "$temp_file" "$INSTALL_DIR/$BIN_NAME"
        sudo chmod +x "$INSTALL_DIR/$BIN_NAME"
        sudo chown root:root "$INSTALL_DIR/$BIN_NAME" 2>/dev/null || true
    else
        cp "$temp_file" "$INSTALL_DIR/$BIN_NAME"
        chmod +x "$INSTALL_DIR/$BIN_NAME"
    fi
    
    # Clean up
    rm -f "$temp_file"
    
    log "GitHub CLI installed to $INSTALL_DIR/$BIN_NAME"
}

# Update PATH if necessary
update_path() {
    # Check if install directory is already in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        log "Installation directory is already in PATH"
        return
    fi
    
    info "🔧 Adding $INSTALL_DIR to PATH..."
    
    local profile_updated=false
    
    case "$OS" in
        "linux"|"wsl")
            # Try to add to appropriate shell profile
            if [[ -n "$ZSH_VERSION" ]] && [[ -f "$HOME/.zshrc" ]]; then
                echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.zshrc"
                warn "Added to ~/.zshrc - restart your shell or run: source ~/.zshrc"
                profile_updated=true
            elif [[ -f "$HOME/.bashrc" ]]; then
                echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
                warn "Added to ~/.bashrc - restart your shell or run: source ~/.bashrc"
                profile_updated=true
            fi
            if [[ -f "$HOME/.profile" ]] && [[ "$profile_updated" == false ]]; then
                echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.profile"
                warn "Added to ~/.profile - restart your shell or run: source ~/.profile"
                profile_updated=true
            fi
            ;;
        "macos")
            if [[ -f "$HOME/.zshrc" ]]; then
                echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.zshrc"
                warn "Added to ~/.zshrc - restart your shell or run: source ~/.zshrc"
                profile_updated=true
            elif [[ -f "$HOME/.bash_profile" ]]; then
                echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bash_profile"
                warn "Added to ~/.bash_profile - restart your shell or run: source ~/.bash_profile"
                profile_updated=true
            fi
            ;;
        "windows")
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
                warn "Added to ~/.bashrc - restart Git Bash or run: source ~/.bashrc"
                profile_updated=true
            fi
            ;;
    esac
    
    if [[ "$profile_updated" == false ]]; then
        warn "Could not automatically update PATH. Please add this line to your shell profile:"
        echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
    fi
}

# Verify the installation worked correctly
verify_installation() {
    info "✅ Verifying installation..."
    
    if [ ! -x "$INSTALL_DIR/$BIN_NAME" ]; then
        error "Installation failed - script not found or not executable at $INSTALL_DIR/$BIN_NAME"
        exit 1
    fi
    
    # Test if the script can run
    if ! "$INSTALL_DIR/$BIN_NAME" help >/dev/null 2>&1; then
        warn "Script installed but may have issues. Try running: $INSTALL_DIR/$BIN_NAME help"
    fi
    
    log "Installation verification successful!"
}

# Display success message and usage information
show_success_message() {
    echo ""
    header "🎉 GitHub CLI tool 'repo' installed successfully!"
    echo ""
    echo -e "${WHITE}📖 Usage Examples:${NC}"
    echo "  repo help              Show help and available commands"
    echo "  repo create <name>     Create a new repository"
    echo "  repo list              List your repositories"  
    echo "  repo clone <repo>      Clone a repository"
    echo "  repo delete <repo>     Delete a repository"
    echo "  repo open <repo>       Open repository in browser"
    echo ""
    echo -e "${WHITE}🔧 First Time Setup:${NC}"
    echo "  1. Run 'repo list' to configure GitHub authentication"
    echo "  2. Create a GitHub Personal Access Token if prompted"
    echo ""
    echo -e "${WHITE}🚀 Quick Test:${NC}"
    
    # Try to run help command if repo is in PATH
    if command -v "$BIN_NAME" >/dev/null 2>&1; then
        echo "  Command 'repo' is ready to use!"
        echo ""
        echo "  Running quick test..."
        if "$BIN_NAME" help >/dev/null 2>&1; then
            log "✨ Test successful! The tool is working perfectly."
        else
            warn "Tool installed but may need configuration. Run 'repo help' for more info."
        fi
    else
        echo "  Restart your shell, then run: repo help"
        warn "Or run directly: $INSTALL_DIR/$BIN_NAME help"
    fi
    
    echo ""
    log "🎯 Installation completed! Happy coding! 🚀"
}

# Main installation process
main() {
    detect_os
    set_install_dir  
    check_dependencies
    install_jq
    install_repo_script
    update_path
    verify_installation
    show_success_message
}

# Handle script interruption gracefully
trap 'echo ""; error "Installation interrupted by user"; exit 1' INT TERM

# Run the main installation
main "$@"
