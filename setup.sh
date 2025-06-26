#!/bin/bash

# --- Step 0: Ensure 'sudo' is available ---
if ! command -v sudo >/dev/null; then
  echo "❌ 'sudo' is required but not found. Please install sudo and try again."
  exit 1
fi

echo "Starting 'repo' CLI setup..."

# --- Step 1: Install Dependencies ---
echo "Installing dependencies..."

if command -v apt &>/dev/null; then
  sudo apt update && sudo apt install -y git curl jq
elif command -v dnf &>/dev/null; then
  sudo dnf install -y git curl jq
elif command -v pacman &>/dev/null; then
  sudo pacman -Sy --noconfirm git curl jq
elif command -v brew &>/dev/null; then
  brew install git curl jq
else
  echo "❌ Unsupported OS or package manager."
  echo "👉 Please install git, curl, and jq manually."
  exit 1
fi

# --- Step 2: Download and install the CLI tool ---
echo "📥 Downloading 'repo' CLI script..."
sudo curl -fsSL https://raw.githubusercontent.com/nisxant69/Github-CLI/main/repo -o /usr/local/bin/repo

if [ ! -f /usr/local/bin/repo ]; then
  echo "❌ Failed to download 'repo' script."
  exit 1
fi

sudo chmod +x /usr/local/bin/repo

# --- Step 3: Prompt for GitHub credentials and save securely ---
echo ""
echo "🔐 GitHub Authentication Setup"
read -p "Enter your GitHub username: " gh_user

echo ""
echo "👉 Go to https://github.com/settings/tokens and generate a token with 'repo' scope"
read -s -p "Enter your GitHub Personal Access Token (PAT): " gh_token
echo ""

# Save to ~/.netrc with 'api.github.com'
NETRC_FILE="$HOME/.netrc"
{
  echo "machine api.github.com"
  echo "login $gh_user"
  echo "password $gh_token"
} > "$NETRC_FILE"

chmod 600 "$NETRC_FILE"

# Save username for CLI use (optional)
echo "GITHUB_USER=$gh_user" > "$HOME/.repo-cli"

echo ""
echo "✅ Setup complete!"
echo "You can now run: repo help"
