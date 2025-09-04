# ~/.zshrc
# A clean Zsh configuration using Starship and manually loaded plugins.

# --- Zsh Plugin Loading ---
# Safely loads plugins from a custom directory.

# Load zsh-autosuggestions
if [ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Load zsh-syntax-highlighting
if [ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi


# --- Environment Variables & PATH ---

# Load user-specific environment variables
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

# 1Password SSH Agent
export SSH_AUTH_SOCK=$HOME/.1password/agent.sock

# Bun configuration
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Go Development
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin


# --- User Configuration ---

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi


# --- Aliases & Functions ---

# --- Aliases for Arch Linux ---

# Update official repository and AUR packages
alias update="yay"

# Full system upgrade (Official repos, AUR, and Flatpak)
alias sysup="yay && flatpak update"

# Clean all package caches (a useful addition)
alias cleanall="yay -Scc"

# A smarter function to remove orphaned packages.
cleanup() {
    # Get a list of orphaned packages.
    orphans=$(pacman -Qtdq)

    if [ -z "$orphans" ]; then
        # If the list is empty, print a friendly message.
        echo "✨ No orphaned packages to clean up. Your system is tidy!"
    else
        # If orphans were found, print them and then remove them.
        echo "Found the following orphaned packages:"
        echo "$orphans"
        echo "-------------------------------------"
        # The 'xargs' command helps pipe the list of packages correctly to pacman
        echo "$orphans" | xargs sudo pacman -Rns
    fi
}


# --- Development Aliases ---

# Node.js / JavaScript
alias ni="npm install"
alias nid="npm install --save-dev"
alias nig="npm install -g"
alias nrs="npm run start"
alias nrd="npm run dev"
alias nrb="npm run build"
alias nrt="npm run test"
alias nls="npm list"
alias nx="npx"

# Yarn
alias yi="yarn install"
alias ya="yarn add"
alias yad="yarn add --dev"
alias ys="yarn start"
alias yd="yarn dev"
alias yb="yarn build"
alias yt="yarn test"

# --- Python (with uv) ---
alias python="python3"
alias pip="uv pip"              # <-- Always use uv for pip commands
alias venv="uv venv"            # <-- Use uv to create virtual environments (faster)
alias act="source .venv/bin/activate" # <-- Activate .venv (uv's default)
alias deact="deactivate"
alias pipi="uv pip install"     # Now an explicit uv alias
alias pipr="uv pip install -r requirements.txt" # Now an explicit uv alias
alias pipf="uv pip freeze > requirements.txt"   # Now an explicit uv alias

# New aliases for uv project management
alias ua="uv add"
alias ur="uv run"
alias ul="uv lock"
alias us="uv sync"
alias ui="uv init"

# C/C++
alias gcc="gcc -Wall -Wextra -std=c11"
alias g++="g++ -Wall -Wextra -std=c++17"
alias make="make -j$(nproc)"

# Docker
alias d="docker"
alias dc="docker-compose"
alias dps="docker ps"
alias dpsa="docker ps -a"
alias di="docker images"
alias dex="docker exec -it"
alias dlog="docker logs"
alias dstop="docker stop"
alias drm="docker rm"
alias drmi="docker rmi"
alias dprune="docker system prune -f"
alias dcup="docker-compose up"
alias dcdown="docker-compose down"
alias dcbuild="docker-compose build"

# Go
alias gob="go build"
alias gor="go run"
alias got="go test"
alias gom="go mod"
alias gomi="go mod init"
alias gomt="go mod tidy"
alias gof="go fmt"
alias gov="go version"

# Rust
alias cb="cargo build"
alias cr="cargo run"
alias ct="cargo test"
alias cc="cargo check"
alias cf="cargo fmt"
alias ccl="cargo clippy"
alias cn="cargo new"
alias ci="cargo init"
alias cu="cargo update"

# Git shortcuts
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gm="git merge"
alias gr="git rebase"
alias glog="git log --oneline --graph --decorate"

# Update dotfiles and reload zsh config
update-zsh() {
    # Find the git repository containing the actual .zshrc file
    local zshrc_path="$HOME/.zshrc"
    local dotfiles_repo
    
    # If .zshrc is a symlink, follow it to find the actual file
    if [ -L "$zshrc_path" ]; then
        zshrc_path=$(readlink -f "$zshrc_path")
    fi
    
    # Get the directory containing the .zshrc file and find the git repo
    dotfiles_repo=$(cd "$(dirname "$zshrc_path")" && git rev-parse --show-toplevel 2>/dev/null)
    
    if [ -z "$dotfiles_repo" ]; then
        echo "❌ Could not find dotfiles git repository!"
        echo "💡 Make sure your .zshrc is in a git repository or is symlinked to one."
        return 1
    fi
    
    echo "📂 Found dotfiles repo at: $dotfiles_repo"
    
    (cd "$dotfiles_repo" && 
     git fetch && 
     if [ $(git rev-parse HEAD 2>/dev/null) != $(git rev-parse @{u} 2>/dev/null) ]; then 
         git pull && 
         source ~/.zshrc && 
         echo "✨ Dotfiles updated and zsh config reloaded!"
     else 
         echo "📦 Dotfiles are already up-to-date!"
     fi
    )
}

# General utilities
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias h='history'
alias c='clear'
alias x='exit'
alias reload='source ~/.zshrc'

# Load a local, machine-specific configuration file if it exists
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi

# --- Shell Integrations ---

# Homebrew
if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Starship Prompt (must be the last line)
eval "$(starship init zsh)"