# Start of Settings
# End of Settings

$Title          = 'ESXi Memory Reliability'
$Header         = '[count] host(s) reporting memory reliability concerns'
$Comments       = 'Reference: KB 1003322. ESXi retires bad memory pages and exposes per-DIMM status via the hardware health system. High retire counts or non-Green memory sensors indicate failing DIMMs that need replacement.'
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.1
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = "Replace the affected DIMM during the next maintenance window. Use the host's vendor BMC (iDRAC/iLO/CIMC) to identify the physical slot from the sensor name, then schedule maintenance-mode + DIMM swap."

if (-not $Global:VCConnected) { return }

foreach ($h in (Get-VMHost -ErrorAction SilentlyContinue)) {
    if ($h.ConnectionState -ne 'Connected') {
        # Skip - we cannot query disconnected hosts.
        continue
    }
    try {
        $memInfo = $h.ExtensionData.Runtime.HealthSystemRuntime.HardwareStatusInfo.MemoryStatusInfo
    } catch {
        $memInfo = $null
    }

    # Each MemoryStatusInfo entry is a DIMM (or memory bank); Status.Key is one
    # of green / yellow / red / unknown. Anything other than green is reported.
    if ($memInfo) {
        foreach ($m in $memInfo) {
            $statusKey = if ($m.Status -and $m.Status.Key) { $m.Status.Key } else { 'unknown' }
            if ($statusKey -ne 'green') {
                [pscustomobject]@{
                    Host       = $h.Name
                    Cluster    = $h.Parent.Name
                    DIMM       = $m.Name
                    Status     = $statusKey
                    StatusText = if ($m.Status -and $m.Status.Summary) { $m.Status.Summary } else { '' }
                    HostBuild  = "$($h.Version) build $($h.Build)"
                    Action     = 'Identify DIMM slot via vendor BMC; schedule maintenance + replace.'
                }
            }
        }
    }

    # Also surface any host whose CIM Memory health overall is red/yellow even
    # when no per-DIMM detail is available.
    try {
        $overall = $h.ExtensionData.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo |
            Where-Object { $_.SensorType -eq 'memory' -and $_.HealthState -and $_.HealthState.Key -ne 'green' }
        foreach ($s in $overall) {
            [pscustomobject]@{
                Host       = $h.Name
                Cluster    = $h.Parent.Name
                DIMM       = $s.Name
                Status     = $s.HealthState.Key
                StatusText = $s.HealthState.Summary
                HostBuild  = "$($h.Version) build $($h.Build)"
                Action     = 'Investigate ECC counter / DIMM via vendor BMC.'
            }
        }
    } catch { }
}

$TableFormat = @{
    Status = { param($v,$row) if ($v -eq 'red') { 'bad' } elseif ($v -eq 'yellow') { 'warn' } else { '' } }
}
