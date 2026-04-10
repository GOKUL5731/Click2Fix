Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ports = @(8080, 8001)
$connections = Get-NetTCPConnection -LocalPort $ports -ErrorAction SilentlyContinue |
  Where-Object { $_.OwningProcess -ne 0 } |
  Select-Object -ExpandProperty OwningProcess -Unique

foreach ($processId in $connections) {
  Write-Host "Stopping process $processId"
  Stop-Process -Id $processId -Force
}

Write-Host 'Click2Fix local services stopped.'

