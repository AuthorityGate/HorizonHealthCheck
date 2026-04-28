# Start of Settings
# End of Settings

$Title          = "Hardware Health Sensors (red / yellow)"
$Header         = "[count] hardware sensor(s) reporting non-Green status"
$Comments       = "vSphere queries IPMI/CIM hardware sensors per host (PSU, fans, temperature, memory, storage). Red sensors usually correlate with HW alarms in vCenter. Reference: KB 2074907."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "96 vSphere Standalone"
$Severity       = "P1"
$Recommendation = "Inspect each red sensor in Host -> Monitor -> Hardware Health. For PSU/fan: schedule a maintenance-mode replacement. For 'memory' or 'CPU': open a vendor case before the host fails."

if (-not $Global:VCConnected) { return }

Get-VMHost -ErrorAction SilentlyContinue | ForEach-Object {
    $h = $_
    $hs = $h.ExtensionData.Runtime.HealthSystemRuntime
    if (-not $hs) { return }
    $sensors = @()
    $sensors += $hs.HardwareStatusInfo.MemoryStatusInfo
    $sensors += $hs.HardwareStatusInfo.CpuStatusInfo
    $sensors += $hs.HardwareStatusInfo.StorageStatusInfo
    $sensors += $hs.SystemHealthInfo.NumericSensorInfo
    foreach ($s in $sensors) {
        if (-not $s) { continue }
        $color = if ($s.Status) { $s.Status.Key } elseif ($s.HealthState) { $s.HealthState.Key } else { '' }
        if ($color -eq 'red' -or $color -eq 'yellow') {
            [pscustomobject]@{
                Host    = $h.Name
                Sensor  = $s.Name
                Status  = $color
                Summary = if ($s.Status) { $s.Status.Summary } else { '' }
            }
        }
    }
}

$TableFormat = @{ Status = { param($v,$row) if ($v -eq 'red') { 'bad' } elseif ($v -eq 'yellow') { 'warn' } else { '' } } }
