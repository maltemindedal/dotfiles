#!/bin/sh
# Gives GitHub repos the labels in github/labels.tsv, with the same colour and
# description everywhere. It creates missing labels and corrects the colour and
# description of existing ones. It never deletes or renames a label, so labels
# a single repo needs stay. Needs gh, logged in with write access to the repos.
#
#   sh github/sync-labels.sh [--check] [OWNER | OWNER/REPO]...
#
# With no arguments it syncs every repo you own and every repo you administer in
# an organisation, skipping archived repos and forks. OWNER syncs every repo of
# that user or organisation that is not archived or a fork. --check changes
# nothing: it lists the labels that differ and exits 1 if any repo differs.
set -eu

usage() {
  sed -n '2,13s/^# \{0,1\}//p' "$0"
}

LABELS="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/labels.tsv"
TAB=$(printf '\t')
check=0

case ${1-} in
  -h|--help) usage; exit 0 ;;
  --check) check=1; shift ;;
esac
for arg in "$@"; do
  case $arg in
    -*|*/*/*|/*|*/|'') printf 'sync-labels: not an OWNER or OWNER/REPO: %s\n\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done
command -v gh >/dev/null || { echo 'sync-labels: needs the GitHub CLI (gh)' >&2; exit 2; }
[ -f "$LABELS" ] || { echo "sync-labels: missing $LABELS" >&2; exit 2; }

list_repos() {
  if [ "$#" -eq 0 ]; then
    gh api --paginate 'user/repos?affiliation=owner,organization_member&per_page=100' \
      --jq '.[] | select(.archived | not) | select(.fork | not) | select(.permissions.admin) | .full_name' </dev/null
    return
  fi
  for arg in "$@"; do
    case $arg in
      */*) printf '%s\n' "$arg" ;;
      *) gh repo list "$arg" --limit 1000 --no-archived --source \
           --json nameWithOwner --jq '.[].nameWithOwner' </dev/null ;;
    esac
  done
}

repos=$(list_repos "$@")
[ -n "$repos" ] || { echo 'sync-labels: found no repos' >&2; exit 1; }

bad=0
for repo in $repos; do
  if ! have=$(gh label list -R "$repo" --limit 1000 --json name,color,description \
      --jq '.[] | [.name, .color, .description] | @tsv' </dev/null); then
    printf 'FAIL %s: could not read its labels\n' "$repo"
    bad=$((bad + 1))
    continue
  fi
  changes=
  failed=0
  while IFS="$TAB" read -r name color desc; do
    case $name in ''|'#'*) continue ;; esac
    printf '%s\n' "$have" | grep -qxF -- "$name$TAB$color$TAB$desc" && continue
    if printf '%s\n' "$have" | cut -f1 | grep -qixF -- "$name"; then action=update; else action=create; fi
    if [ "$check" -eq 0 ] &&
        ! gh label create "$name" -R "$repo" --color "$color" --description "$desc" --force >/dev/null </dev/null; then
      action="$action FAILED"
      failed=1
    fi
    changes="$changes
     $action $name"
  done < "$LABELS"
  if [ -z "$changes" ]; then
    printf 'ok   %s\n' "$repo"
  elif [ "$check" -eq 1 ]; then
    printf 'DIFF %s%s\n' "$repo" "$changes"
    bad=$((bad + 1))
  elif [ "$failed" -eq 1 ]; then
    printf 'FAIL %s%s\n' "$repo" "$changes"
    bad=$((bad + 1))
  else
    printf 'sync %s%s\n' "$repo" "$changes"
  fi
done

[ "$bad" -eq 0 ]
