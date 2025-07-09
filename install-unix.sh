#!/bin/bash
# GitHub CLI Tool - Mac/Linux Universal Installer (Security Enhanced)
# Usage: Download and run locally for security
# curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-unix.sh -o install-unix.sh && bash install-unix.sh

set -euo pipefail

# Colors for beautiful output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Global configuration
readonly GITHUB_REPO="nisxant69/Github-CLI"
readonly REPO_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
readonly BIN_NAME="repo"
readonly SCRIPT_NAME="$(basename "$0")"
readonly TEMP_DIR="$(mktemp -d)"

# Global state variables
INSTALL_DIR=""
USE_SUDO=false
OS=""
DISTRO=""
PROFILE_UPDATED=false

# Cleanup function
cleanup() {
    local exit_code=$?
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    if [[ $exit_code -ne 0 ]]; then
        error "Installation failed. Cleaned up temporary files."
        if [[ -n "$INSTALL_DIR" && -f "$INSTALL_DIR/$BIN_NAME" ]]; then
            warn "Partial installation detected. You may want to remove: $INSTALL_DIR/$BIN_NAME"
        fi
    fi
}

# Set up cleanup trap
trap cleanup EXIT
trap 'echo ""; error "Installation interrupted by user"; exit 130' INT TERM

# Logging functions with emojis
log() { echo -e "${GREEN}✅${NC} $1" >&2; }
warn() { echo -e "${YELLOW}⚠️${NC} $1" >&2; }
error() { echo -e "${RED}❌${NC} $1" >&2; }
info() { echo -e "${BLUE}ℹ️${NC} $1" >&2; }
header() { echo -e "${CYAN}$1${NC}" >&2; }

# Utility functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_root() {
    [[ "$EUID" -eq 0 ]]
}

can_sudo() {
    command_exists sudo && sudo -n true 2>/dev/null
}

# Detect operating system with better logic
detect_os() {
    info "🔍 Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]]; then
            OS="wsl"
            DISTRO="WSL: ${WSL_DISTRO_NAME:-Unknown}"
            info "🪟 Windows Subsystem for Linux detected: ${WSL_DISTRO_NAME:-Unknown}"
        else
            OS="linux"
            if [[ -f /etc/os-release ]]; then
                # shellcheck source=/dev/null
                source /etc/os-release
                DISTRO="${PRETTY_NAME:-${NAME:-Unknown Linux}}"
            else
                DISTRO="Unknown Linux"
            fi
            info "🐧 Linux detected: $DISTRO"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        local version
        version=$(sw_vers -productVersion 2>/dev/null || echo 'Unknown')
        DISTRO="macOS $version"
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

# Determine installation directory with better logic
set_install_dir() {
    info "📁 Determining installation directory..."
    
    # Check for global installation capability
    if is_root || can_sudo; then
        case "$OS" in
            "macos")
                # Check for Homebrew and determine correct path
                if command_exists brew; then
                    local brew_prefix
                    brew_prefix=$(brew --prefix 2>/dev/null || echo "/usr/local")
                    INSTALL_DIR="$brew_prefix/bin"
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
        
        # Create directory if it doesn't exist
        if ! mkdir -p "$INSTALL_DIR"; then
            error "Failed to create installation directory: $INSTALL_DIR"
            exit 1
        fi
    fi
    
    info "📁 Installation directory: $INSTALL_DIR"
    if [[ "$USE_SUDO" == true ]]; then
        info "🔒 Using sudo for global installation"
    else
        info "👤 Installing for current user only"
    fi
}

# Check dependencies with better error handling
check_dependencies() {
    info "🔍 Checking required dependencies..."
    
    local deps=("curl" "git" "bash")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -ne 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        echo "" >&2
        echo "Please install them first:" >&2
        case "$OS" in
            "linux"|"wsl")
                echo "  • Ubuntu/Debian: sudo apt update && sudo apt install -y ${missing[*]}" >&2
                echo "  • RHEL/Fedora:   sudo dnf install -y ${missing[*]}" >&2
                echo "  • Arch Linux:    sudo pacman -S --noconfirm ${missing[*]}" >&2
                echo "  • Alpine:        sudo apk add ${missing[*]}" >&2
                ;;
            "macos")
                echo "  • Using Homebrew: brew install ${missing[*]}" >&2
                echo "  • Or install Xcode Command Line Tools: xcode-select --install" >&2
                ;;
            *)
                echo "  • Please install using your system's package manager" >&2
                ;;
        esac
        exit 1
    fi
    
    log "All required dependencies are available"
}

# Install jq with better error handling
install_jq() {
    if command_exists jq; then
        log "jq is already installed"
        return 0
    fi
    
    info "📦 Installing jq (recommended for enhanced functionality)..."
    
    local install_cmd=""
    case "$OS" in
        "linux"|"wsl")
            if command_exists apt && [[ "$USE_SUDO" == true ]]; then
                install_cmd="sudo apt update -qq && sudo apt install -y jq"
            elif command_exists dnf && [[ "$USE_SUDO" == true ]]; then
                install_cmd="sudo dnf install -y jq"
            elif command_exists pacman && [[ "$USE_SUDO" == true ]]; then
                install_cmd="sudo pacman -S --noconfirm jq"
            elif command_exists apk && [[ "$USE_SUDO" == true ]]; then
                install_cmd="sudo apk add jq"
            fi
            ;;
        "macos")
            if command_exists brew; then
                install_cmd="brew install jq"
            fi
            ;;
    esac
    
    if [[ -n "$install_cmd" ]]; then
        if eval "$install_cmd" >/dev/null 2>&1; then
            log "jq installed successfully"
        else
            warn "jq installation failed, but repo tool will still work"
        fi
    else
        warn "Cannot auto-install jq on this system. Install manually if needed."
    fi
}

# Verify downloaded file integrity
verify_file() {
    local file="$1"
    local expected_type="$2"
    
    if [[ ! -s "$file" ]]; then
        error "Downloaded file is empty or corrupted"
        return 1
    fi
    
    case "$expected_type" in
        "bash")
            if ! head -n1 "$file" | grep -q "#!/bin/bash"; then
                error "Downloaded file is not a valid bash script"
                error "File header: $(head -n1 "$file")"
                return 1
            fi
            ;;
        *)
            error "Unknown file type for verification: $expected_type"
            return 1
            ;;
    esac
    
    return 0
}

# Download file with better error handling
download_file() {
    local url="$1"
    local output="$2"
    
    info "📥 Downloading from: $url"
    
    # Use curl with proper error handling and progress
    local curl_opts=(-fsSL --connect-timeout 10 --max-time 300)
    
    # Add progress bar for interactive terminals
    if [[ -t 1 ]] && curl --help 2>/dev/null | grep -q "\-\-progress-bar"; then
        curl_opts+=(--progress-bar)
    fi
    
    if ! curl "${curl_opts[@]}" "$url" -o "$output"; then
        error "Failed to download from: $url"
        error "Please check your internet connection and try again"
        return 1
    fi
    
    return 0
}

# Install the main repo script with verification
install_repo_script() {
    local temp_file="$TEMP_DIR/repo_script"
    
    info "📥 Downloading GitHub CLI repo script..."
    
    if ! download_file "${REPO_URL}/repo" "$temp_file"; then
        exit 1
    fi
    
    # Verify the downloaded file
    if ! verify_file "$temp_file" "bash"; then
        exit 1
    fi
    
    info "🔧 Installing repo script..."
    
    # Install the script with appropriate permissions
    if [[ "$USE_SUDO" == true ]]; then
        if ! sudo cp "$temp_file" "$INSTALL_DIR/$BIN_NAME"; then
            error "Failed to copy script to $INSTALL_DIR"
            exit 1
        fi
        if ! sudo chmod +x "$INSTALL_DIR/$BIN_NAME"; then
            error "Failed to make script executable"
            exit 1
        fi
        # Set ownership (ignore errors for systems without root:root)
        sudo chown root:root "$INSTALL_DIR/$BIN_NAME" 2>/dev/null || true
    else
        if ! cp "$temp_file" "$INSTALL_DIR/$BIN_NAME"; then
            error "Failed to copy script to $INSTALL_DIR"
            exit 1
        fi
        if ! chmod +x "$INSTALL_DIR/$BIN_NAME"; then
            error "Failed to make script executable"
            exit 1
        fi
    fi
    
    log "GitHub CLI installed to $INSTALL_DIR/$BIN_NAME"
}

# Detect current shell
detect_shell() {
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        echo "zsh"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        echo "bash"
    else
        # Fallback to checking $SHELL
        basename "${SHELL:-bash}"
    fi
}

# Update PATH with better shell detection
update_path() {
    # Check if install directory is already in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        log "Installation directory is already in PATH"
        return 0
    fi
    
    info "🔧 Adding $INSTALL_DIR to PATH..."
    
    local shell_type
    shell_type=$(detect_shell)
    local profile_files=()
    
    # Determine which profile files to update based on OS and shell
    case "$OS" in
        "linux"|"wsl")
            case "$shell_type" in
                "zsh")
                    [[ -f "$HOME/.zshrc" ]] && profile_files+=("$HOME/.zshrc")
                    ;;
                "bash")
                    [[ -f "$HOME/.bashrc" ]] && profile_files+=("$HOME/.bashrc")
                    ;;
            esac
            # Always try .profile as fallback
            [[ -f "$HOME/.profile" ]] && profile_files+=("$HOME/.profile")
            ;;
        "macos")
            case "$shell_type" in
                "zsh")
                    [[ -f "$HOME/.zshrc" ]] && profile_files+=("$HOME/.zshrc")
                    ;;
                "bash")
                    [[ -f "$HOME/.bash_profile" ]] && profile_files+=("$HOME/.bash_profile")
                    [[ -f "$HOME/.bashrc" ]] && profile_files+=("$HOME/.bashrc")
                    ;;
            esac
            ;;
        "windows")
            [[ -f "$HOME/.bashrc" ]] && profile_files+=("$HOME/.bashrc")
            ;;
    esac
    
    # Update the first available profile file
    local path_line="export PATH=\"\$PATH:$INSTALL_DIR\""
    for profile in "${profile_files[@]}"; do
        # Check if PATH is already in this file
        if ! grep -q "$INSTALL_DIR" "$profile" 2>/dev/null; then
            if echo "$path_line" >> "$profile"; then
                warn "Added to $(basename "$profile") - restart your shell or run: source $profile"
                PROFILE_UPDATED=true
                break
            fi
        fi
    done
    
    if [[ "$PROFILE_UPDATED" == false ]]; then
        warn "Could not automatically update PATH. Please add this line to your shell profile:"
        echo "  $path_line" >&2
        echo "" >&2
        echo "Or run the tool directly with: $INSTALL_DIR/$BIN_NAME" >&2
    fi
}

# Verify installation with better checks
verify_installation() {
    info "✅ Verifying installation..."
    
    if [[ ! -f "$INSTALL_DIR/$BIN_NAME" ]]; then
        error "Installation failed - script not found at $INSTALL_DIR/$BIN_NAME"
        exit 1
    fi
    
    if [[ ! -x "$INSTALL_DIR/$BIN_NAME" ]]; then
        error "Installation failed - script is not executable at $INSTALL_DIR/$BIN_NAME"
        exit 1
    fi
    
    # Test basic script functionality
    if ! "$INSTALL_DIR/$BIN_NAME" --help >/dev/null 2>&1; then
        # Try alternative help command
        if ! "$INSTALL_DIR/$BIN_NAME" help >/dev/null 2>&1; then
            warn "Script installed but may have issues. Try running: $INSTALL_DIR/$BIN_NAME help"
        fi
    fi
    
    log "Installation verification successful!"
}

# Display comprehensive success message
show_success_message() {
    echo "" >&2
    header "🎉 GitHub CLI tool 'repo' installed successfully!"
    echo "" >&2
    echo -e "${WHITE}📖 Usage Examples:${NC}" >&2
    echo "  repo help              Show help and available commands" >&2
    echo "  repo create <name>     Create a new repository" >&2
    echo "  repo list              List your repositories" >&2
    echo "  repo clone <repo>      Clone a repository" >&2
    echo "  repo delete <repo>     Delete a repository" >&2
    echo "  repo open <repo>       Open repository in browser" >&2
    echo "" >&2
    echo -e "${WHITE}🔧 First Time Setup:${NC}" >&2
    echo "  1. Run 'repo help' to see all available commands" >&2
    echo "  2. Configure GitHub authentication when prompted" >&2
    echo "  3. Create a GitHub Personal Access Token if needed" >&2
    echo "" >&2
    echo -e "${WHITE}🚀 Quick Test:${NC}" >&2
    
    # Test if repo command is available
    if command_exists "$BIN_NAME"; then
        echo "  Command 'repo' is ready to use!" >&2
        echo "" >&2
        echo "  Running quick test..." >&2
        if "$BIN_NAME" --help >/dev/null 2>&1 || "$BIN_NAME" help >/dev/null 2>&1; then
            log "✨ Test successful! The tool is working perfectly."
        else
            warn "Tool installed but may need configuration. Run 'repo help' for more info."
        fi
    else
        if [[ "$PROFILE_UPDATED" == true ]]; then
            echo "  Restart your shell, then run: repo help" >&2
        else
            echo "  Add $INSTALL_DIR to your PATH, then run: repo help" >&2
        fi
        warn "Or run directly: $INSTALL_DIR/$BIN_NAME help"
    fi
    
    echo "" >&2
    echo -e "${WHITE}🔒 Security Note:${NC}" >&2
    echo "  The tool has been installed to: $INSTALL_DIR/$BIN_NAME" >&2
    echo "  You can inspect the script before use if needed." >&2
    echo "" >&2
    log "🎯 Installation completed! Happy coding! 🚀"
}

# Show usage information
show_usage() {
    echo "Usage: $SCRIPT_NAME [OPTIONS]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  -h, --help     Show this help message" >&2
    echo "  -v, --verbose  Enable verbose output" >&2
    echo "" >&2
    echo "For security, it's recommended to download and inspect this script before running:" >&2
    echo "  curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/install-unix.sh -o install-unix.sh" >&2
    echo "  # Inspect the script" >&2
    echo "  bash install-unix.sh" >&2
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main installation process
main() {
    # Display header
    clear
    echo "" >&2
    header "🚀 GitHub CLI Tool - Mac/Linux Installer (Security Enhanced)"
    header "============================================================"
    echo "" >&2
    
    # Parse command line arguments
    parse_args "$@"
    
    # Run installation steps
    detect_os
    set_install_dir
    check_dependencies
    install_jq
    install_repo_script
    update_path
    verify_installation
    show_success_message
    
    return 0
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi