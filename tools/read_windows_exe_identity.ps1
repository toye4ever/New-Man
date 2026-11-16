[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$DebugExecutable,
  [Parameter(Mandatory = $true)][string]$ReleaseExecutable,
  [Parameter(Mandatory = $true)][string]$Report
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Read-Identity([string]$Executable) {
  if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
    throw 'Expected compiled executable is missing.'
  }
  $item = Get-Item -LiteralPath $Executable
  if ($item.Extension -ne '.exe') { throw 'Expected an EXE file.' }
  # Read VERSIONINFO only. Never execute the binary or resolve app storage.
  $info = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($item.FullName)
  return [ordered]@{
    company = $info.CompanyName
    product = $info.ProductName
    description = $info.FileDescription
    internalName = $info.InternalName
    originalFilename = $info.OriginalFilename
    fileVersion = $info.FileVersion
    productVersion = $info.ProductVersion
    debug = $info.IsDebug
  }
}
$identity = [ordered]@{
  debug = Read-Identity $DebugExecutable
  release = Read-Identity $ReleaseExecutable
}
$identity | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $Report -Encoding utf8NoBOM
