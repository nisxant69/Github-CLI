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

# --- Step 2: Install Dependencies ---
echo "📦 Installing dependencies..."

install_with_apt() {
    sudo apt update && sudo apt install -y git curl jq
}

install_with_dnf() {
    sudo dnf install -y git curl jq
}

install_with_pacman() {
    sudo pacman -Sy --noconfirm git curl jq
}

install_with_brew() {
    brew install git curl jq
}

# Try to install dependencies
if command -v apt &>/dev/null; then
    if ! install_with_apt; then
        echo "❌ Failed to install dependencies using apt"
        exit 1
    fi
elif command -v dnf &>/dev/null; then
    if ! install_with_dnf; then
        echo "❌ Failed to install dependencies using dnf"
        exit 1
    fi
elif command -v pacman &>/dev/null; then
    if ! install_with_pacman; then
        echo "❌ Failed to install dependencies using pacman"
        exit 1
    fi
elif command -v brew &>/dev/null; then
    if ! install_with_brew; then
        echo "❌ Failed to install dependencies using brew"
        exit 1
    fi
else
    echo "⚠️ No supported package manager found"
    echo "👉 Please ensure git, curl, and jq are installed manually"
    
    # Check if dependencies are already installed
    for dep in git curl jq; do
        if ! command -v $dep >/dev/null 2>&1; then
            echo "❌ Required dependency '$dep' is not installed"
            exit 1
        fi
    done
fi

# Verify minimum versions
if ! curl --version | grep -q "^curl [7-9]"; then
    echo "⚠️ Warning: curl version 7.0.0 or higher is recommended"
fi

if ! jq --version | grep -q "^jq-[1-9]"; then
    echo "⚠️ Warning: jq version 1.0 or higher is recommended"
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
read -p "Enter your GitHub username: " gh_user

echo -e "\n👉 Go to https://github.com/settings/tokens and generate a token with 'repo' scope"
read -s -p "Enter your GitHub Personal Access Token (PAT): " gh_token
echo ""

# Backup existing .netrc if it exists
if [ -f "$NETRC_FILE" ]; then
    echo "📑 Backing up existing .netrc file..."
    cp "$NETRC_FILE" "${NETRC_FILE}.backup"
fi

# Create .netrc with proper permissions
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
if ! curl -s -f --netrc https://api.github.com/user >/dev/null; then
    echo "❌ Failed to authenticate with GitHub. Please check your token and try again"
    exit 1
fi

echo -e "\n✅ Setup complete!"
echo "🎉 You can now run: repo help"
