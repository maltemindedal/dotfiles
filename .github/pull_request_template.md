## What changed and why

<!-- Describe the change and the reason for it. -->

Closes #

## Checks

From [CONTRIBUTING.md](https://github.com/maltemindedal/dotfiles/blob/main/CONTRIBUTING.md#making-a-change):

- [ ] `zsh -n shell/.zshrc`
- [ ] `git config -f git/.gitconfig -l`
- [ ] `sh tests/install_test.sh`
- [ ] `sh tests/zshrc_test.sh`
- [ ] `reload`
- [ ] Added or updated a case in `tests/` if this changes what `install.sh` or `.zshrc` does
- [ ] Updated the docs that describe the change
