# Recebe o link "ctrltest-driver:<modo>" vindo do app de teste e abre o xbox-driver.ps1 como administrador.
# Só aceita os modos conhecidos: qualquer outro texto no link é ignorado.
param([string]$Url)

if ($Url -notmatch '^ctrltest-driver:(?://)?(calibrar|teste)/?$') { exit 1 }
$script = Join-Path $PSScriptRoot 'xbox-driver.ps1'
Start-Process powershell -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$script`"", '-Modo', $Matches[1])
