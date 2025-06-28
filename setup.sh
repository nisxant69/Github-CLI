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

validate_token_permissions() {
    local token="$1"
    local response
    
    echo "🔍 Checking token permissions..."
    response=$(curl -s -H "Authorization: token $token" \
                   -H "Accept: application/vnd.github.v3+json" \
                   https://api.github.com/user)
    
    if ! echo "$response" | jq -e '.login' >/dev/null; then
        echo "❌ Invalid token or API error"
        return 1
    fi

    # Check token scopes
    local scopes
    scopes=$(curl -s -I -H "Authorization: token $token" \
                  -H "Accept: application/vnd.github.v3+json" \
                  https://api.github.com/user \
             | grep -i "^x-oauth-scopes:" | cut -d' ' -f2-)

    local required_scopes=("repo" "delete_repo")
    local missing_scopes=()
    
    for scope in "${required_scopes[@]}"; do
        if ! echo "$scopes" | grep -q "$scope"; then
            missing_scopes+=("$scope")
        fi
    done

    if [ ${#missing_scopes[@]} -gt 0 ]; then
        echo "❌ Token is missing required permissions: ${missing_scopes[*]}"
        echo "Please generate a new token with the following scopes:"
        echo "  - repo (Full control of private repositories)"
        echo "  - delete_repo (Delete repositories)"
        return 1
    fi

    echo "✅ Token has all required permissions"
    return 0
}

validate_github_user() {
    local username="$1"
    local token="$2"
    local response

    echo "🔍 Verifying GitHub account..."
    response=$(curl -s -H "Authorization: token $token" \
                   -H "Accept: application/vnd.github.v3+json" \
                   "https://api.github.com/users/$username")

    if ! echo "$response" | jq -e '.login' >/dev/null; then
        echo "❌ Invalid GitHub username"
        return 1
    fi

    # Verify the token belongs to this user
    local token_user
    token_user=$(curl -s -H "Authorization: token $token" \
                     -H "Accept: application/vnd.github.v3+json" \
                     https://api.github.com/user | jq -r '.login')

    if [ "$username" != "$token_user" ]; then
        echo "❌ Token does not belong to user $username"
        return 1
    fi

    echo "✅ GitHub account verified"
    return 0
}

get_github_credentials() {
    # For first time run, delete existing .netrc file
    if [ -f "$NETRC_FILE" ]; then
        echo "🗑️ Removing existing .netrc file for fresh setup..."
        rm -f "$NETRC_FILE"
        rm -f "${NETRC_FILE}.backup-"*
    fi

    while true; do
        # Get GitHub username/email
        gh_user=""
        while [ -z "$gh_user" ]; do
            read -r -p "Enter your GitHub username or email: " gh_user
            if [ -z "$gh_user" ]; then
                echo "❌ Username/email cannot be empty. Please try again."
                sleep 1
            fi
        done

        # Get GitHub token with instructions
        echo -e "\n📝 Generate a new Personal Access Token (PAT):"
        echo "1. Go to: https://github.com/settings/tokens/new"
        echo "2. Note: repo-cli-token"
        echo "3. Select scopes:"
        echo "   ☑️ repo (Full control of private repositories)"
        echo "   ☑️ delete_repo (Delete repositories)"
        echo "4. Click 'Generate token'"
        echo "5. Copy the token (it will only be shown once!)"

        gh_token=""
        while [ -z "$gh_token" ]; do
            read -r -s -p "Enter your GitHub Personal Access Token (PAT): " gh_token
            echo
            if [ -z "$gh_token" ]; then
                echo "❌ Token cannot be empty. Please try again."
                sleep 1
            fi
        done

        # Validate token permissions
        if ! validate_token_permissions "$gh_token"; then
            read -r -p "Would you like to try again with a new token? [Y/n] " retry
            if [[ "$retry" =~ ^[Nn] ]]; then
                echo "❌ Setup cancelled. Please run the script again with a properly configured token."
                exit 1
            fi
            continue
        fi

        # Validate GitHub user
        if ! validate_github_user "$gh_user" "$gh_token"; then
            read -r -p "Would you like to try again? [Y/n] " retry
            if [[ "$retry" =~ ^[Nn] ]]; then
                echo "❌ Setup cancelled. Please run the script again with correct credentials."
                exit 1
            fi
            continue
        fi

        # Create .netrc with proper permissions
        mkdir -p "$(dirname "$NETRC_FILE")"
        touch "$NETRC_FILE"
        chmod 600 "$NETRC_FILE"
        chmod 700 "$(dirname "$NETRC_FILE")"

        # Save credentials in the proper format
        {
            echo "machine api.github.com"
            echo "login $gh_user"
            echo "password $gh_token"
        } > "$NETRC_FILE"

        # Save username for CLI use
        mkdir -p "$(dirname "$REPO_CLI_CONFIG")"
        echo "GITHUB_USER=$gh_user" > "$REPO_CLI_CONFIG"
        chmod 600 "$REPO_CLI_CONFIG"

        echo "✅ Credentials saved successfully!"
        return 0
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
