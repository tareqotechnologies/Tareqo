# find_apk_on_phone.ps1 - procura APKs na arvore MTP (recursivo, ate 4 niveis).
$ErrorActionPreference = 'Stop'
$shell = New-Object -ComObject Shell.Application
$computers = $shell.NameSpace(0x11)

function Walk($folder, $path, $depth) {
  if ($depth -gt 4) { return }
  foreach ($f in $folder.Items()) {
    $p = "$path\$($f.Name)"
    if ($f.IsFolder) {
      Walk $f.GetFolder $p ($depth + 1)
    } elseif ($f.Name -match '\.apk$') {
      Write-Output ("FOUND: {0} ({1:N0} bytes)" -f $p, $f.Size)
    }
  }
}

foreach ($item in $computers.Items()) {
  if ($item.Type -match 'Local Disk|Disco local') { continue }
  Write-Output ("DEVICE: {0}" -f $item.Name)
  Walk $item.GetFolder $item.Name 0
}
