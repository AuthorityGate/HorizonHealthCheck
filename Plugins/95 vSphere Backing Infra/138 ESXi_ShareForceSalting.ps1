# Start of Settings
# End of Settings

$Title          = 'ESXi Memory Page-Sharing Salt'
$Header         = '[count] host(s) with insecure Mem.ShareForceSalting'
$Comments       = 'KB 2097593: Mem.ShareForceSalting=2 enforces per-VM salt for memory page sharing, preventing cross-VM TPS-based memory disclosure attacks. Default in 6.0+ is 2.'
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = "Set on each host: Get-VMHost <name> | Get-AdvancedSetting -Name Mem.ShareForceSalting | Set-AdvancedSetting -Value 2"

if (-not $Global:VCConnected) { return }

foreach ($h in (Get-VMHost -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $v = (Get-AdvancedSetting -Entity $h -Name 'Mem.ShareForceSalting' -ErrorAction SilentlyContinue).Value
    if ([int]$v -ne 2) {
        [pscustomobject]@{
            Host              = $h.Name
            ShareForceSalting = $v
            Recommended       = 2
            Note              = 'Mode 0 = no salting; mode 1 = optional; mode 2 = enforced.'
        }
    }
}

$TableFormat = @{
    ShareForceSalting = { param($v,$row) if ([int]$v -ne 2) { 'bad' } else { '' } }
}
