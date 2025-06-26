#!/bin/bash
set -e

echo "Starting 'repo' CLI setup..."

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo): sudo $0"
  exit 1
fi

install_dependencies() {
  echo "Installing dependencies..."
  if command -v apt-get &>/dev/null; then
    apt-get update
    apt-get install -y git curl jq
  elif command -v brew &>/dev/null; then
    brew install git curl jq
  else
    echo "Unsupported OS or package manager."
    echo "Please install git, curl, jq manually."
    exit 1
  fi
}

install_dependencies

# Determine script directory (assumes setup.sh & repo are together if cloned)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
REPO_SCRIPT="$SCRIPT_DIR/repo"

# If repo script does not exist in same dir, download it directly from GitHub CDN
if [ ! -f "$REPO_SCRIPT" ]; then
  echo "'repo' script not found locally, downloading latest version..."
  curl -fsSL "https://cdn.jsdelivr.net/gh/yourusername/repo-cli@main/repo" -o /usr/local/bin/repo
  chmod +x /usr/local/bin/repo
else
  echo "Installing 'repo' command to /usr/local/bin/repo ..."
  cp "$REPO_SCRIPT" /usr/local/bin/repo
  chmod +x /usr/local/bin/repo
fi

NETRC_FILE="/root/.netrc"
if [ -f "$NETRC_FILE" ]; then
  echo "~/.netrc already exists for root, skipping."
else
  echo "Setting up GitHub credentials."
  read -rp "GitHub username: " GH_USER
  read -rsp "GitHub Personal Access Token (PAT): " GH_TOKEN
  echo
  cat >"$NETRC_FILE" <<EOF
machine api.github.com
login $GH_USER
password $GH_TOKEN
EOF
  chmod 600 "$NETRC_FILE"
  echo "GitHub credentials saved securely."
fi

echo
echo "'repo' CLI installed successfully!"
echo "Run 'repo help' to get started."

exit 0
