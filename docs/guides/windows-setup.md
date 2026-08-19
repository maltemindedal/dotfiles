# Windows setup

Goal: install the PowerShell profile and Git configuration from this repository on a Windows machine.

## PowerShell profile

`shell/Microsoft.PowerShell_profile.ps1` configures PSReadLine inline predictions and initialises Starship. Requirements:

- PowerShell 7.2 or later — the `HistoryAndPlugin` prediction source only supports plugins on 7.2+ (on older versions PSReadLine falls back to history-only predictions). Source: [PSReadLine 2.2.6 release notes](https://devblogs.microsoft.com/powershell/psreadline-2-2-6-enables-predictive-intellisense-by-default/).
- PSReadLine 2.2 or later (bundled with PowerShell 7.2+).
- [Starship](https://starship.rs) on `PATH`.

Copy it to the path PowerShell stores in `$PROFILE`:

```powershell
git clone https://github.com/maltemindedal/dotfiles $HOME\Developer\dotfiles
New-Item -ItemType Directory -Force (Split-Path $PROFILE) | Out-Null
Copy-Item $HOME\Developer\dotfiles\shell\Microsoft.PowerShell_profile.ps1 $PROFILE
```

Optionally link the Starship config as well:

```powershell
New-Item -ItemType Directory -Force $HOME\.config | Out-Null
Copy-Item $HOME\Developer\dotfiles\shell\starship.toml $HOME\.config\starship.toml
```

## Git

1. Copy the shared config and global ignore:

   ```powershell
   Copy-Item $HOME\Developer\dotfiles\git\.gitconfig $HOME\.gitconfig
   Copy-Item $HOME\Developer\dotfiles\git\.gitignore_global $HOME\.gitignore_global
   ```

2. Copy the Windows overlay to the local include file. `.gitconfig` includes `~/.gitconfig.local`, and `git/.gitconfig.windows` sets `core.sshCommand = ssh.exe` and `gpg.ssh.program = ssh-keygen.exe` so commit signing works with the Windows OpenSSH binaries:

   ```powershell
   Copy-Item $HOME\Developer\dotfiles\git\.gitconfig.windows $HOME\.gitconfig.local
   ```

3. Add any further host-specific keys (for example `gpg.ssh.allowedSignersFile`) to `$HOME\.gitconfig.local` — see [Machine-specific overrides](machine-specific-overrides.md).

4. Install the [GitHub CLI](https://cli.github.com) and run `gh auth login`; `.gitconfig` uses `gh auth git-credential` as the credential helper for github.com and gist.github.com.
