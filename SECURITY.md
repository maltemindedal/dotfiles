# Security policy

This is a personal configuration, so only the latest commit on `main` is supported. Fixes land there and are not backported.

## Reporting a vulnerability

Report vulnerabilities privately through [GitHub's private vulnerability reporting](https://github.com/maltemindedal/dotfiles/security/advisories/new). Do not open a public issue or pull request for a security problem.

Include the affected file, the steps to reproduce, and the impact. Reports are handled on a best-effort basis.

## Scope

In scope:

- `install.sh`, for example unsafe file permissions, unquoted paths, or commands that run untrusted input.
- The shell and Git configuration in `shell/` and `git/`, for example settings that weaken SSH signing or expose data.
- Secrets or personal data committed to the repository by mistake.

Out of scope:

- Vulnerabilities in the third-party tools the configuration loads (Homebrew, Starship, fzf, zsh plugins and so on). Report those to their maintainers.
- Problems caused by the contents of your own `~/.zshrc.local` or `~/.gitconfig.local`.
