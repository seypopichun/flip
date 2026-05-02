# jumping.ps1 – Worker script (runs continuously in background)
# Managed by the "AutoJumping" scheduled task created by init.ps1.
# Do NOT run this file directly unless for testing.

Add-Type -AssemblyName System.Windows.Forms

$intervalSeconds = 60   # pause between iterations
# ─────────────────────────────────────────────────────────────────────────────

# ── One-time startup action (runs immediately on first launch) ────────────────
# Place any "run once at boot / wake" code here:
# e.g. Write-Host "Script started at $(Get-Date)"
# ─────────────────────────────────────────────────────────────────────────────

# ── Periodic loop ─────────────────────────────────────────────────────────────
while ($true) {
    Start-Sleep -Seconds $intervalSeconds

    # ── Action performed every N seconds ─────────────────────────────────────
    notepad.exe
    #[System.Windows.Forms.SendKeys]::SendWait("Hello world")
    # ─────────────────────────────────────────────────────────────────────────
}
