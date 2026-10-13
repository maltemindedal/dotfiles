#!/bin/sh
# cloud-install.sh must keep going when Microsoft does not publish pwsh.
# Each case runs the script with stub sudo, wget, and dpkg, and a fake os-release.
# No network and no root.
#
#   sh tests/cloud_install_test.sh
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

check_file() { # check_file <description> <got> <expected>
  if cmp -s "$2" "$3"; then
    pass "$1"
  else
    fail "$1"
    printf '     got:\n'
    sed 's/^/     |/' "$2"
    printf '     expected:\n'
    sed 's/^/     |/' "$3"
  fi
}

BIN="$TMP/bin"
mkdir "$BIN"
for tool in sed tr mktemp grep rm head; do
  ln -s "$(command -v "$tool")" "$BIN/$tool"
done
printf '%s\n' '#!/bin/sh' 'exit 0' > "$BIN/present"
chmod +x "$BIN/present"
ln -s present "$BIN/zsh"
ln -s present "$BIN/shellcheck"

cat > "$BIN/sudo" <<'EOF'
#!/bin/sh
printf '%s\n' "sudo $*" >> "$STUB_LOG"
case "${SUDO_MODE:-ok}" in
  fail)
    case "$*" in
      *"install -y powershell"*) exit 1 ;;
    esac
    ;;
esac
exit 0
EOF
cat > "$BIN/wget" <<'EOF'
#!/bin/sh
printf '%s\n' "wget $*" >> "$STUB_LOG"
if [ "${WGET_MODE:-ok}" = missing ]; then
  exit 8
fi
prev=
for arg in "$@"; do
  if [ "$prev" = -O ]; then
    printf 'not-a-real-deb\n' > "$arg"
  fi
  prev=$arg
done
exit 0
EOF
cat > "$BIN/dpkg-deb" <<'EOF'
#!/bin/sh
if [ "${DEB_MODE:-good}" = good ]; then
  printf '%s\n' "Package: packages-microsoft-prod"
  exit 0
fi
printf '%s\n' "dpkg-deb: not a debian format archive" >&2
exit 2
EOF
cat > "$BIN/dpkg-query" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$BIN/sudo" "$BIN/wget" "$BIN/dpkg-deb" "$BIN/dpkg-query"

# run_install <name> <id> <version> <arch> <expected-exit>
# Honour WGET_MODE, DEB_MODE, SUDO_MODE, and WITH_PWSH from the caller.
run_install() {
  name=$1
  os_id=$2
  version_id=$3
  arch=$4
  want_rc=$5
  os_file=$TMP/$name.os-release
  deb=$TMP/$name.deb
  printf 'ID=%s\nVERSION_ID=%s\n' "$os_id" "$version_id" > "$os_file"
  : > "$TMP/log"
  if [ "${WITH_PWSH:-}" = 1 ]; then
    ln -s present "$BIN/pwsh"
  else
    rm -f "$BIN/pwsh"
  fi
  if env -i \
    PATH="$BIN" \
    HOME="$TMP" \
    STUB_LOG="$TMP/log" \
    WGET_MODE="${WGET_MODE:-ok}" \
    DEB_MODE="${DEB_MODE:-good}" \
    SUDO_MODE="${SUDO_MODE:-ok}" \
    CLOUD_INSTALL_OS_RELEASE="$os_file" \
    CLOUD_INSTALL_ARCH="$arch" \
    CLOUD_INSTALL_DEB="$deb" \
    /bin/sh "$REPO/.cursor/cloud-install.sh" > "$TMP/$name.out" 2> "$TMP/$name.err"
  then
    rc=0
  else
    rc=$?
  fi
  if [ "$rc" -eq "$want_rc" ]; then
    pass "$name exits $want_rc"
  else
    fail "$name exits $want_rc (got $rc)"
  fi
  check_file "$name stdout" "$TMP/$name.out" "$TMP/empty"
  check_file "$name stderr" "$TMP/$name.err" "$TMP/$name.err-want"
  check_file "$name commands" "$TMP/log" "$TMP/$name.log-want"
}

: > "$TMP/empty"

# Ubuntu 26.04 amd64. The prod deb exists, and the powershell package does not.
WGET_MODE=ok DEB_MODE=good SUDO_MODE=ok \
  printf '%s\n' "cloud-install: skipping pwsh. Microsoft publishes the powershell apt package for amd64 Ubuntu 22.04 and 24.04 only. This host is ubuntu 26.04 amd64." > "$TMP/ubuntu-26.err-want"
: > "$TMP/ubuntu-26.log-want"
WGET_MODE=ok DEB_MODE=good SUDO_MODE=ok \
  run_install ubuntu-26 ubuntu 26.04 amd64 0

# Ubuntu 24.04 arm64. powershell is absent from the arm64 index.
printf '%s\n' "cloud-install: skipping pwsh. Microsoft publishes the powershell apt package for amd64 Ubuntu 22.04 and 24.04 only. This host is ubuntu 24.04 arm64." > "$TMP/arm64.err-want"
: > "$TMP/arm64.log-want"
WGET_MODE=ok DEB_MODE=good SUDO_MODE=ok \
  run_install arm64 ubuntu 24.04 arm64 0

# A non-Ubuntu host must not build a packages.microsoft.com URL.
printf '%s\n' "cloud-install: skipping pwsh. Microsoft publishes the powershell apt package for amd64 Ubuntu 22.04 and 24.04 only. This host is debian 12 amd64." > "$TMP/debian.err-want"
: > "$TMP/debian.log-want"
WGET_MODE=ok DEB_MODE=good SUDO_MODE=ok \
  run_install debian debian 12 amd64 0

# The published host, and the deb URL answers 404. wget -q would exit 8 with no text.
printf '%s\n' "cloud-install: skipping pwsh. https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb is not available." > "$TMP/missing-deb.err-want"
printf '%s\n' "wget -q --no-hsts --spider https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb" > "$TMP/missing-deb.log-want"
WGET_MODE=missing DEB_MODE=good SUDO_MODE=ok \
  run_install missing-deb ubuntu 24.04 amd64 0

# The download is not the Microsoft repo package, so dpkg must not install it as root.
printf '%s\n' "cloud-install: skipping pwsh. The file from https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb is not a packages-microsoft-prod package." > "$TMP/bad-deb.err-want"
cat > "$TMP/bad-deb.log-want" <<'EOF'
wget -q --no-hsts --spider https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
wget -q --no-hsts -O @DEB@ https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
EOF
sed "s|@DEB@|$TMP/bad-deb.deb|" "$TMP/bad-deb.log-want" > "$TMP/bad-deb.log-want.tmp"
mv "$TMP/bad-deb.log-want.tmp" "$TMP/bad-deb.log-want"
WGET_MODE=ok DEB_MODE=bad SUDO_MODE=ok \
  run_install bad-deb ubuntu 24.04 amd64 0

# amd64 Ubuntu 24.04 installs powershell, with one apt update.
cat > "$TMP/ubuntu-24.log-want" <<'EOF'
wget -q --no-hsts --spider https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
wget -q --no-hsts -O @DEB@ https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
sudo dpkg -i @DEB@
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y powershell
EOF
sed "s|@DEB@|$TMP/ubuntu-24.deb|g" "$TMP/ubuntu-24.log-want" > "$TMP/ubuntu-24.log-want.tmp"
mv "$TMP/ubuntu-24.log-want.tmp" "$TMP/ubuntu-24.log-want"
: > "$TMP/ubuntu-24.err-want"
WGET_MODE=ok DEB_MODE=good SUDO_MODE=ok \
  run_install ubuntu-24 ubuntu 24.04 amd64 0

# The other published release.
cat > "$TMP/ubuntu-22.log-want" <<'EOF'
wget -q --no-hsts --spider https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
wget -q --no-hsts -O @DEB@ https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
sudo dpkg -i @DEB@
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y powershell
EOF
sed "s|@DEB@|$TMP/ubuntu-22.deb|g" "$TMP/ubuntu-22.log-want" > "$TMP/ubuntu-22.log-want.tmp"
mv "$TMP/ubuntu-22.log-want.tmp" "$TMP/ubuntu-22.log-want"
: > "$TMP/ubuntu-22.err-want"
WGET_MODE=ok DEB_MODE=good SUDO_MODE=ok \
  run_install ubuntu-22 ubuntu 22.04 amd64 0

# apt install powershell failing must not fail the script.
printf '%s\n' "cloud-install: skipping pwsh. apt could not install the powershell package." > "$TMP/apt-fail.err-want"
cat > "$TMP/apt-fail.log-want" <<'EOF'
wget -q --no-hsts --spider https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
wget -q --no-hsts -O @DEB@ https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
sudo dpkg -i @DEB@
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y powershell
EOF
sed "s|@DEB@|$TMP/apt-fail.deb|g" "$TMP/apt-fail.log-want" > "$TMP/apt-fail.log-want.tmp"
mv "$TMP/apt-fail.log-want.tmp" "$TMP/apt-fail.log-want"
WGET_MODE=ok DEB_MODE=good SUDO_MODE=fail \
  run_install apt-fail ubuntu 24.04 amd64 0

# Tools already present. No apt and no warning.
: > "$TMP/present.err-want"
: > "$TMP/present.log-want"
WGET_MODE=ok DEB_MODE=good SUDO_MODE=ok WITH_PWSH=1 \
  run_install present ubuntu 26.04 arm64 0

echo
if [ "$fails" -eq 0 ]; then echo "all cloud-install tests passed"; else echo "$fails cloud-install test(s) failed"; exit 1; fi
