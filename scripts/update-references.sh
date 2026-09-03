#!/bin/bash
# Bring the reference clones the omasync skill compares against up to date.
#
# For every Git clone directly under QUARRY (default ~/Projects/quarry):
#   - resolve the origin's current GitHub location through the API, which
#     follows repository transfers and renames, and repoint origin when it moved
#   - resolve the upstream default branch (git remote set-head origin -a) and
#     check it out, tracking origin, when the clone is on another branch
#   - fetch with prune and forced tags (upstream moves rolling tags such as
#     nightly), then fast-forward to the default branch
# A clone with local changes to tracked files, or a checkout that cannot
# fast-forward, is reported and left alone; the run then exits non-zero so the
# skill never compares against a clone this run did not update. Non-GitHub
# remotes skip the transfer lookup and are fetched as they are.
# Usage: update-references.sh [--dry-run]
set -uo pipefail

quarry=${QUARRY:-$HOME/Projects/quarry}
dry_run=0
case ${1:-} in
  '') ;;
  --dry-run) dry_run=1 ;;
  *) printf 'usage: update-references.sh [--dry-run]\n' >&2; exit 2 ;;
esac
[[ -d $quarry ]] || { printf 'FAIL: reference directory is missing: %s\n' "$quarry" >&2; exit 1; }
for tool in git gh; do
  command -v "$tool" >/dev/null || { printf 'FAIL: required tool is missing: %s\n' "$tool" >&2; exit 1; }
done

fail=0
problem() {
  printf 'FAIL: %s\n' "$1" >&2
  fail=1
}

github_slug() { # origin url -> owner/repo, or nothing for a non-GitHub remote
  local url=$1 slug
  case $url in
    https://github.com/* | http://github.com/* | ssh://git@github.com/*) slug=${url#*github.com/} ;;
    git@github.com:*) slug=${url#git@github.com:} ;;
    *) return 1 ;;
  esac
  slug=${slug%/}
  slug=${slug%.git}
  [[ $slug == */* ]] && printf '%s\n' "$slug"
}

for clone in "$quarry"/*/; do
  clone=${clone%/}
  name=${clone##*/}
  [[ -d $clone/.git ]] || continue
  url=$(git -C "$clone" remote get-url origin 2>/dev/null) || { problem "$name: no origin remote"; continue; }

  if slug=$(github_slug "$url"); then
    current=$(gh api "repos/$slug" --jq .full_name 2>/dev/null)
    if [[ -z $current ]]; then
      problem "$name: cannot resolve $slug on GitHub"
      continue
    elif [[ $current != "$slug" ]]; then
      if [[ $url == git@github.com:* ]]; then new_url="git@github.com:$current.git"; else new_url="https://github.com/$current.git"; fi
      if ((dry_run)); then
        printf 'plan: %s: repoint origin %s -> %s\n' "$name" "$slug" "$current"
      else
        git -C "$clone" remote set-url origin "$new_url" || { problem "$name: cannot repoint origin"; continue; }
        printf 'ok:   %s: repointed origin %s -> %s\n' "$name" "$slug" "$current"
      fi
    fi
  fi

  if [[ -n $(git -C "$clone" status --porcelain --untracked-files=no) ]]; then
    problem "$name: local changes to tracked files; left alone"
    continue
  fi

  if ((dry_run)); then
    printf 'plan: %s: set-head, fetch, and fast-forward to the upstream default branch (now on %s)\n' \
      "$name" "$(git -C "$clone" branch --show-current)"
    continue
  fi

  git -C "$clone" remote set-head origin -a >/dev/null 2>&1 || { problem "$name: cannot resolve the upstream default branch"; continue; }
  default=$(git -C "$clone" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) || { problem "$name: origin/HEAD is unset"; continue; }
  default=${default#origin/}
  git -C "$clone" fetch -q --prune --prune-tags --tags --force origin || { problem "$name: fetch failed"; continue; }

  branch=$(git -C "$clone" branch --show-current)
  if [[ $branch != "$default" ]]; then
    if git -C "$clone" show-ref --verify -q "refs/heads/$default"; then
      git -C "$clone" checkout -q "$default" || { problem "$name: cannot check out $default"; continue; }
    else
      git -C "$clone" checkout -q -b "$default" --track "origin/$default" || { problem "$name: cannot create $default"; continue; }
    fi
    printf 'ok:   %s: switched %s -> %s\n' "$name" "${branch:-detached}" "$default"
  fi

  before=$(git -C "$clone" rev-parse --short HEAD)
  if git -C "$clone" merge -q --ff-only "origin/$default" 2>/dev/null; then
    after=$(git -C "$clone" rev-parse --short HEAD)
    if [[ $before == "$after" ]]; then
      printf 'ok:   %s: %s up to date at %s\n' "$name" "$default" "$after"
    else
      printf 'ok:   %s: %s fast-forwarded %s -> %s\n' "$name" "$default" "$before" "$after"
    fi
  else
    problem "$name: $default has diverged from origin/$default; left alone"
  fi
done

exit "$fail"
