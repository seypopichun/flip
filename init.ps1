# init.ps1 – Installer / Updater (re-runs safely every time)


# ── Settings ─────────────────────────────────────────────────────────────────
if ([string]::IsNullOrEmpty($rawUrl)) {
    $rawUrl = "https://raw.githubusercontent.com/seypopichun/flip/refs/heads/main/jumping.ps1"
}
$destination = "$env:APPDATA\jumping.ps1"
$taskName = "AutoJumping"
# ─────────────────────────────────────────────────────────────────────────────

# ── 1. Always download a fresh copy of jumping.ps1 ───────────────────────────
Write-Host "Downloading jumping.ps1 from $rawUrl ..."
Invoke-WebRequest -Uri $rawUrl -OutFile $destination -UseBasicParsing
Write-Host "Saved: $destination"
# ─────────────────────────────────────────────────────────────────────────────

# ── 2. Stop the old task if it is running ────────────────────────────────────
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask -and $existingTask.State -eq "Running") {
    Stop-ScheduledTask -TaskName $taskName
    Write-Host "Stopped running task '$taskName'."
}
# ─────────────────────────────────────────────────────────────────────────────

# ── 3. Register (or re-register) the scheduled task ──────────────────────────
#   jumping.ps1 now contains its own loop, so we just call it once.
$action = New-ScheduledTaskAction `
    -Execute  "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$destination`""

$triggerBoot = New-ScheduledTaskTrigger -AtStartup

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask `
    -TaskName $taskName `
    -Action   $action `
    -Trigger  $triggerBoot `
    -Settings $settings `
    -RunLevel Highest `
    -Force | Out-Null

Write-Host "Task '$taskName' registered (or updated)."
# ─────────────────────────────────────────────────────────────────────────────

# ── 4. Start the task immediately (no reboot needed) ─────────────────────────
Start-ScheduledTask -TaskName $taskName
Write-Host ""
Write-Host "Done! Task '$taskName' is running."
Write-Host "  jumping.ps1 starts once at boot and loops internally."
Write-Host "  Re-run init.ps1 any time to update jumping.ps1 and restart the task."
