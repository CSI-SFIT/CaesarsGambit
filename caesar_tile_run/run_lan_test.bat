@echo off
echo ======================================================
echo  CAESAR'S GAMBIT - 2-PLAYER DUAL INSTANCE LAN TEST
echo ======================================================
echo Launching Instance 1 (Host - Centurion Caesar)...
start "Player 1 - Host" "C:\Users\Kavya\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --path "%~dp0" --position 50,50 --resolution 800x600

timeout /t 2 /nobreak > nul

echo Launching Instance 2 (Player 2 - Centurion)...
start "Player 2 - Client" "C:\Users\Kavya\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --path "%~dp0" --position 880,50 --resolution 800x600

echo Both instances launched! In instance 1 click 'HOST LAN GAME'. In instance 2 click 'JOIN GAME' with IP 127.0.0.1.
