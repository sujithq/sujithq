# Generates 100x100 thumbnails for PNG/JPG/SVG assets and
# 40x40 icon thumbnails for files in assets/icons.
# Sets CHANGED=1 in $GITHUB_ENV when at least one file is created.

$changed = $false

# ── 100×100 thumbnails (PNG + JPG) ───────────────────────────────────────────
Get-ChildItem -Path assets -Recurse -Include *.png, *.jpg, *.jpeg |
    Where-Object { $_.Name -notmatch '-100x100\.(png|jpg|jpeg)$' -and
                   $_.Name -notmatch '-40x40\.(png|jpg|jpeg)$' } |
    ForEach-Object {
        $img = $_.FullName
        $ext = $_.Extension.TrimStart('.')
        $out = $img -replace "\.$ext$", "-100x100.$ext"

        if ($ext -eq 'png') {
            magick $img -alpha on -background none `
                -thumbnail 100x100^ -gravity center -extent 100x100 `
                -strip -define png:color-type=6 $out
        } else {
            magick $img -background white -alpha remove -alpha off `
                -thumbnail 100x100^ -gravity center -extent 100x100 `
                -strip $out
        }

        if (Test-Path $out) {
            Write-Host "Created: $out"
            $changed = $true
        }
    }

# ── 100×100 thumbnails (SVG → PNG) ───────────────────────────────────────────
Get-ChildItem -Path assets -Recurse -Include *.svg |
    Where-Object { $_.Name -notmatch '-100x100\.svg$' -and
                   $_.Name -notmatch '-40x40\.svg$' } |
    ForEach-Object {
        $svg  = $_.FullName
        $base = $svg -replace '\.svg$', ''
        $out  = "$base-100x100.png"
        if (Test-Path $out) { return }

        if (Get-Command rsvg-convert -ErrorAction SilentlyContinue) {
            rsvg-convert -w 100 -h 100 -b transparent $svg -o $out
        } else {
            magick -background none -alpha on -resize 100x100 $svg $out
        }

        if (Test-Path $out) {
            Write-Host "Created: $out"
            $changed = $true
        }
    }

# ── 40×40 icons (PNG + JPG) ──────────────────────────────────────────────────
Get-ChildItem -Path assets/icons -Include *.png, *.jpg, *.jpeg |
    Where-Object { $_.Name -notmatch '-40x40\.(png|jpg|jpeg)$' -and
                   $_.Name -notmatch '-100x100\.(png|jpg|jpeg)$' } |
    ForEach-Object {
        $img = $_.FullName
        $ext = $_.Extension.TrimStart('.')
        $out = $img -replace "\.$ext$", "-40x40.$ext"

        if ($ext -eq 'png') {
            magick $img -alpha on -background none `
                -thumbnail 40x40^ -gravity center -extent 40x40 `
                -strip -define png:color-type=6 $out
        } else {
            magick $img -background white -alpha remove -alpha off `
                -thumbnail 40x40^ -gravity center -extent 40x40 `
                -strip $out
        }

        if (Test-Path $out) {
            Write-Host "Created: $out"
            $changed = $true
        }
    }

# ── 40×40 icons (SVG → PNG) ──────────────────────────────────────────────────
Get-ChildItem -Path assets/icons -Include *.svg |
    Where-Object { $_.Name -notmatch '-40x40\.svg$' -and
                   $_.Name -notmatch '-100x100\.svg$' } |
    ForEach-Object {
        $svg  = $_.FullName
        $base = $svg -replace '\.svg$', ''
        $out  = "$base-40x40.png"
        if (Test-Path $out) { return }

        if (Get-Command rsvg-convert -ErrorAction SilentlyContinue) {
            rsvg-convert -w 40 -h 40 -b transparent $svg -o $out
        } else {
            magick -background none -alpha on -resize 40x40 $svg $out
        }

        if (Test-Path $out) {
            Write-Host "Created: $out"
            $changed = $true
        }
    }

# ── Propagate result to GitHub Actions env ────────────────────────────────────
$changedValue = if ($changed) { '1' } else { '0' }
if ($env:GITHUB_ENV) {
    "CHANGED=$changedValue" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
}
