# jumping.ps1 – Started once at boot; loops internally every N seconds.

# ── Settings ─────────────────────────────────────────────────────────────────
$intervalSeconds = 60   # pause between iterations
# ─────────────────────────────────────────────────────────────────────────────

Add-Type -AssemblyName System.Windows.Forms

# ── One-time startup action (runs immediately on first launch) ────────────────
# Place any "run once at boot" code here:
# e.g. Write-Host "Script started at $(Get-Date)"
# ─────────────────────────────────────────────────────────────────────────────

# ── Periodic loop ─────────────────────────────────────────────────────────────
while ($true) {
    Start-Sleep -Seconds $intervalSeconds

    # ── Action performed every N seconds ─────────────────────────────────────
    [System.Windows.Forms.SendKeys]::SendWait("Hello world")
    # ─────────────────────────────────────────────────────────────────────────
}
