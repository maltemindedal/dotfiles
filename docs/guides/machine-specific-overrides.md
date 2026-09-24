# Machine-specific overrides

Use local override files to add settings for one machine, such as secrets, absolute paths, and work-specific aliases, without modifying tracked files.

Both config files in this repository load an optional local file that is not tracked in git.

## zsh: `~/.zshrc.local`

`shell/.zshrc` sources `~/.zshrc.local` if it exists. The local file loads after the aliases, nvm, fzf, and zoxide setup but before the zsh plugins and Starship. It can override any alias or variable defined in `.zshrc`.

```sh
# ~/.zshrc.local
export OPENAI_API_KEY="..."
alias work='cd ~/Developer/work'
```

Run `reload`, an alias for `exec zsh`, to apply the changes.

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
    signingkey = key::ssh-ed25519 AAAA...
```
