<#
.SYNOPSIS
  Render permits + commit + push to GitHub (which triggers Vercel deploy).

.DESCRIPTION
  1. Runs render-all.ps1 with -ClearCache -SkipOpen (fresh API pull, no browser).
  2. git add -A (respects .gitignore - private data + cross-ref stay local).
  3. Commits with an auto-generated timestamped message.
  4. git push to the current branch's upstream.
  Vercel auto-deploys on push.

.PARAMETER NoClearCache
  Skip cache-wipe and use cached data where available. Faster.

.PARAMETER Message
  Override the auto-generated commit message.

.PARAMETER DryRun
  Render + show what would be committed, but don't commit or push.

.EXAMPLE
  .\deploy.ps1
  Fresh API pull, render, commit, push.

.EXAMPLE
  .\deploy.ps1 -NoClearCache
  Render using cached data, commit, push.

.EXAMPLE
  .\deploy.ps1 -Message "Add restaurant pre-selection"
  Custom commit message.
#>

[CmdletBinding()]
param(
    [switch]$NoClearCache,
    [string]$Message,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $ScriptDir

Write-Host ""
Write-Host "=== Winnipeg Permit Suite - deploy ===" -ForegroundColor Cyan
Write-Host ""

# ---- 1. Render ----
# NOTE: splat a *hashtable* (not array) so switch parameters bind by name.
# @array splats positionally, which fails on [switch] params.
$renderArgs = @{ SkipOpen = $true }
if (-not $NoClearCache) { $renderArgs.ClearCache = $true }

& (Join-Path $ScriptDir 'render-all.ps1') @renderArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Render failed (exit $LASTEXITCODE). Aborting deploy."
    exit $LASTEXITCODE
}

# ---- 2. Stage ----
Write-Host ""
Write-Host "Staging changes..." -ForegroundColor Cyan
git add -A
if ($LASTEXITCODE -ne 0) { Write-Error "git add failed."; exit $LASTEXITCODE }

# ---- 3. Check if there's anything to commit ----
$pending = git status --porcelain
if (-not $pending) {
    Write-Host "Nothing to commit - working tree clean. Skipping push." -ForegroundColor Yellow
    exit 0
}

Write-Host "Pending changes:" -ForegroundColor DarkGray
git status --short

if ($DryRun) {
    Write-Host ""
    Write-Host "[DryRun] Would commit + push. Stopping here." -ForegroundColor Yellow
    exit 0
}

# ---- 4. Commit ----
if (-not $Message) {
    $Message = "Render update {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm')
}
Write-Host ""
Write-Host "Committing: $Message" -ForegroundColor Cyan
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed."; exit $LASTEXITCODE }

# ---- 5. Push ----
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Host ""
Write-Host "Pushing $branch to origin..." -ForegroundColor Cyan
git push
if ($LASTEXITCODE -ne 0) { Write-Error "git push failed."; exit $LASTEXITCODE }

Write-Host ""
Write-Host "Deploy pushed. Vercel will pick it up shortly." -ForegroundColor Green
Write-Host "Repo: https://github.com/jayschellenberg/winnipeg-permits" -ForegroundColor DarkGray
