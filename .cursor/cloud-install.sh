#!/bin/sh
# Tools for .agents/skills/verify-dotfiles on a Linux cloud VM.
# A rerun with zsh, shellcheck and pwsh already installed does no work.
set -eu

has() { command -v "$1" >/dev/null 2>&1; }

if has zsh && has shellcheck && has pwsh; then
  exit 0
fi

apt() { sudo DEBIAN_FRONTEND=noninteractive apt-get "$@"; }

# VERSION_ID comes from the image, so this script does not pin Ubuntu or PowerShell.
if ! has pwsh && ! dpkg-query -W -f '${Status}' packages-microsoft-prod 2>/dev/null | grep -q 'install ok installed'; then
  apt update
  apt install -y wget apt-transport-https software-properties-common
  version_id=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')
  deb=$(mktemp)
  trap 'rm -f "$deb"' EXIT
  wget -q --no-hsts -O "$deb" "https://packages.microsoft.com/config/ubuntu/${version_id}/packages-microsoft-prod.deb"
  sudo dpkg -i "$deb"
  rm -f "$deb"
  trap - EXIT
fi

apt update

set --
has zsh || set -- "$@" zsh
has shellcheck || set -- "$@" shellcheck
if [ "$#" -gt 0 ]; then
  apt install -y "$@"
fi

if ! has pwsh; then
  apt install -y powershell
fi
