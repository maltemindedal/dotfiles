# ~/.zshrc
# A clean, macOS-optimized Zsh configuration using Starship and manual plugins.
# Homebrew shellenv lives in ~/.zprofile (login shell) — not repeated here.

# Deduplicate PATH/FPATH automatically (safe to `reload` repeatedly)
typeset -U path PATH fpath FPATH

# --- Environment Variables & PATH ---
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/Library/pnpm"
path=("$HOME/.local/bin" "$BUN_INSTALL/bin" "$PNPM_HOME/bin" $path)

# SSH: use the macOS system ssh-agent (launchd sets SSH_AUTH_SOCK).
# Previously overridden to the 1Password agent; retired in favour of the
# on-disk key at ~/.ssh/id_ed25519_git (passphrase held in the login keychain).
# The agent starts empty after a reboot and commit signing needs the key in it, so load
# keychain-held keys now. Absolute path: Homebrew's ssh-add lacks --apple-load-keychain.
/usr/bin/ssh-add -l >/dev/null 2>&1 || /usr/bin/ssh-add --apple-load-keychain -q 2>/dev/null

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # share across open terminals; also writes immediately
setopt EXTENDED_HISTORY       # timestamps
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE      # leading space = don't record
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # show expanded !! before running

# --- Shell Options ---
setopt AUTO_CD                # `dir` == `cd dir`
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt CORRECT                # suggest corrections for mistyped commands
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# --- Completion ---
fpath=("$HOME/.zsh/completions" "$HOME/.docker/completions" /opt/homebrew/share/zsh-completions /opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit
# Full compinit (with its security check) at most once a day; otherwise trust the dump.
# The glob matches only a dump older than 24h. compinit leaves an up-to-date dump
# untouched, so touch it to restart the clock.
() {
  if (( $# )) || [[ ! -e ~/.zcompdump ]]; then
    compinit && touch ~/.zcompdump
  else
    compinit -C
  fi
} ~/.zcompdump(N.mh+24)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'   # case-insensitive + partial
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# --- Keybindings ---
bindkey -e                                   # emacs mode
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search   # ↑ prefix history search
bindkey '^[[B' down-line-or-beginning-search # ↓
bindkey '^[[1;3C' forward-word               # ⌥→
bindkey '^[[1;3D' backward-word              # ⌥←
bindkey '^[[H' beginning-of-line             # Home
bindkey '^[[F' end-of-line                   # End
bindkey '^[[3~' delete-char                  # Fn+Delete

# --- Aliases & Functions ---
# Aliases are for interactive shells only. Claude Code sources this file in a non-interactive
# shell and copies its aliases into the agent's shell, where eza rejects `ls -lt`, bat rejects
# `cat -e`, and `gs` would shadow Ghostscript.
if [[ -o interactive ]]; then
  # Homebrew maintenance
  alias update="brew update && brew upgrade"
  alias sysup="brew update && brew upgrade && brew cleanup --prune=all"
  alias clean="brew cleanup --prune=all"

  # Git shortcuts
  alias gs="git status"
  alias ga="git add"
  alias gc="git commit"
  alias gp="git push"
  alias gl="git pull"
  alias gd="git diff"
  alias gb="git branch"
  alias gco="git checkout"
  alias gcb="git switch -c"
  alias gsw="git switch"
  alias gm="git merge"
  alias gr="git rebase"
  alias glog="git log --oneline --graph --decorate"

  # Modern replacements (eza / bat / fd / rg)
  if command -v eza >/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -la --group-directories-first --git'
    alias la='eza -a --group-directories-first'
    alias l='eza -l --group-directories-first'
    alias lt='eza --tree --level=2 --group-directories-first'
  else
    alias ls='ls -G'
    alias ll='ls -alFG'
    alias la='ls -A'
    alias l='ls -CF'
  fi
  command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'

  # General utilities
  alias ..='cd ..'
  alias ...='cd ../..'
  alias ....='cd ../../..'
  alias grep='grep --color=auto'
  alias h='history'
  alias c='clear'
  alias x='exit'
  alias reload='exec zsh'
  alias path='print -l $path'

  # uv / Python: `py` runs inside the project venv. (Global `python` is deliberately
  # NOT shadowed — scripts/tools that call `python` should get the real one.)
  alias py='uv run python'
fi

# --- NVM ---
# nvm's default Node goes on PATH directly, so node, npm, npx and global npm tools work in
# every shell and in scripts. Loading nvm itself costs ~0.5s, so the `nvm` function loads it
# on first use. That function is self-contained so it still works when copied on its own,
# such as into a Claude Code shell snapshot, and it unsets itself first so a failed load
# ends in "command not found" instead of recursing. It loads nvm's completion only in
# interactive shells: the snapshot copies `compdef` without its data, so it errors there.
export NVM_DIR="$HOME/.nvm"
() {
  # Follow the alias chain (default -> lts/* -> lts/krypton -> v24.21.0; capped in case of a
  # loop), then take the newest installed match, as nvm does for partial versions like "24".
  local v=default i
  for i in {1..10}; do [[ -r $NVM_DIR/alias/$v ]] && v=$(<$NVM_DIR/alias/$v) || break; done
  v=${v#v}
  local pat='*'
  [[ $v == (node|stable) ]] || pat="${(b)v}(|.*)"   # (b): alias text is literal, not a pattern
  local -a nodes=($NVM_DIR/versions/node/v${~pat}/bin/node(N-*nOn))
  (( $#nodes )) && path=(${nodes[1]:h} $path)
}
if [ -s /opt/homebrew/opt/nvm/nvm.sh ]; then
  nvm() {
    unset -f nvm
    \. /opt/homebrew/opt/nvm/nvm.sh --no-use   # the default is already on PATH
    [[ -o interactive && -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ]] && \. /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm
    nvm "$@"
  }
fi

# --- Tool Initializations ---
command -v fzf    >/dev/null && source <(fzf --zsh)          # Ctrl-R history, Ctrl-T files, Alt-C cd
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"    # `z <dir>` smart cd
if command -v fd >/dev/null; then
  # Note: fzf disables Ctrl-T/Alt-C if these are set to an empty string, so only set them when fd exists.
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi

# Plugin settings go before ~/.zshrc.local so the local file can override them.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Load a local, machine-specific configuration file if it exists
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# --- Zsh Plugins (keep near the end: they wrap ZLE widgets, so source after compinit, fzf and zoxide;
#     autosuggestions before syntax-highlighting) ---
[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship prompt (keep last). An if, not &&, so .zshrc returns 0 without starship.
if command -v starship >/dev/null; then eval "$(starship init zsh)"; fi
