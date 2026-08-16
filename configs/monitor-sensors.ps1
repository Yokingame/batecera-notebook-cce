# Monitor de sensores do PC via LibreHardwareMonitor (net472)
# Roda como ADMIN (MSR/SuperIO). Uso: powershell -NoProfile -ExecutionPolicy Bypass -File monitor-sensors.ps1
$ErrorActionPreference = "SilentlyContinue"

$dll = "C:\PC-Monitor\LibreHardwareMonitorLib.dll"
[System.Reflection.Assembly]::LoadFrom($dll) | Out-Null

$hw = New-Object LibreHardwareMonitor.Hardware.Computer
$hw.IsCpuEnabled = $true
$hw.IsMotherboardEnabled = $true
$hw.IsGpuEnabled = $false
$hw.IsMemoryEnabled = $false
$hw.IsStorageEnabled = $true
$hw.Open()
Start-Sleep -Seconds 5

$temps = @()
$loads = @()

function Scan-Sensors($hardware) {
    foreach ($sensor in $hardware.Sensors) {
        if ($sensor.SensorType -eq [LibreHardwareMonitor.Hardware.SensorType]::Temperature -and $sensor.Value) {
            $script:temps += [PSCustomObject]@{ HW = $hardware.HardwareType; Name = $sensor.Name; Value = $sensor.Value }
        }
        if ($sensor.SensorType -eq [LibreHardwareMonitor.Hardware.SensorType]::Load -and $sensor.Value) {
            $script:loads += "$($sensor.Name) = $([math]::Round($sensor.Value,0))%"
        }
    }
    foreach ($sub in $hardware.SubHardware) {
        $sub.Update()
        Scan-Sensors $sub
    }
}
foreach ($hardware in $hw.Hardware) {
    $hardware.Update()
    Scan-Sensors $hardware
}

$cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
if (-not $cpuLoad) {
    $cpuLoad = (($loads | Where-Object { $_ -match '^CPU Total' } | Select-Object -First 1) -replace '.*= (\d+)%.*', '$1')
}
if (-not $cpuLoad) { $cpuLoad = '--' }
$ram = Get-CimInstance Win32_OperatingSystem
$total = [math]::Round($ram.TotalVisibleMemorySize/1MB,1)
$free  = [math]::Round($ram.FreePhysicalMemory/1MB,1)
$used  = $total - $free
$pct   = [math]::Round($used/$total*100,0)

# CPU: procura "Core Max" ou "CPU Package"
$cpuMax = $temps | Where-Object { $_.HW.ToString() -eq 'Cpu' -and $_.Name -match 'Max' } | Select-Object -First 1
$cpuPkg = $temps | Where-Object { $_.HW.ToString() -eq 'Cpu' -and $_.Name -match 'Package' } | Select-Object -First 1
# Disco mais quente
$diskHot = $temps | Where-Object { $_.HW.ToString() -eq 'Storage' } | Sort-Object Value -Descending | Select-Object -First 1

Write-Host "=== PC 192.168.1.2 (Xeon E5-2690 v4) ==="
Write-Host ("CPU: {0}%  Load" -f $cpuLoad)
Write-Host ("CPU Temp: {0} C (pkg {1} C)" -f $(if ($cpuMax) {[math]::Round($cpuMax.Value,0)} else {'--'}), $(if ($cpuPkg) {[math]::Round($cpuPkg.Value,0)} else {'--'}))
Write-Host ("RAM: {0} / {1} GB ({2}%)" -f $used, $total, $pct)
if ($diskHot) { Write-Host ("DISCO+QUENTE: {0} = {1} C" -f $diskHot.Name, [math]::Round($diskHot.Value,0)) }

$hw.Close()