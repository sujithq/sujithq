#!/usr/bin/env pwsh
# Copilot Agents Dojo - Pre-PR Verification Wrapper
# Runs a series of checks before a PR is considered ready.
#
# Usage: pwsh scripts/verify.ps1
#
# Checks:
#   1. tasks/todo.md has a plan (not just the template)
#   2. No uncommitted changes (clean working tree)
#   3. Tests pass (auto-detects test runner)
#   4. Summary output

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
$RepoRoot = Split-Path -Parent $ScriptDir

$script:Passed = 0
$script:Failed = 0
$script:Warned = 0

function Pass([string]$Message) {
    Write-Host "  ✅ $Message"
    $script:Passed++
}

function Fail([string]$Message) {
    Write-Host "  ❌ $Message"
    $script:Failed++
}

function Warn([string]$Message) {
    Write-Host "  ⚠️  $Message"
    $script:Warned++
}

Write-Host "🥋 Copilot Agents Dojo - Pre-PR Verification"
Write-Host ""

# 1. Check for a plan in todo.md
Write-Host "[1/4] Checking tasks/todo.md for a plan..."
$todoFile = Join-Path $RepoRoot 'tasks/todo.md'
if (-not (Test-Path -LiteralPath $todoFile -PathType Leaf)) {
    Fail "tasks/todo.md not found. Create a plan before submitting."
} else {
    $todoContent = Get-Content -LiteralPath $todoFile -Raw
    $hasChecklist = $todoContent -match '- \[x\]|- \[ \]'
    $isTemplate = $todoContent -match 'Step 1'

    if ($hasChecklist -and -not $isTemplate) {
        Pass "Plan found in tasks/todo.md"
    } else {
        Warn "tasks/todo.md looks like the default template. Write a real plan."
    }
}

# 2. Check for uncommitted changes
Write-Host "[2/4] Checking for uncommitted changes..."
$gitClean = $false
& git -C $RepoRoot diff --quiet HEAD 2>$null
$unstagedCode = $LASTEXITCODE
& git -C $RepoRoot diff --cached --quiet HEAD 2>$null
$stagedCode = $LASTEXITCODE
if ($unstagedCode -eq 0 -and $stagedCode -eq 0) {
    $gitClean = $true
}

if ($gitClean) {
    Pass "Working tree is clean"
} else {
    Warn "Uncommitted changes detected. Commit or stash before PR."
}

# 3. Auto-detect and run tests
Write-Host "[3/4] Running tests..."
$testsRan = $false

$packageJson = Join-Path $RepoRoot 'package.json'
if (Test-Path -LiteralPath $packageJson -PathType Leaf) {
    $packageContent = Get-Content -LiteralPath $packageJson -Raw
    if ($packageContent -match '"test"') {
        Write-Host "   Detected: npm test"
        & npm test --prefix $RepoRoot
        if ($LASTEXITCODE -eq 0) {
            Pass "npm tests passed"
        } else {
            Fail "npm tests failed"
        }
        $testsRan = $true
    }
}

$pyproject = Join-Path $RepoRoot 'pyproject.toml'
$setupPy = Join-Path $RepoRoot 'setup.py'
$pytestIni = Join-Path $RepoRoot 'pytest.ini'
if ((Test-Path -LiteralPath $pyproject -PathType Leaf) -or (Test-Path -LiteralPath $setupPy -PathType Leaf) -or (Test-Path -LiteralPath $pytestIni -PathType Leaf)) {
    Write-Host "   Detected: pytest"
    & python -m pytest $RepoRoot
    if ($LASTEXITCODE -eq 0) {
        Pass "pytest passed"
    } else {
        Fail "pytest failed"
    }
    $testsRan = $true
}

$pom = Join-Path $RepoRoot 'pom.xml'
if (Test-Path -LiteralPath $pom -PathType Leaf) {
    Write-Host "   Detected: Maven"
    & mvn -f $pom test
    if ($LASTEXITCODE -eq 0) {
        Pass "Maven tests passed"
    } else {
        Fail "Maven tests failed"
    }
    $testsRan = $true
}

$goMod = Join-Path $RepoRoot 'go.mod'
if (Test-Path -LiteralPath $goMod -PathType Leaf) {
    Write-Host "   Detected: Go"
    Push-Location $RepoRoot
    try {
        & go test ./...
        if ($LASTEXITCODE -eq 0) {
            Pass "Go tests passed"
        } else {
            Fail "Go tests failed"
        }
    } finally {
        Pop-Location
    }
    $testsRan = $true
}

if (-not $testsRan) {
    Warn "No test runner detected. Add tests for your stack."
}

# 4. Summary
Write-Host ""
Write-Host "[4/4] Checking lessons.md exists..."
$lessonsFile = Join-Path $RepoRoot 'tasks/lessons.md'
if (Test-Path -LiteralPath $lessonsFile -PathType Leaf) {
    Pass "tasks/lessons.md exists"
} else {
    Warn "tasks/lessons.md missing. Run scripts/init.sh."
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "  Results: ✅ $($script:Passed) passed, ❌ $($script:Failed) failed, ⚠️  $($script:Warned) warnings"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ($script:Failed -gt 0) {
    Write-Host ""
    Write-Host "🚫 Verification FAILED. Fix the issues above before submitting."
    exit 1
}

if ($script:Warned -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Verification passed with warnings. Review before submitting."
    exit 0
}

Write-Host ""
Write-Host "🏯 All checks passed. Ready to submit."
