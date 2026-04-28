# Start of Settings
$WarnRatio = 5
$BadRatio  = 8
# End of Settings

$Title          = 'Cluster vCPU : pCPU Oversubscription'
$Header         = '[count] cluster(s) with high vCPU/pCPU oversubscription'
$Comments       = 'Aggregate vCPU (sum of NumCpu across powered-on VMs) divided by pCPU (sum of physical cores). VDI tolerates 5:1 - 8:1; server workloads typically 1.5:1 - 3:1. High ratios cause CPU ready (KB 2002181) under load.'
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = 'Right-size oversubscribed VMs, scale out the cluster, or split workloads by tier. Pair this finding with 13 VM CPU Ready Outliers to confirm whether oversubscription is hurting in practice.'

if (-not $Global:VCConnected) { return }

foreach ($c in (Get-Cluster -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $hosts = @($c | Get-VMHost)
    if ($hosts.Count -eq 0) { continue }
    $pcpu  = ($hosts | Measure-Object -Property NumCpu -Sum).Sum
    $vms   = @($c | Get-VM | Where-Object { $_.PowerState -eq 'PoweredOn' })
    $vcpu  = ($vms | Measure-Object -Property NumCpu -Sum).Sum
    if ($pcpu -le 0) { continue }
    $ratio = [math]::Round($vcpu/$pcpu, 2)
    if ($ratio -ge $WarnRatio) {
        [pscustomobject]@{
            Cluster      = $c.Name
            pCPU         = $pcpu
            vCPU         = $vcpu
            Ratio        = "$ratio : 1"
            Threshold    = "$WarnRatio : 1 warn / $BadRatio : 1 bad"
            PoweredOnVMs = $vms.Count
        }
    }
}

$TableFormat = @{
    Ratio = { param($v,$row)
        $r = [decimal]([string]$v -replace ' : 1','')
        if ($r -ge $BadRatio) { 'bad' } elseif ($r -ge $WarnRatio) { 'warn' } else { '' }
    }
}
