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


# --- Aliases ---

# --- Aliases for Arch Linux ---

# System Update
alias update="sudo pacman -Syu"
alias flatup="flatpak update"
alias sysup="sudo pacman -Syu && flatpak update"
alias cleanup="sudo pacman -Rns \$(pacman -Qtdq)"

# Development Aliases
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

# Python
alias python="python3"
alias pip="pip3"
alias venv="python3 -m venv"
alias act="source venv/bin/activate"
alias deact="deactivate"
alias pipi="pip install"
alias pipr="pip install -r requirements.txt"
alias pipf="pip freeze > requirements.txt"

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

# SSH Aliaes
alias ssh='ssh.exe'
alias ssh-add='ssh-add.exe'

# --- Shell Integrations ---

# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Starship Prompt (must be the last line)
eval "$(starship init zsh)"%                                                                                            