# Start of Settings
# Minimum surplus headroom: cluster CPU/RAM minus the largest single host
# must still cover current consumption with at least this much buffer.
$MinHeadroomPct = 10
# End of Settings

$Title          = 'Cluster N+1 Capacity Headroom'
$Header         = '[count] cluster(s) without N+1 CPU or RAM headroom'
$Comments       = "Standard HA design: cluster total minus its largest host (worst-case host failure) should still serve current workload with >= $MinHeadroomPct% buffer. If not, an HA event will not have somewhere to restart all VMs."
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = 'Add capacity, evict workloads, or relax admission control. Verify HA admission-control policy matches your tolerance (Slot vs Percentage vs Dedicated Failover Hosts).'

if (-not $Global:VCConnected) { return }

foreach ($c in (Get-Cluster -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $hosts = @($c | Get-VMHost)
    if ($hosts.Count -lt 2) { continue }
    $totalCpuMHz = ($hosts | Measure-Object -Property CpuTotalMhz -Sum).Sum
    $totalRamMB  = ($hosts | Measure-Object -Property MemoryTotalMB -Sum).Sum
    $maxCpuMHz   = ($hosts | Measure-Object -Property CpuTotalMhz -Maximum).Maximum
    $maxRamMB    = ($hosts | Measure-Object -Property MemoryTotalMB -Maximum).Maximum
    $usedCpuMHz  = ($hosts | Measure-Object -Property CpuUsageMhz -Sum).Sum
    $usedRamMB   = ($hosts | Measure-Object -Property MemoryUsageMB -Sum).Sum

    $survCpu = $totalCpuMHz - $maxCpuMHz
    $survRam = $totalRamMB  - $maxRamMB
    $cpuHeadroomPct = if ($survCpu -gt 0) { [math]::Round((($survCpu - $usedCpuMHz)/$survCpu)*100, 1) } else { -100 }
    $ramHeadroomPct = if ($survRam -gt 0) { [math]::Round((($survRam - $usedRamMB)/$survRam)*100, 1) } else { -100 }

    if ($cpuHeadroomPct -lt $MinHeadroomPct -or $ramHeadroomPct -lt $MinHeadroomPct) {
        [pscustomobject]@{
            Cluster        = $c.Name
            Hosts          = $hosts.Count
            CpuHeadroomPct = $cpuHeadroomPct
            RamHeadroomPct = $ramHeadroomPct
            Threshold      = "$MinHeadroomPct%"
            Note           = 'Surviving cluster after worst-case host loss has insufficient buffer.'
        }
    }
}

$TableFormat = @{
    CpuHeadroomPct = { param($v,$row) if ([decimal]$v -lt $MinHeadroomPct) { 'bad' } else { '' } }
    RamHeadroomPct = { param($v,$row) if ([decimal]$v -lt $MinHeadroomPct) { 'bad' } else { '' } }
}
