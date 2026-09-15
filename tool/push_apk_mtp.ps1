# push_apk_mtp.ps1 - copia o APK para a memoria do Android via MTP (Shell COM).
#
# Por que existe: o cabo USB do SM-A055F esta sem ADB (depuracao USB
# desligada) - so o modo MTP (Transferencia de ficheiros) fica visivel.
# O MTP nao monta letra de drive no Windows: a copia e feita pela API do
# Explorer (Shell.Application COM), igual a arrastar no Explorador.
#
# Uso:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tool/push_apk_mtp.ps1
#
# Pre-requisitos NO TELEFONE: desbloqueado (tela acesa) e modo USB
# "Transferencia de ficheiros / MTP" (a notificacao de USB permite trocar).
$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot '..\build\app\outputs\flutter-apk\app-prod-release.apk'
$src = (Resolve-Path $src).Path
if (-not (Test-Path $src)) {
  Write-Output "ERRO: APK nao encontrado: $src"
  exit 1
}
$apkName = Split-Path $src -Leaf
$apkSize = (Get-Item $src).Length

Write-Output ("APK: {0} ({1:N0} bytes)" -f $apkName, $apkSize)

$shell = New-Object -ComObject Shell.Application
$computers = $shell.NameSpace(0x11)  # ssfDRIVES = "Este Computador"

# 1. Localiza o dispositivo MTP: qualquer item de "Este Computador" cujo
# tipo nao seja disco local (o nome e personalizado pelo usuario, ex. "Dom's A73").
$phone = $null
foreach ($item in $computers.Items()) {
  if ($item.Type -notmatch 'Local Disk|Disco local') { $phone = $item; break }
}
if (-not $phone) {
  Write-Output 'ERRO: nenhum dispositivo MTP encontrado. Desbloqueie o telefone, confirme o modo USB "Transferencia de ficheiros" e tente de novo.'
  exit 2
}
Write-Output ("Telefone: {0}" -f $phone.Name)

$phoneFolder = $phone.GetFolder

# 2. Desce um nivel: "Armazenamento interno" / "Internal storage" / "Cartao SD".
$storage = $null
foreach ($child in $phoneFolder.Items()) {
  if ($child.Name -match 'Armazenamento|Internal|storage|Cart') { $storage = $child; break }
}
$storageFolder = if ($storage) { $storage.GetFolder } else { $phoneFolder }
$storageName = if ($storage) { $storage.Name } else { $phone.Name }
Write-Output ("Destino: {0} (raiz do armazenamento)" -f $storageName)

# 3. Copia (0x10 = "sim a tudo"; 0x2 = sem dialogo de progresso).
$storageFolder.CopyHere($src, 0x12)

# 4. Espera a copia terminar (ate 5 min), comparando o tamanho no destino.
$deadline = (Get-Date).AddMinutes(5)
$copied = $null
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 3
  $copied = $null
  foreach ($f in $storageFolder.Items()) {
    if ($f.Name -eq $apkName) { $copied = $f; break }
  }
  if ($copied -and $copied.Size -eq $apkSize) { break }
}

if ($copied -and $copied.Size -eq $apkSize) {
  Write-Output ("OK: {0} enviado para {1}. Abra 'Meus ficheiros' no telefone e toque no APK para instalar." -f $apkName, $storageName)
  exit 0
}
Write-Output 'ERRO: a copia nao terminou a tempo (tela do telefone bloqueada? cabo solto?). Rode de novo.'
exit 3
