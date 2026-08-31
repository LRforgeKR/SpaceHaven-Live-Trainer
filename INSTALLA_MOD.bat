@echo off
title Space Haven Live Trainer - Installer
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0installer\Install-Mod.ps1"
set ERR=%ERRORLEVEL%
echo.
if not "%ERR%"=="0" (
  echo Installazione non completata.
) else (
  echo Installazione completata.
)
pause
exit /b %ERR%
