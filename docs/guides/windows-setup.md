# Windows setup

Follow this guide to install the PowerShell profile and Git configuration from this repository on a Windows machine.

## PowerShell profile

`shell/Microsoft.PowerShell_profile.ps1` configures PSReadLine inline predictions and initialises Starship. Requirements:

- PowerShell 7.2 or later.
- PSReadLine 2.2 or later, which PowerShell 7.3 and later bundle. See the [PSReadLine 2.2.6 release notes](https://devblogs.microsoft.com/powershell/psreadline-2-2-6-enables-predictive-intellisense-by-default/). PowerShell 7.2 bundles PSReadLine 2.1, which lacks both prediction options, so the profile prints two errors at every start. On 7.2, install a current PSReadLine once:

  ```powershell
  Install-Module PSReadLine -Scope CurrentUser -Force
  ```

- [Starship](https://starship.rs) on `PATH`.

Copy it to the path PowerShell stores in `$PROFILE`:

```powershell
git clone https://github.com/maltemindedal/dotfiles $HOME\Developer\dotfiles
New-Item -ItemType Directory -Force (Split-Path $PROFILE) | Out-Null
Copy-Item $HOME\Developer\dotfiles\shell\Microsoft.PowerShell_profile.ps1 $PROFILE
```

You can also copy the Starship config:

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

2. Copy the Windows settings to the local include file. `.gitconfig` includes `~/.gitconfig.local`. The `git/.gitconfig.windows` file selects the Windows OpenSSH binaries with `core.sshCommand = ssh.exe` and `gpg.ssh.program = ssh-keygen.exe`:

   ```powershell
   Copy-Item $HOME\Developer\dotfiles\git\.gitconfig.windows $HOME\.gitconfig.local
   ```

3. Add any further host-specific keys (for example `gpg.ssh.allowedSignersFile`) to `$HOME\.gitconfig.local`. See [Machine-specific overrides](machine-specific-overrides.md).

4. Install the [GitHub CLI](https://cli.github.com) and run `gh auth login`. `.gitconfig` uses `gh auth git-credential` as the credential helper for github.com and gist.github.com.
