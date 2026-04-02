#!/usr/bin/env pwsh
# Copilot Agents Dojo - Initialization Script
# Scaffolds the tasks/ directory with todo.md and lessons.md templates.
# Run this after cloning the repo or when starting a fresh project.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
$RepoRoot = Split-Path -Parent $ScriptDir
$TasksDir = Join-Path $RepoRoot 'tasks'

Write-Host "🥋 Copilot Agents Dojo - Initializing..."

# Create tasks directory if missing
if (-not (Test-Path -LiteralPath $TasksDir -PathType Container)) {
    New-Item -ItemType Directory -Path $TasksDir -Force | Out-Null
    Write-Host "  ✅ Created tasks/ directory"
} else {
    Write-Host "  ℹ️  tasks/ directory already exists"
}

# Create todo.md if missing
$TodoFile = Join-Path $TasksDir 'todo.md'
if (-not (Test-Path -LiteralPath $TodoFile -PathType Leaf)) {
    @'
# Task Plan

> Write your plan here before starting any non-trivial work.
> Mark items complete as you go. Add a review section when done.

## Current Task
<!-- Describe the task/goal here -->

## Plan
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## Review
<!-- After completion: summarize what was done, what was verified, any open items -->
'@ | Set-Content -LiteralPath $TodoFile -Encoding UTF8
    Write-Host "  ✅ Created tasks/todo.md"
} else {
    Write-Host "  ℹ️  tasks/todo.md already exists - skipping"
}

# Create lessons.md if missing
$LessonsFile = Join-Path $TasksDir 'lessons.md'
if (-not (Test-Path -LiteralPath $LessonsFile -PathType Leaf)) {
    @'
# Lessons Learned

> This file is the agent's memory. After every correction, log the lesson here.
> Review this file at the start of every session.
> If a pattern appears 3+ times, propose a rule update to skills.md.

## Lesson Log

## Metrics

| Metric | Value |
|--------|-------|
| Total lessons logged | 0 |
| Patterns amended to skills | 0 |
| Recurring patterns (3+) | 0 |
| Sessions since last new lesson | 0 |
'@ | Set-Content -LiteralPath $LessonsFile -Encoding UTF8
    Write-Host "  ✅ Created tasks/lessons.md"
} else {
    Write-Host "  ℹ️  tasks/lessons.md already exists - skipping"
}

Write-Host ""
Write-Host "🏯 Dojo initialized. Your agents are ready to train."
Write-Host "   Next: open skills.md and start your first session."
