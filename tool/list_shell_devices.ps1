# list_shell_devices.ps1 - lista o que o Windows ve em "Este Computador"
# (drives + dispositivos MTP). Diagnostico para o push via MTP.
$ErrorActionPreference = 'Stop'
$shell = New-Object -ComObject Shell.Application
$computers = $shell.NameSpace(0x11)
foreach ($item in $computers.Items()) {
  Write-Output ("[{0}]" -f $item.Name)
}
