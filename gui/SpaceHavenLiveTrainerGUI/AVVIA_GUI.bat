@echo off
title Space Haven Live Trainer GUI v0.7.2
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0SpaceHavenLiveTrainerGUI.ps1"
if errorlevel 1 (
  echo.
  echo Errore durante l'avvio della GUI.
  pause
)
