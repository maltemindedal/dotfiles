# Machine-specific overrides

Goal: add settings that apply to one machine only (secrets, absolute paths, work-specific aliases) without modifying tracked files.

Both config files in this repository load an optional local file that is not tracked in git.

## zsh: `~/.zshrc.local`

`shell/.zshrc` sources `~/.zshrc.local` if it exists. It is sourced after the aliases, nvm, fzf and zoxide setup but **before** the zsh plugins and Starship, so it can override any alias or variable defined in `.zshrc`.

```sh
# ~/.zshrc.local
export OPENAI_API_KEY="..."
alias work='cd ~/Developer/work'
```

Apply with `reload` (alias for `exec zsh`).

## Git: `~/.gitconfig.local`

`git/.gitconfig` ends with:

```ini
[include]
    path = ~/.gitconfig.local
```

Keys in the included file override earlier values. Typical contents:

```ini
# macOS example
[gpg "ssh"]
    allowedSignersFile = ~/.ssh/allowed_signers
```

On Windows, start from `git/.gitconfig.windows` (see [Windows setup](windows-setup.md)) and append to it.

To use a different identity for a work machine:

```ini
[user]
    email = you@work.example
    signingkey = ssh-ed25519 AAAA...
```
