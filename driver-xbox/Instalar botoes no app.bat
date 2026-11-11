@echo off
rem Ativa neste PC os botoes "Modo calibrar" e "Modo teste" do app de teste. Rodar uma vez.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar-botoes.ps1"
