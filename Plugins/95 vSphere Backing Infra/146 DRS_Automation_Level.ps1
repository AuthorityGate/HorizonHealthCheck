# Start of Settings
# End of Settings

$Title          = 'DRS Automation Level'
$Header         = '[count] DRS-enabled cluster(s) NOT in FullyAutomated mode'
$Comments       = 'DRS at Manual/PartiallyAutomated requires operator approval for migrations - effectively load-balances only at VM power-on. Production clusters typically should be FullyAutomated.'
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = 'Cluster -> Configure -> vSphere DRS -> Edit -> Automation Level = Fully Automated. Use VM-level overrides if specific VMs must stay manual.'

if (-not $Global:VCConnected) { return }

foreach ($c in (Get-Cluster -ErrorAction SilentlyContinue | Where-Object { $_.DrsEnabled } | Sort-Object Name)) {
    if ($c.DrsAutomationLevel -ne 'FullyAutomated') {
        [pscustomobject]@{
            Cluster         = $c.Name
            AutomationLevel = $c.DrsAutomationLevel
            Recommended     = 'FullyAutomated'
        }
    }
}

$TableFormat = @{
    AutomationLevel = { param($v,$row) if ($v -ne 'FullyAutomated') { 'warn' } else { '' } }
}
