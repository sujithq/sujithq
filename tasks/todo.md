# Task Plan

> Write your plan here before starting any non-trivial work.
> Mark items complete as you go. Add a review section when done.

## Current Task
Add a minimal Windows PowerShell usage note for the dojo scripts in README.md.

## Plan
- [x] Add a short PowerShell usage section to README.md.
- [x] Keep the change minimal and consistent with existing README style.
- [x] Run the PowerShell verification script and capture the result.

## Review
- Added a small `Copilot Agents Dojo` section to README.md with Windows PowerShell commands for `init.ps1`, `lesson-updater.ps1`, and `verify.ps1`.
- Verified with `pwsh ./scripts/verify.ps1`.
- Result: 2 passed, 0 failed, 2 warnings.
- Warnings were expected for this docs-only change: uncommitted changes in the working tree and no detected test runner.
