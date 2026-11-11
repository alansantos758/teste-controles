@echo off
rem Coloca o WinUSB nos controles Xbox plugados (para calibrar no DriftGuard). Pede permissao de administrador.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0xbox-driver.ps1\" -Modo calibrar'"
