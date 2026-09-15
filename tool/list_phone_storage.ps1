# list_phone_storage.ps1 - mostra a arvore MTP do telefone (2 niveis) para
# descobrir onde a copia caiu e por que a deteccao falhou.
$ErrorActionPreference = 'Stop'
$shell = New-Object -ComObject Shell.Application
$computers = $shell.NameSpace(0x11)
foreach ($item in $computers.Items()) {
  if ($item.Type -match 'Local Disk|Disco local') { continue }
  Write-Output ("DEVICE: {0} (tipo: {1})" -f $item.Name, $item.Type)
  $folder = $item.GetFolder
  foreach ($child in $folder.Items()) {
    Write-Output ("  L1: {0} (tipo: {1})" -f $child.Name, $child.Type)
    $sub = $child.GetFolder
    $count = 0
    foreach ($f in $sub.Items()) {
      if ($count -ge 12) { Write-Output '    ...'; break }
      Write-Output ("    L2: {0} ({1} bytes)" -f $f.Name, $f.Size)
      $count++
    }
  }
}
