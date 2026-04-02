#!/usr/bin/env bash
set -euo pipefail

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add 'assets/**/*-100x100.*' 'assets/icons/*-40x40.*'
git commit -m "chore(assets): add 100x100 and 40x40 thumbnails"
git push
