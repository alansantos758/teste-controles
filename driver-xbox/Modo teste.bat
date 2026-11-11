@echo off
rem Volta o driver padrao do Windows nos controles Xbox plugados (para o app de teste). Pede permissao de administrador.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0xbox-driver.ps1\" -Modo teste'"
