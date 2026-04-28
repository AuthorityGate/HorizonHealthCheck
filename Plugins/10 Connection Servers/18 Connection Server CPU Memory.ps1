# Start of Settings
# End of Settings

$Title          = 'Connection Server CPU / Memory Sizing'
$Header         = 'Per-CS CPU / RAM utilization snapshot'
$Comments       = 'VMware sizing baseline: 4 vCPU + 12 GB RAM minimum per CS for Horizon 8 (KB 70327). At sustained > 70% CPU or > 80% RAM, add a replica.'
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = '10 Connection Servers'
$Severity       = 'P3'
$Recommendation = 'Right-size or add a replica. Verify the CS is dedicated (no co-located AD/DNS/SQL).'

if (-not (Get-HVRestSession)) { return }
$cs = Get-HVConnectionServer
if (-not $cs) { return }
foreach ($c in $cs) {
    [pscustomobject]@{
        Name           = $c.name
        Version        = $c.version
        OsType         = $c.os_type
        CpuUtilization = $c.cpu_utilization
        RamSizeMb      = $c.ram_size_in_mb
        RamUsageMb     = $c.ram_usage_in_mb
        SslOk          = ($c.certificate.valid)
    }
}

