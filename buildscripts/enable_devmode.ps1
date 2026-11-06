param([switch]$Verbose)

$ErrorActionPreference = 'Stop'

function Get-Key([string]$Sid) { $reg = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($Sid, $false); if ($null -eq $reg) { return $null } else { $v = $reg.GetValue('AllowDevelopmentWithoutDevLicense'); $reg.Close(); return $v } }
function Set-Key([string]$Sid, [int]$Val) {
    $parent = 'Software\Microsoft\Windows\CurrentVersion'
    $k = $parent + '\AppModelUnlock'
    $reg = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($parent, $true)
    if ($null -eq $reg) { throw "cannot open $parent" }
    $reg.CreateSubKey('AppModelUnlock') | Out-Null
    $reg.Close()
    $w = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($k, $true)
    if ($null -eq $w) { throw "cannot open $k" }
    $w.SetValue('AllowDevelopmentWithoutDevLicense', [uint32]$Val, 'DWord')
    $w.Close()
}

$p = ('Software','Microsoft','Windows','CurrentVersion','AppModelUnlock') -join [char]92
$v = Get-Key $p
Write-Output "HKCU AllowDevelopmentWithoutDevLicense (before) = $v"
Set-Key $p 1
$v2 = Get-Key $p
Write-Output "HKCU AllowDevelopmentWithoutDevLicense (after)  = $v2"

$Ver = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).CurrentBuild
Write-Output "CurrentBuild = $Ver"

$vc = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools'
Write-Output "--- toolchain discovery ---"
Write-Output ("vcvarsall.bat       = " + (Test-Path (Join-Path $vc 'VC\Auxiliary\Build\vcvarsall.bat')))
Write-Output ("MSVC dir           = " + (Test-Path (Join-Path $vc 'VC\Tools\MSVC')))
$msvc = Get-ChildItem (Join-Path $vc 'VC\Tools\MSVC') -Directory | Sort-Object Name -Descending | Select-Object -First 1
if ($null -ne $msvc) {
    $bindir = Join-Path (Join-Path (Join-Path $vc 'VC\Tools\MSVC') $msvc.Name) 'bin\Hostx64\x64'
    Write-Output ("MSVC version        = " + $msvc.Name)
    Write-Output ("cl.exe             = " + (Test-Path (Join-Path $bindir 'cl.exe')))
    Write-Output ("cl.exe full path   = " + (Join-Path $bindir 'cl.exe'))
    $env:PATH = "$bindir;$env:PATH"
} else {
    Write-Output "MSVC dir: MISSING"
}
Write-Output ("cmake.exe          = " + (Test-Path (Join-Path $vc 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe')))
Write-Output ("ninja.exe          = " + (Test-Path (Join-Path $vc 'Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe')))
Write-Output ("WindowsSdkDir      = " + $env:WindowsSdkDir)
Write-Output ("WindowsSDKVersion  = " + $env:WindowsSDKVersion)

if ($Verbose) {
    Write-Output "--- current PATH (first 3) ---"
    $env:PATH.Split(';', [StringSplitOptions]::RemoveEmptyEntries)[0..2] | ForEach-Object { Write-Output "  $_" }
}

Write-Output "DONE"
