#!/bin/sh
# Install zsh and shellcheck, and pwsh only where Microsoft publishes it.
set -eu

has() { command -v "$1" >/dev/null 2>&1; }

warn() { printf 'cloud-install: %s\n' "$1" >&2; }

apt() { sudo DEBIAN_FRONTEND=noninteractive apt-get "$@"; }

# packages.microsoft.com publishes the powershell apt package for these hosts only.
pwsh_published() {
  os_id=$1
  version_id=$2
  arch=$3
  [ "$os_id" = ubuntu ] || return 1
  [ "$arch" = amd64 ] || return 1
  case $version_id in
    22.04|24.04) return 0 ;;
    *) return 1 ;;
  esac
}

# Tests pass a fixture. The default is this machine.
read_host() {
  os_file=${CLOUD_INSTALL_OS_RELEASE:-/etc/os-release}
  os_id=$(sed -n 's/^ID=//p' "$os_file" | head -n 1 | tr -d '"')
  version_id=$(sed -n 's/^VERSION_ID=//p' "$os_file" | head -n 1 | tr -d '"')
  if [ -n "${CLOUD_INSTALL_ARCH:-}" ]; then
    arch=$CLOUD_INSTALL_ARCH
  elif has dpkg; then
    arch=$(dpkg --print-architecture)
  else
    arch=$(uname -m)
  fi
  case $arch in
    x86_64) arch=amd64 ;;
    aarch64) arch=arm64 ;;
  esac
}

# Returns 0 when apt should install powershell. Prints a skip and returns 1 otherwise.
prepare_pwsh_repo() {
  read_host
  if ! pwsh_published "$os_id" "$version_id" "$arch"; then
    warn "skipping pwsh. Microsoft publishes the powershell apt package for amd64 Ubuntu 22.04 and 24.04 only. This host is ${os_id} ${version_id} ${arch}."
    return 1
  fi
  if dpkg-query -W -f '${Status}' packages-microsoft-prod 2>/dev/null | grep -q 'install ok installed'; then
    return 0
  fi
  if ! has wget; then
    apt update
    apt install -y wget
  fi
  url="https://packages.microsoft.com/config/ubuntu/${version_id}/packages-microsoft-prod.deb"
  if ! wget -q --no-hsts --spider "$url"; then
    warn "skipping pwsh. ${url} is not available."
    return 1
  fi
  if [ -n "${CLOUD_INSTALL_DEB:-}" ]; then
    deb=$CLOUD_INSTALL_DEB
  else
    deb=$(mktemp)
  fi
  trap 'rm -f "$deb"' EXIT
  if ! wget -q --no-hsts -O "$deb" "$url"; then
    warn "skipping pwsh. ${url} is not available."
    return 1
  fi
  if ! dpkg-deb -I "$deb" control 2>/dev/null | grep -q '^Package: packages-microsoft-prod$'; then
    warn "skipping pwsh. The file from ${url} is not a packages-microsoft-prod package."
    return 1
  fi
  if ! sudo dpkg -i "$deb"; then
    warn "skipping pwsh. dpkg could not install ${url}."
    return 1
  fi
  return 0
}

if has zsh && has shellcheck && has pwsh; then
  exit 0
fi

want_pwsh=0
if ! has pwsh && prepare_pwsh_repo; then
  want_pwsh=1
fi

set --
has zsh || set -- "$@" zsh
has shellcheck || set -- "$@" shellcheck
if [ "$#" -gt 0 ] || [ "$want_pwsh" -eq 1 ]; then
  apt update
fi
if [ "$#" -gt 0 ]; then
  apt install -y "$@"
fi
if [ "$want_pwsh" -eq 1 ]; then
  if ! apt install -y powershell; then
    warn "skipping pwsh. apt could not install the powershell package."
  fi
fi
