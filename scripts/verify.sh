#!/usr/bin/env bash
# Copilot Agents Dojo — Pre-PR Verification Wrapper
# Runs a series of checks before a PR is considered ready.
#
# Usage: bash scripts/verify.sh
#
# Checks:
#   1. tasks/todo.md has a plan (not just the template)
#   2. No uncommitted changes (clean working tree)
#   3. Tests pass (auto-detects test runner)
#   4. Summary output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

PASSED=0
FAILED=0
WARNED=0

pass() { echo "  ✅ $1"; PASSED=$((PASSED + 1)); }
fail() { echo "  ❌ $1"; FAILED=$((FAILED + 1)); }
warn() { echo "  ⚠️  $1"; WARNED=$((WARNED + 1)); }

echo "🥋 Copilot Agents Dojo — Pre-PR Verification"
echo ""

# 1. Check for a plan in todo.md
echo "[1/4] Checking tasks/todo.md for a plan..."
TODO_FILE="$REPO_ROOT/tasks/todo.md"
if [ ! -f "$TODO_FILE" ]; then
  fail "tasks/todo.md not found. Create a plan before submitting."
elif grep -qE '\- \[x\]|\- \[ \]' "$TODO_FILE" 2>/dev/null && \
     ! grep -q 'Step 1' "$TODO_FILE" 2>/dev/null; then
  pass "Plan found in tasks/todo.md"
else
  warn "tasks/todo.md looks like the default template. Write a real plan."
fi

# 2. Check for uncommitted changes
echo "[2/4] Checking for uncommitted changes..."
cd "$REPO_ROOT"
if git diff --quiet HEAD 2>/dev/null && git diff --cached --quiet HEAD 2>/dev/null; then
  pass "Working tree is clean"
else
  warn "Uncommitted changes detected. Commit or stash before PR."
fi

# 3. Auto-detect and run tests
echo "[3/4] Running tests..."
TESTS_RAN=false

if [ -f "$REPO_ROOT/package.json" ]; then
  if grep -q '"test"' "$REPO_ROOT/package.json" 2>/dev/null; then
    echo "   Detected: npm test"
    if npm test --prefix "$REPO_ROOT" 2>&1; then
      pass "npm tests passed"
    else
      fail "npm tests failed"
    fi
    TESTS_RAN=true
  fi
fi

if [ -f "$REPO_ROOT/pyproject.toml" ] || [ -f "$REPO_ROOT/setup.py" ] || [ -f "$REPO_ROOT/pytest.ini" ]; then
  echo "   Detected: pytest"
  if python -m pytest "$REPO_ROOT" 2>&1; then
    pass "pytest passed"
  else
    fail "pytest failed"
  fi
  TESTS_RAN=true
fi

if [ -f "$REPO_ROOT/pom.xml" ]; then
  echo "   Detected: Maven"
  if mvn -f "$REPO_ROOT/pom.xml" test 2>&1; then
    pass "Maven tests passed"
  else
    fail "Maven tests failed"
  fi
  TESTS_RAN=true
fi

if [ -f "$REPO_ROOT/go.mod" ]; then
  echo "   Detected: Go"
  if (cd "$REPO_ROOT" && go test ./... 2>&1); then
    pass "Go tests passed"
  else
    fail "Go tests failed"
  fi
  TESTS_RAN=true
fi

if [ "$TESTS_RAN" = false ]; then
  warn "No test runner detected. Add tests for your stack."
fi

# 4. Summary
echo ""
echo "[4/4] Checking lessons.md exists..."
if [ -f "$REPO_ROOT/tasks/lessons.md" ]; then
  pass "tasks/lessons.md exists"
else
  warn "tasks/lessons.md missing. Run scripts/init.sh."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Results: ✅ $PASSED passed, ❌ $FAILED failed, ⚠️  $WARNED warnings"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "🚫 Verification FAILED. Fix the issues above before submitting."
  exit 1
fi

if [ "$WARNED" -gt 0 ]; then
  echo ""
  echo "⚠️  Verification passed with warnings. Review before submitting."
  exit 0
fi

echo ""
echo "🏯 All checks passed. Ready to submit."
