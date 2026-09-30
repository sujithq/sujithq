# Repository guidance

Read this file before making changes. This repository is a static GitHub profile; keep changes focused on
profile content, supporting assets, and the automation that generates them.

## Working agreements

- Use `master` as the default branch and keep generated contribution artwork on its existing output branches.
- Prefer small, direct edits. Preserve the existing README layout and image sizing conventions.
- Store certificates and badges under `assets/<provider>/` and reference repository images with stable raw URLs.
- Treat `.github/copilot-instructions.md` as existing Copilot guidance; extend it only when a change is
  specifically Copilot-related rather than duplicating this file.
- There is no application build or automated test suite. Use the repository verification script and inspect
  Markdown, image paths, external links, and workflow syntax for affected changes.

## Maintenance matrix

| Change | Also update |
|---|---|
| Add or remove a certificate or badge | `README.md`, the matching `assets/<provider>/` directory |
| Change a profile image or icon | `README.md`, the referenced file under `assets/` |
| Change a workflow source or generated workflow | The related `.github/workflows/` file and `.github/aw/actions-lock.json` when action pins change |
| Change verification or initialization scripts | The matching PowerShell script and README usage documentation |
| Add a contributor-facing process | `README.md`, `.github/PULL_REQUEST_TEMPLATE.md`, and `CHANGELOG.md` |

## Done means

- `bash scripts/verify.sh` completes without failures.
- Changed README image paths and external links have been checked.
- Affected workflow files remain valid YAML and existing automation is preserved.

## Never merges without a human

A person has to have **read this diff** before it lands. Telling an agent "merge it when you're done" is
approving a goal, not this change — so it does not count for anything on this list. Everywhere else it counts
fine, which is the point of having a list.

- Changes to `.github/workflows/` or `.github/aw/`
- Changes to profile links, certification claims, or externally hosted assets
- Changes that expose credentials, tokens, or other repository secrets

## Documentation

The main documentation is `README.md`. Skills and their specification are documented in `skills.md`,
`spec/copilot-skills-spec.md`, and the individual `SKILL.md` files.
