# zsh reference

Source of truth: [`shell/.zshrc`](../../shell/.zshrc). Installed as `~/.zshrc`.

## Environment variables and PATH

| Variable | Value | Purpose |
|----------|-------|---------|
| `BUN_INSTALL` | `$HOME/.bun` | Bun install root; `$BUN_INSTALL/bin` is prepended to `PATH` |
| `PNPM_HOME` | `$HOME/Library/pnpm` | pnpm global bin dir; prepended to `PATH` |
| `NVM_DIR` | `$HOME/.nvm` | nvm data dir |
| `HISTFILE` | `~/.zsh_history` | History file |
| `HISTSIZE` / `SAVEHIST` | `100000` | History size in memory / on disk |
| `FZF_DEFAULT_COMMAND` | `fd --type f --hidden --exclude .git` | Only set when `fd` is installed |
| `FZF_CTRL_T_COMMAND` | same as `FZF_DEFAULT_COMMAND` | Only set when `fd` is installed |
| `FZF_ALT_C_COMMAND` | `fd --type d --hidden --exclude .git` | Only set when `fd` is installed |
| `ZSH_AUTOSUGGEST_STRATEGY` | `(history completion)` | Autosuggestion sources |

`shell/.zshrc` prepends `$HOME/.local/bin`, `$BUN_INSTALL/bin`, and `$PNPM_HOME` to `PATH` in that order. It declares `path` and `fpath` with `typeset -U`, which removes duplicates on reload. It expects Homebrew's `shellenv` command in `~/.zprofile` and does not run it here.

It adds `$HOME/.zsh/completions`, `$HOME/.docker/completions`, `/opt/homebrew/share/zsh-completions`, and `/opt/homebrew/share/zsh/site-functions` to `fpath`.

## Shell options

| Option | Effect |
|--------|--------|
| `SHARE_HISTORY` | Share history across open terminals |
| `INC_APPEND_HISTORY` | Write history immediately, not on exit |
| `EXTENDED_HISTORY` | Store timestamps |
| `HIST_IGNORE_ALL_DUPS` | Drop older duplicates |
| `HIST_IGNORE_SPACE` | Commands starting with a space are not recorded |
| `HIST_REDUCE_BLANKS` | Trim superfluous blanks |
| `HIST_VERIFY` | Show expanded `!!` before running |
| `AUTO_CD` | `dir` behaves like `cd dir` |
| `AUTO_PUSHD`, `PUSHD_IGNORE_DUPS`, `PUSHD_SILENT` | `cd` pushes onto the directory stack silently |
| `CORRECT` | Suggest corrections for mistyped commands |
| `INTERACTIVE_COMMENTS` | Allow `#` comments on the command line |
| `NO_BEEP` | Disable the bell |

## Completion

`compinit` performs its security check at most once every 24 hours, based on the age of `~/.zcompdump`. During other shell starts, `compinit -C` skips that check. Completion uses menu selection, case-insensitive and partial-word matching, `LS_COLORS` in listings, grouped results with yellow headings, and a cache in `~/.zsh/cache`.

## Keybindings

The configuration enables Emacs mode with `bindkey -e` and defines these keybindings:

| Key | Action |
|-----|--------|
| ↑ / ↓ | History search by typed prefix |
| ⌥→ / ⌥← | Forward / backward word |
| Home / End | Beginning / end of line |
| Fn+Delete | Delete character under cursor |
| Ctrl-R, Ctrl-T, Alt-C | fzf history, file and directory pickers (when `fzf` is installed) |

## Aliases

### Homebrew

| Alias | Command |
|-------|---------|
| `update` | `brew update && brew upgrade` |
| `sysup` | `brew update && brew upgrade && brew cleanup --prune=all` |
| `clean` | `brew cleanup --prune=all` |

### Git

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gd` | `git diff` |
| `gb` | `git branch` |
| `gco` | `git checkout` |
| `gcb` | `git switch -c` |
| `gsw` | `git switch` |
| `gm` | `git merge` |
| `gr` | `git rebase` |
| `glog` | `git log --oneline --graph --decorate` |

### Listing files

With `eza` installed:

| Alias | Command |
|-------|---------|
| `ls` | `eza --group-directories-first` |
| `ll` | `eza -la --group-directories-first --git` |
| `la` | `eza -a --group-directories-first` |
| `l` | `eza -l --group-directories-first` |
| `lt` | `eza --tree --level=2 --group-directories-first` |

Without `eza`:

| Alias | Command |
|-------|---------|
| `ls` | `ls -G` |
| `ll` | `ls -alFG` |
| `la` | `ls -A` |
| `l` | `ls -CF` |

### General

| Alias | Command | Note |
|-------|---------|------|
| `cat` | `bat --paging=never --style=plain` | Only when `bat` is installed |
| `..`, `...`, `....` | `cd ..`, `cd ../..`, `cd ../../..` | |
| `grep` | `grep --color=auto` | |
| `h` | `history` | |
| `c` | `clear` | |
| `x` | `exit` | |
| `reload` | `exec zsh` | |
| `path` | `print -l $path` | One `PATH` entry per line |
| `py` | `uv run python` | `python` itself is deliberately not aliased |

## Optional tools

Missing tools do not prevent shell startup. `.zshrc` checks before it runs tool setup code or replaces a standard command. Aliases such as `py` still require the tool listed in the table when invoked.

| Tool | What it enables |
|------|-----------------|
| `starship` | Prompt (`starship init zsh`, run last). Config: `shell/starship.toml` → `~/.config/starship.toml` |
| `fzf` | Ctrl-R / Ctrl-T / Alt-C widgets via `fzf --zsh` |
| `zoxide` | `z <dir>` smart cd |
| `fd` | Sets the `FZF_*_COMMAND` variables above |
| `eza` | Replaces `ls` family aliases |
| `bat` | Replaces `cat` |
| `zsh-completions` | Extra completions via `/opt/homebrew/share/zsh-completions` |
| `nvm` | Lazy-loaded: `nvm`, `node`, `npm`, `npx` are shell functions that source `/opt/homebrew/opt/nvm/nvm.sh` on first call, then replace themselves |
| `uv` | Backs the `py` alias |

### Plugins

Near the end of the file, `.zshrc` sources these plugins from `~/.zsh/plugins/` when they exist. They wrap ZLE widgets, so they load after `compinit`, fzf, and zoxide:

1. `zsh-autosuggestions/zsh-autosuggestions.zsh`
2. `zsh-syntax-highlighting/zsh-syntax-highlighting.zsh`

## Local override

`.zshrc` sources `~/.zshrc.local` if the file exists. See [Machine-specific overrides](../guides/machine-specific-overrides.md).

## Starship configuration

`shell/starship.toml` overrides five module symbols so the prompt works without a Nerd Font: `azure`, `battery`, `erlang`, `nodejs` and `pulumi`. Everything else uses Starship's default.
