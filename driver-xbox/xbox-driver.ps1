# Alterna o driver dos controles Xbox plugados no USB entre o padrão do Windows (modo teste)
# e o WinUSB do Zadig (modo calibrar, usado pelo DriftGuard).
# Usa UpdateDriverForPlugAndPlayDevices com INSTALLFLAG_FORCE: troca o driver sem apagar nenhum pacote,
# então o WinUSB do Zadig continua no Windows para a próxima calibração.
param(
  [Parameter(Mandatory)][ValidateSet('calibrar', 'teste', 'listar')][string]$Modo
)

$ErrorActionPreference = 'Stop'

# Receptores e adaptadores sem fio da Microsoft: nunca mexer neles
$IGNORAR_PIDS = @('0719', '0291', '02A9', '02E6', '02FE')
$INF_PADRAO = @("$env:windir\INF\dc1-controller.inf", "$env:windir\INF\xusb22.inf")
$INSTALLFLAG_FORCE = 1

function Get-ControlesXbox {
  Get-PnpDevice -PresentOnly |
    Where-Object { $_.InstanceId -match '^USB\\VID_045E&PID_([0-9A-F]{4})\\' -and $IGNORAR_PIDS -notcontains $Matches[1] } |
    Where-Object { $_.Class -in @('XboxComposite', 'XnaComposite', 'USBDevice') } |
    ForEach-Object {
      [pscustomobject]@{
        Nome      = $_.FriendlyName
        HardwareId = ($_.InstanceId -split '\\')[0..1] -join '\'
        Driver    = (Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName DEVPKEY_Device_Service).Data
      }
    }
}

function Find-InfWinUsb([string]$hardwareId) {
  # Pacote gerado pelo Zadig (libwdi) para este modelo, já copiado para o repositório de drivers.
  # O Zadig escreve o ID como DeviceID = "VID_xxxx&PID_yyyy" e monta "USB\%DeviceID%", então busca só a parte VID/PID.
  $vidPid = ($hardwareId -split '\\')[1]
  Get-ChildItem "$env:windir\INF\oem*.inf" |
    Where-Object { (Select-String -Path $_.FullName -SimpleMatch $vidPid -Quiet) -and (Select-String -Path $_.FullName -SimpleMatch 'libwdi' -Quiet) } |
    Select-Object -First 1 -ExpandProperty FullName
}

function Find-InfPadrao([string]$hardwareId) {
  $INF_PADRAO | Where-Object { (Test-Path $_) -and (Select-String -Path $_ -SimpleMatch $hardwareId -Quiet) } | Select-Object -First 1
}

function Set-Driver([string]$hardwareId, [string]$inf) {
  if (-not ('NewDev' -as [type])) {
    Add-Type @'
using System; using System.Runtime.InteropServices;
public static class NewDev {
  [DllImport("newdev.dll", SetLastError = true, CharSet = CharSet.Unicode)]
  public static extern bool UpdateDriverForPlugAndPlayDevices(IntPtr hwnd, string hardwareId, string infPath, uint flags, out bool reboot);
}
'@
  }
  $reboot = $false
  $ok = [NewDev]::UpdateDriverForPlugAndPlayDevices([IntPtr]::Zero, $hardwareId, $inf, $INSTALLFLAG_FORCE, [ref]$reboot)
  if (-not $ok) { throw ('falha ao trocar o driver (erro 0x{0:X8})' -f [Runtime.InteropServices.Marshal]::GetLastWin32Error()) }
  $reboot
}

function Invoke-Modo([string]$modo) {
  $controles = @(Get-ControlesXbox)
  if (-not $controles.Count) { Write-Host 'Nenhum controle Xbox encontrado no USB. Plugue o cabo e rode de novo.' -ForegroundColor Yellow; return }

  foreach ($c in $controles) {
    $winusb = Find-InfWinUsb $c.HardwareId
    $padrao = Find-InfPadrao $c.HardwareId
    Write-Host ("`n{0}  [{1}]  driver atual: {2}" -f $c.Nome, $c.HardwareId, $c.Driver)
    if ($modo -eq 'listar') { Write-Host "  WinUSB do Zadig: $(if ($winusb) { $winusb } else { 'não instalado' })"; Write-Host "  Driver padrão:   $padrao"; continue }

    $alvo = if ($modo -eq 'calibrar') { $winusb } else { $padrao }
    if (-not $alvo) {
      if ($modo -eq 'calibrar') { Write-Host '  Este modelo ainda não tem o WinUSB neste PC. Rode o Zadig UMA vez para ele (sem apagar o driver depois).' -ForegroundColor Yellow }
      else { Write-Host '  Driver padrão do Xbox não encontrado para este modelo. Use o Gerenciador de Dispositivos.' -ForegroundColor Yellow }
      continue
    }
    try {
      $reboot = Set-Driver $c.HardwareId $alvo
      $msg = if ($modo -eq 'calibrar') { '  OK: pronto para o DriftGuard.' } else { '  OK: driver padrão de volta. Pode medir no app de teste.' }
      Write-Host $msg -ForegroundColor Green
      if ($reboot) { Write-Host '  O Windows pediu para reiniciar o PC.' -ForegroundColor Yellow }
    } catch { Write-Host "  ERRO: $($_.Exception.Message)" -ForegroundColor Red }
  }
}

Invoke-Modo $Modo
if ($Modo -ne 'listar') { Read-Host "`nEnter para fechar" | Out-Null }
