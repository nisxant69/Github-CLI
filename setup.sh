#!/bin/bash

# Ensure we're running with bash
if [ -z "$BASH_VERSION" ]; then
    echo "❌ Error: This script requires bash"
    exit 1
fi

# --- Step 0: Setup variables and directories ---
NETRC_FILE="${HOME:-$(getent passwd $(id -u) | cut -d: -f6)}/.netrc"
REPO_CLI_CONFIG="$HOME/.repo-cli"
DEFAULT_INSTALL_DIR="/usr/local/bin"
FALLBACK_INSTALL_DIR="$HOME/bin"

# Ensure HOME directory exists and is writable
if [ ! -w "$HOME" ]; then
    echo "❌ Error: Home directory is not writable"
    exit 1
fi

# --- Step 1: Check for sudo or determine alternative install location ---
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
if ! command -v sudo >/dev/null || ! sudo -n true 2>/dev/null; then
    echo "⚠️ sudo not available or requires password, using local installation"
    INSTALL_DIR="$FALLBACK_INSTALL_DIR"
    mkdir -p "$FALLBACK_INSTALL_DIR"
fi

echo "🚀 Starting 'repo' CLI setup..."

# --- Step 2: Check and Install Dependencies ---
echo "📦 Checking dependencies..."

# Function to check if a dependency needs to be installed
check_dependency() {
    local dep="$1"
    if command -v "$dep" >/dev/null 2>&1; then
        echo "✅ $dep is already installed"
        return 1  # Return 1 means don't need to install
    else
        echo "❌ $dep is not installed"
        return 0  # Return 0 means need to install
    fi
}

# Function to check version requirements
check_version() {
    case "$1" in
        "curl")
            if ! curl --version | grep -q "^curl [7-9]"; then
                echo "⚠️ Warning: curl version 7.0.0 or higher is recommended"
            fi
            ;;
        "jq")
            if ! jq --version | grep -q "^jq-[1-9]"; then
                echo "⚠️ Warning: jq version 1.0 or higher is recommended"
            fi
            ;;
    esac
}

# Check which dependencies need to be installed
DEPS_TO_INSTALL=()
for dep in git curl jq; do
    if check_dependency "$dep"; then
        DEPS_TO_INSTALL+=("$dep")
    else
        check_version "$dep"
    fi
done

# Install missing dependencies if any
if [ ${#DEPS_TO_INSTALL[@]} -gt 0 ]; then
    echo "🔧 Installing missing dependencies: ${DEPS_TO_INSTALL[*]}"
    
    install_with_apt() {
        sudo apt update && sudo apt install -y "$@"
    }

    install_with_dnf() {
        sudo dnf install -y "$@"
    }

    install_with_pacman() {
        sudo pacman -Sy --noconfirm "$@"
    }

    install_with_brew() {
        brew install "$@"
    }

    if command -v apt &>/dev/null; then
        if ! install_with_apt "${DEPS_TO_INSTALL[@]}"; then
            echo "❌ Failed to install dependencies using apt"
            exit 1
        fi
    elif command -v dnf &>/dev/null; then
        if ! install_with_dnf "${DEPS_TO_INSTALL[@]}"; then
            echo "❌ Failed to install dependencies using dnf"
            exit 1
        fi
    elif command -v pacman &>/dev/null; then
        if ! install_with_pacman "${DEPS_TO_INSTALL[@]}"; then
            echo "❌ Failed to install dependencies using pacman"
            exit 1
        fi
    elif command -v brew &>/dev/null; then
        if ! install_with_brew "${DEPS_TO_INSTALL[@]}"; then
            echo "❌ Failed to install dependencies using brew"
            exit 1
        fi
    else
        echo "❌ No supported package manager found and some dependencies are missing"
        echo "Please install the following manually: ${DEPS_TO_INSTALL[*]}"
        exit 1
    fi
else
    echo "✅ All dependencies are already installed"
fi

# --- Step 3: Download and install the CLI tool ---
echo "📥 Downloading 'repo' CLI script..."

if [ "$INSTALL_DIR" = "$DEFAULT_INSTALL_DIR" ]; then
    sudo curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/repo -o "$INSTALL_DIR/repo"
    sudo chmod +x "$INSTALL_DIR/repo"
else
    curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/repo -o "$INSTALL_DIR/repo"
    chmod +x "$INSTALL_DIR/repo"
fi

if [ ! -f "$INSTALL_DIR/repo" ]; then
    echo "❌ Failed to download 'repo' script"
    exit 1
fi

# Add to PATH if necessary
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
    echo "⚠️ Added $INSTALL_DIR to PATH in .bashrc - please restart your shell"
fi

# --- Step 4: GitHub Authentication Setup ---
echo -e "\n🔐 GitHub Authentication Setup"

get_github_credentials() {
    local prompt_user=true
    local prompt_token=true

    # Check if credentials already exist and are valid
    if [ -f "$NETRC_FILE" ] && [ -f "$REPO_CLI_CONFIG" ]; then
        echo "🔍 Found existing credentials, verifying..."
        if curl -s -f --netrc https://api.github.com/user >/dev/null; then
            echo "✅ Existing credentials are valid!"
            return 0
        else
            echo "⚠️ Existing credentials are invalid, need to update"
        fi
    fi

    while true; do
        if [ "$prompt_user" = true ]; then
            read -p "Enter your GitHub username: " gh_user
            if [ -z "$gh_user" ]; then
                echo "❌ Username cannot be empty. Please try again."
                continue
            fi
            prompt_user=false
        fi

        if [ "$prompt_token" = true ]; then
            echo -e "\n👉 Go to https://github.com/settings/tokens and generate a token with 'repo' scope"
            read -s -p "Enter your GitHub Personal Access Token (PAT): " gh_token
            echo
            if [ -z "$gh_token" ]; then
                echo "❌ Token cannot be empty. Please try again."
                continue
            fi
            prompt_token=false
        fi

        # Backup existing .netrc if it exists
        if [ -f "$NETRC_FILE" ]; then
            echo "📑 Backing up existing .netrc file..."
            cp "$NETRC_FILE" "${NETRC_FILE}.backup"
        fi

        # Create .netrc with proper permissions
        mkdir -p "$(dirname "$NETRC_FILE")"
        touch "$NETRC_FILE"
        chmod 600 "$NETRC_FILE"
        chmod 700 "$(dirname "$NETRC_FILE")"

        # Save credentials
        {
            echo "machine api.github.com"
            echo "login $gh_user"
            echo "password $gh_token"
        } > "$NETRC_FILE"

        # Save username for CLI use
        mkdir -p "$(dirname "$REPO_CLI_CONFIG")"
        echo "GITHUB_USER=$gh_user" > "$REPO_CLI_CONFIG"
        chmod 600 "$REPO_CLI_CONFIG"

        # Verify the token works
        echo "🔍 Verifying GitHub token..."
        if curl -s -f --netrc https://api.github.com/user >/dev/null; then
            echo "✅ GitHub authentication successful!"
            return 0
        else
            echo "❌ Failed to authenticate with GitHub. Please check your credentials and try again."
            echo "ℹ️  Make sure your token has the 'repo' scope enabled."
            read -p "Would you like to try again? [Y/n] " retry
            if [[ "$retry" =~ ^[Nn] ]]; then
                echo "❌ Setup cancelled. Please run the script again when you have valid GitHub credentials."
                exit 1
            fi
            prompt_user=true
            prompt_token=true
            echo
        fi
    done
}

# Get GitHub credentials
get_github_credentials

echo -e "\n✅ Setup complete!"
echo "🎉 You can now run: repo help"

# Remind about shell restart if PATH was modified
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "\n⚠️  Important: You need to restart your shell or run:"
    echo "    source ~/.bashrc"
    echo "to use the 'repo' command."
fi
