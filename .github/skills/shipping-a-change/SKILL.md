---
name: shipping-a-change
description: What to update when you change something in this repository, and what done requires. Use before opening a pull request.
---

# Shipping a change

## Add a new certificate or badge

1. `assets/<provider>/` — add the optimized PNG or JPEG.
2. `README.md` — add the certificate or badge entry and stable raw image link.
3. `bash scripts/verify.sh` — verify the repository checks.

## When you change this, also change that

| Change | Also update |
|---|---|
| `README.md` profile content | Referenced files under `assets/` and any affected external links |
| `.github/workflows/` | `.github/aw/actions-lock.json` when action pins change |
| `scripts/*.sh` | The matching `scripts/*.ps1` file and README usage documentation |
| Contributor process | `README.md`, `.github/PULL_REQUEST_TEMPLATE.md`, and `CHANGELOG.md` |

## Done

- `bash scripts/verify.sh` completes without failures.
- Changed README image paths and external links have been checked.
- Affected workflow files remain valid YAML and existing automation is preserved.
