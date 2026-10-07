# Caesar's Gambit - 2-Player Dual Launcher
$proj = $PSScriptRoot
$godot = "C:\Users\Kavya\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe"
if (-not (Test-Path $godot)) {
    $godot = "C:\Users\Kavya\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
}

Write-Host "Launching Instance 1 (Host - Left)..." -ForegroundColor Yellow
Start-Process $godot -ArgumentList "--path `"$proj`" --max-fps 60 --position 40,40 --resolution 800x600"

Start-Sleep -Seconds 1

Write-Host "Launching Instance 2 (Client - Right)..." -ForegroundColor Cyan
Start-Process $godot -ArgumentList "--path `"$proj`" --max-fps 60 --position 860,40 --resolution 800x600"

Write-Host "`nBoth instances launched! Host on left, Join on right (127.0.0.1)." -ForegroundColor Green
