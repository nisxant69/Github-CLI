Got it! Here’s the entire detailed README in one single copy box for you — just copy all at once and save as README.md:

# 🚀 Repo CLI Tool

**Manage your GitHub repositories directly from the terminal — create, delete, clone, list, open, and push — all with one simple CLI!** ✨

---

## ✨ Features

- 🆕 Create public/private GitHub repositories with description, license, `.gitignore`, and topics  
- ❌ Delete repositories safely with confirmation prompt  
- 📥 Clone any GitHub repository, optionally removing the `.git` folder for a clean start  
- 📋 List all your GitHub repositories with URLs  
- 🌐 Open repository page in your default browser  
- 📤 Push local commits to remote `main` branch  
- ⚙️ Automated setup — zero hassle!

---

## 🛠️ Requirements

- macOS or Linux  
- `bash` shell  
- `git`, `curl`, and `jq` (auto-installed by setup script if missing)  
- GitHub Personal Access Token (PAT) with **`repo`** scope 🔐  

---

## 🚀 Installation

Run this single command in your terminal to install everything automatically:

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/yourusername/repo-cli@main/setup.sh | sudo bash

This will:

📦 Install dependencies if missing (git, curl, jq)

📥 Download and install the repo CLI script globally at /usr/local/bin/repo

🔐 Prompt you for GitHub username & PAT, saving credentials securely in /root/.netrc (or your home directory for non-root installs)



---

🔑 Setting Up Your GitHub Personal Access Token (PAT)

1. Visit GitHub Token Settings


2. Click Generate new token (classic)


3. Select the repo scope (for full control of private repositories)


4. Generate the token and copy it immediately


5. You will be prompted to enter this token during installation




---

💡 Usage

Type the following command to get help and see available commands:

repo help


---

Common Commands

# Create a new GitHub repository (public by default)
repo -create MyRepo

# Create a private repository with description, gitignore, license, topics, push initial commit, and custom directory
repo -create MyRepo -p --desc "My private repo" --gitignore Node --license mit --topics cli,tool -d ~/projects -push

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


---

🔒 Security Notes

Credentials are stored securely in your ~/.netrc file with strict 600 permissions

Your Personal Access Token must have repo scope to enable repo creation, deletion, and pushing

Never share your Personal Access Token publicly to avoid unauthorized access



---

🐞 Troubleshooting

If dependencies (git, curl, jq) are missing, run the setup script again

Authentication errors? Re-run the setup script and carefully re-enter your GitHub username and PAT

For API issues, check GitHub rate limits and network connectivity

Make sure your token has the necessary permissions (repo scope)



---

🤝 Contribution & Support

Contributions, bug reports, and feature requests are very welcome!
Please open issues or pull requests at the GitHub repository.


---

📄 License

This project is licensed under the MIT License © Your Name


---

Ready to get started? Run this one-liner in your terminal:

curl -fsSL https://cdn.jsdelivr.net/gh/yourusername/repo-cli@main/setup.sh | sudo bash

Then use the repo command anywhere in your terminal!


---

Happy coding! 🎉

Just select all the text above and copy it — everything is inside one code block for your convenience!

