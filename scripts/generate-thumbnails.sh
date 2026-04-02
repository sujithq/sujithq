#!/usr/bin/env bash
# Generates 100x100 thumbnails for PNG/JPG/SVG assets and
# 40x40 icon thumbnails for files in assets/icons.
# Sets CHANGED=1 in $GITHUB_ENV when at least one file is created.
set -euo pipefail

changed=0

# ── 100×100 thumbnails (PNG + JPG) ───────────────────────────────────────────
shopt -s globstar nullglob
for img in assets/**/*.{png,jpg,jpeg}; do
  [[ "$img" =~ -100x100\.(png|jpg|jpeg)$ ]] && continue
  [[ "$img" =~  -40x40\.(png|jpg|jpeg)$ ]] && continue

  ext="${img##*.}"
  out="${img%.*}-100x100.${ext}"

  if [[ "$ext" == "png" ]]; then
    convert "$img" \
      -alpha on -background none \
      -thumbnail 100x100^ -gravity center -extent 100x100 \
      -strip -define png:color-type=6 "$out"
  else
    convert "$img" \
      -background white -alpha remove -alpha off \
      -thumbnail 100x100^ -gravity center -extent 100x100 \
      -strip "$out"
  fi

  if [[ -f "$out" ]]; then
    echo "Created: $out"
    changed=1
  fi
done

# ── 100×100 thumbnails (SVG → PNG) ───────────────────────────────────────────
for svg in assets/**/*.svg; do
  [[ "$svg" =~ -100x100\.svg$ ]] && continue
  [[ "$svg" =~  -40x40\.svg$  ]] && continue
  base="${svg%.svg}"
  out="${base}-100x100.png"
  [[ -f "$out" ]] && continue

  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w 100 -h 100 -b transparent "$svg" -o "$out"
  else
    convert -background none -alpha on -resize 100x100 "$svg" "$out"
  fi

  if [[ -f "$out" ]]; then
    echo "Created: $out"
    changed=1
  fi
done

# ── 40×40 icons (PNG + JPG) ──────────────────────────────────────────────────
shopt -s nullglob
for img in assets/icons/*.{png,jpg,jpeg}; do
  [[ "$img" =~ -40x40\.(png|jpg|jpeg)$   ]] && continue
  [[ "$img" =~ -100x100\.(png|jpg|jpeg)$ ]] && continue

  ext="${img##*.}"
  out="${img%.*}-40x40.${ext}"

  if [[ "$ext" == "png" ]]; then
    convert "$img" \
      -alpha on -background none \
      -thumbnail 40x40^ -gravity center -extent 40x40 \
      -strip -define png:color-type=6 "$out"
  else
    convert "$img" \
      -background white -alpha remove -alpha off \
      -thumbnail 40x40^ -gravity center -extent 40x40 \
      -strip "$out"
  fi

  if [[ -f "$out" ]]; then
    echo "Created: $out"
    changed=1
  fi
done

# ── 40×40 icons (SVG → PNG) ──────────────────────────────────────────────────
for svg in assets/icons/*.svg; do
  [[ "$svg" =~ -40x40\.svg$   ]] && continue
  [[ "$svg" =~ -100x100\.svg$ ]] && continue
  base="${svg%.svg}"
  out="${base}-40x40.png"
  [[ -f "$out" ]] && continue

  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w 40 -h 40 -b transparent "$svg" -o "$out"
  else
    convert -background none -alpha on -resize 40x40 "$svg" "$out"
  fi

  if [[ -f "$out" ]]; then
    echo "Created: $out"
    changed=1
  fi
done

# ── Propagate result to GitHub Actions env ────────────────────────────────────
echo "CHANGED=$changed" >> "${GITHUB_ENV:-/dev/null}"
