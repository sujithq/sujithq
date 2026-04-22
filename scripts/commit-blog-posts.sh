#!/usr/bin/env bash
set -euo pipefail

if [[ -n "$(git status --porcelain)" ]]; then
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git add README.md
  git commit -m "chore(readme): update latest blog posts"
  git push
else
  echo "No changes to commit."
fi
