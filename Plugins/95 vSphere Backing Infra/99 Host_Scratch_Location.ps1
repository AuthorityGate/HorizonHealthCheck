# Start of Settings
# End of Settings

$Title          = 'Host Scratch Location'
$Header         = '[count] host(s) with default scratch / no persistent scratch'
$Comments       = 'Reference: KB 1033696. Without persistent scratch, vmkernel logs are lost on reboot. Auto-deploy hosts often miss scratch config.'
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = 'Set ScratchConfig.ConfiguredScratchLocation to a persistent VMFS / vSAN path. Reboot.'

if (-not $Global:VCConnected) { return }
Get-VMHost -ErrorAction SilentlyContinue | ForEach-Object {
    $cfg = (Get-AdvancedSetting -Entity $_ -Name 'ScratchConfig.ConfiguredScratchLocation' -ErrorAction SilentlyContinue).Value
    $cur = (Get-AdvancedSetting -Entity $_ -Name 'ScratchConfig.CurrentScratchLocation' -ErrorAction SilentlyContinue).Value
    if (-not $cfg -or $cur -like '/tmp*' -or $cur -like '*scratch*' -and $cur -notlike '/vmfs/*') {
        [pscustomobject]@{ Host=$_.Name; ConfiguredScratch=$cfg; CurrentScratch=$cur }
    }
}
