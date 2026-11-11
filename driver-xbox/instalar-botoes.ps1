# Registra o link "ctrltest-driver:" para o usuário atual, para os botões do app de teste abrirem os modos de driver.
# Rodar uma vez por PC (não precisa de administrador). Se a pasta mudar de lugar, rode de novo.
$chave = 'HKCU:\Software\Classes\ctrltest-driver'
$abrir = Join-Path $PSScriptRoot 'abrir-modo.ps1'

New-Item -Path "$chave\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path $chave -Name '(default)' -Value 'URL:Driver Xbox (teste de controles)'
Set-ItemProperty -Path $chave -Name 'URL Protocol' -Value ''
Set-ItemProperty -Path "$chave\shell\open\command" -Name '(default)' `
  -Value "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$abrir`" `"%1`""

Write-Host 'Botões do app ativados neste PC.' -ForegroundColor Green
Read-Host 'Enter para fechar' | Out-Null
