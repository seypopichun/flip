# init.ps1 – Installer / Updater (re-runs safely every time)
# Run this script once (manually or via another mechanism) to install/update
# the AutoJumping scheduled task.  After that, jumping.ps1 runs automatically
# at every boot AND every time the PC wakes from sleep.

# ── Settings ─────────────────────────────────────────────────────────────────
if ([string]::IsNullOrEmpty($rawUrl)) {
    $rawUrl = "https://raw.githubusercontent.com/seypopichun/flip/refs/heads/main/jumping.ps1"
}

# Destination folder – must match exactly what the scheduled task will call
$destDir  = "$env:APPDATA\Windows"
$destFile = "$destDir\jumping.ps1"
$taskName = "AutoJumping"
# ─────────────────────────────────────────────────────────────────────────────

# ── 0. Make sure destination folder exists ────────────────────────────────────
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Write-Host "Created folder: $destDir"
}
# ─────────────────────────────────────────────────────────────────────────────

# ── 1. Download a fresh copy of jumping.ps1 ───────────────────────────────────
Write-Host "Downloading jumping.ps1 from $rawUrl ..."
try {
    Invoke-WebRequest -Uri $rawUrl -OutFile $destFile -UseBasicParsing -ErrorAction Stop
    Write-Host "Saved: $destFile"
} catch {
    Write-Warning "Download failed: $_"
    Write-Warning "Will use existing copy at $destFile (if any)."
}
# ─────────────────────────────────────────────────────────────────────────────

# ── 2. Stop the old task instance if it is currently running ─────────────────
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask -and $existingTask.State -eq "Running") {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Write-Host "Stopped running task '$taskName'."
    Start-Sleep -Seconds 2
}
# ─────────────────────────────────────────────────────────────────────────────

# ── 3. Build task components ──────────────────────────────────────────────────
$action = New-ScheduledTaskAction `
    -Execute  "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$destFile`""

# Trigger 1: at every system startup (with a short delay so network is up)
$triggerBoot = New-ScheduledTaskTrigger -AtStartup
$triggerBoot.Delay = "PT30S"   # wait 30 seconds after boot before starting

# Trigger 2: when the PC resumes from sleep / hibernation
# (uses a raw CIM instance because New-ScheduledTaskTrigger has no -OnEvent shortcut for this)
$triggerWake = Get-CimClass -ClassName MSFT_TaskSessionStateChangeTrigger `
                             -Namespace "Root/Microsoft/Windows/TaskScheduler" |
               New-CimInstance -ClientOnly -Property @{
                   StateChange = 8          # 8 = TASK_SESSION_RESUME (wake from sleep)
                   Enabled     = $true
               }

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -WakeToRun `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

# Principal: S4U = runs as the current user WITHOUT needing an interactive session
# (works even before the user logs in on next boot, and on wake from sleep)
$principal = New-ScheduledTaskPrincipal `
    -UserId    $env:USERNAME `
    -LogonType S4U `
    -RunLevel  Highest
# ─────────────────────────────────────────────────────────────────────────────

# ── 4. Register (or replace) the task ────────────────────────────────────────
Register-ScheduledTask `
    -TaskName  $taskName `
    -Action    $action `
    -Trigger   @($triggerBoot, $triggerWake) `
    -Settings  $settings `
    -Principal $principal `
    -Force | Out-Null

Write-Host ""
Write-Host "Task '$taskName' registered (or updated) successfully."
Write-Host "  Triggers: boot (after 30s delay) + wake from sleep"
Write-Host "  LogonType: S4U  (runs without interactive session)"
Write-Host "  Script: $destFile"
# ─────────────────────────────────────────────────────────────────────────────

# ── 5. Start the task immediately (no reboot needed) ─────────────────────────
Start-ScheduledTask -TaskName $taskName
Write-Host ""
Write-Host "Done! Task '$taskName' is now running."
Write-Host "  Re-run init.ps1 any time to update jumping.ps1 and restart the task."
