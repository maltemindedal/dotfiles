# Keep GitHub labels the same in every repo

Coding agents find work by issue label, so every repo carries the same labels. [`github/labels.tsv`](../../github/labels.tsv) lists them, and [`github/sync-labels.sh`](../../github/sync-labels.sh) applies them with the GitHub CLI.

## Requirements

[`gh`](https://cli.github.com), logged in (`gh auth login`) as an account with write access to the repos.

## Check that every repo matches

```sh
sh github/sync-labels.sh --check
```

It prints `ok` for each repo that matches and `DIFF` with the labels to create or update for each repo that does not, then exits 1 if any repo differs. It changes nothing.

## Sync the labels

```sh
sh github/sync-labels.sh
```

With no arguments the script covers every repo you own and every repo you administer in an organisation. It skips archived repos and forks. To cover other repos, name them:

```sh
sh github/sync-labels.sh xmindm                 # every repo of a user or organisation
sh github/sync-labels.sh maltemindedal/stash    # one repo
```

The script creates missing labels and corrects the colour and description of existing ones. It never deletes or renames a label, so a label only one repo uses, such as `frontend` or a Dependabot ecosystem label, stays. Run it after creating a repo, because GitHub gives a new personal repo only its own default labels.

## Add or change a label

1. Edit `github/labels.tsv`. Each line is a name, a colour as six lowercase hex digits without `#`, and a description, separated by single tabs.
2. Run `sh tests/sync_labels_test.sh` to check the file, then `sh github/sync-labels.sh` to apply it.

To rename a label, rename it on GitHub in each repo first (`gh label edit OLD --name NEW -R OWNER/REPO`), which keeps it on its issues, then change the name in `labels.tsv`. Removing a line from `labels.tsv` leaves the label in place on GitHub. Delete it there by hand if no repo needs it.

## The labels

| Label | Meaning |
|-------|---------|
| `needs-triage` | Maintainer needs to evaluate this issue |
| `needs-info` | Waiting on reporter for more information |
| `ready-for-agent` | Fully specified, ready for an AFK agent |
| `ready-for-human` | Requires human implementation |
| `wontfix` | This will not be worked on |
| `blocked` | Waiting on another issue or an external dependency |
| `needs-decision` | Needs a maintainer decision before work can start |
| `priority: high` | Do this before other work |
| `priority: medium` | Normal priority |
| `priority: low` | Low priority; do not jump ahead of in-flight work |
| `security` | Security vulnerability or hardening |

The first five are the triage roles in each repo's `docs/agents/triage-labels.md`.
