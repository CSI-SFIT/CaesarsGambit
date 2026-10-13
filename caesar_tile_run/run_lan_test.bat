@echo off
title Caesar's Gambit - 2-Player LAN Launcher
echo ======================================================
echo  CAESAR'S GAMBIT - 2-PLAYER DUAL INSTANCE LAN TEST
echo ======================================================

cd /d "%~dp0"
set "GODOT=C:\Users\Kavya\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe"

if not exist "%GODOT%" (
    set "GODOT=C:\Users\Kavya\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
)

echo [1/2] Launching Instance 1 (Player 1 - Host)...
start "" "%GODOT%" --max-fps 60 --position 40,40 --resolution 800x600

ping 127.0.0.1 -n 2 > nul

echo [2/2] Launching Instance 2 (Player 2 - Client)...
start "" "%GODOT%" --max-fps 60 --position 860,40 --resolution 800x600

echo.
echo ======================================================
echo  Both instances launched side-by-side!
echo  1. On Left Window: Click 'HOST LAN GAME'.
echo  2. On Right Window: Click 'JOIN GAME' (IP 127.0.0.1).
echo ======================================================
echo Window will close in 5 seconds...
ping 127.0.0.1 -n 6 > nul
