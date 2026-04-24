<#
.SYNOPSIS
  Renders both Winnipeg permit reports and opens the resulting HTML files.

.DESCRIPTION
  Runs `quarto render` on WpgNonResPermits.qmd and WpgMultiResPermits.qmd
  in sequence, then opens the two HTML outputs in the default browser.
  Optionally clears the .cache\ folder first to force fresh API pulls.

.PARAMETER ClearCache
  Delete all cached RDS files in .cache\ before rendering. Use this when
  you want a hard refresh from the Winnipeg Open Data API.

.PARAMETER SkipOpen
  Render only — don't open the HTML files afterward.

.EXAMPLE
  .\render-all.ps1
  Normal render using caches where available.

.EXAMPLE
  .\render-all.ps1 -ClearCache
  Force fresh API pulls, then render.

.EXAMPLE
  .\render-all.ps1 -SkipOpen
  Render without opening the browser.
#>

[CmdletBinding()]
param(
    [switch]$ClearCache,
    [switch]$SkipOpen
)

$ErrorActionPreference = 'Stop'

# Pin working directory to the script's folder so it works from any shell
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $ScriptDir

Write-Host ""
Write-Host "=== Winnipeg Permit Suite - render-all ===" -ForegroundColor Cyan
Write-Host "Working directory: $ScriptDir"
Write-Host ""

# ---- Optional cache wipe ----
if ($ClearCache) {
    $cacheDir = Join-Path $ScriptDir '.cache'
    if (Test-Path -LiteralPath $cacheDir) {
        Write-Host "Clearing cache: $cacheDir" -ForegroundColor Yellow
        Get-ChildItem -LiteralPath $cacheDir -File | Remove-Item -Force
    } else {
        Write-Host "No .cache folder found - skipping clear." -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ---- Targets (render in order) ----
$targets = @(
    'WpgNonResPermits.qmd',
    'WpgMultiResPermits.qmd'
)

$rendered = @()
foreach ($qmd in $targets) {
    $qmdPath = Join-Path $ScriptDir $qmd
    if (-not (Test-Path -LiteralPath $qmdPath)) {
        Write-Warning "Skipping $qmd - file not found."
        continue
    }

    $stamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$stamp] Rendering $qmd ..." -ForegroundColor Cyan

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & quarto render $qmd
    $sw.Stop()

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Error "quarto render failed for $qmd (exit $LASTEXITCODE). Stopping."
        exit $LASTEXITCODE
    }

    $html = [System.IO.Path]::ChangeExtension($qmdPath, '.html')
    if (Test-Path -LiteralPath $html) {
        $sizeMB = [math]::Round((Get-Item -LiteralPath $html).Length / 1MB, 2)
        Write-Host ("    OK  -> {0} ({1} MB, {2:N1}s)" -f (Split-Path -Leaf $html), $sizeMB, $sw.Elapsed.TotalSeconds) -ForegroundColor Green
        $rendered += $html
    } else {
        Write-Warning "    Render reported success but output HTML not found for $qmd"
    }
    Write-Host ""
}

# ---- Open outputs ----
if (-not $SkipOpen -and $rendered.Count -gt 0) {
    Write-Host "Opening rendered HTML..." -ForegroundColor Cyan
    foreach ($html in $rendered) {
        Start-Process $html
    }
}

Write-Host ""
Write-Host "Done. Rendered $($rendered.Count) of $($targets.Count) reports." -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: the cross-reference report (WpgComPermitSalesCrossRef.qmd) is not" -ForegroundColor DarkGray
Write-Host "      rendered here because it depends on the permits CSV export, which" -ForegroundColor DarkGray
Write-Host "      must be re-downloaded manually from the permits HTML first." -ForegroundColor DarkGray
