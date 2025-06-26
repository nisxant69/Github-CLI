#!/bin/bash

# --- Step 0: Prevent running as root ---
if [ "$EUID" -eq 0 ]; then
  echo "⚠️  Please run this script as a normal user, not with sudo."
  echo "👉 Run it like this:"
  echo "    curl -fsSL https://cdn.jsdelivr.net/gh/nisxant69/Github-CLI@main/setup.sh | bash"
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
sudo curl -fsSL https://cdn.jsdelivr.net/gh/nisxant69/Github-CLI@main/repo -o /usr/local/bin/repo

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

# Save to ~/.netrc
NETRC_FILE="$HOME/.netrc"
{
  echo "machine github.com"
  echo "login $gh_user"
  echo "password $gh_token"
} > "$NETRC_FILE"

chmod 600 "$NETRC_FILE"

# Save username for CLI use (optional)
echo "GITHUB_USER=$gh_user" > "$HOME/.repo-cli"

echo ""
echo "✅ Setup complete!"
echo "Try: repo help"
