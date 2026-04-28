# Start of Settings
# End of Settings

$Title          = 'ESXi Block Guest BPDUs'
$Header         = '[count] host(s) NOT blocking guest-originated BPDUs'
$Comments       = 'KB 2034605: Net.BlockGuestBPDU=1 prevents a compromised VM from sending Bridge Protocol Data Units that could trick the physical switch into changing topology (BPDU Guard bypass).'
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = "Set on each host: Get-VMHost <name> | Get-AdvancedSetting -Name Net.BlockGuestBPDU | Set-AdvancedSetting -Value 1"

if (-not $Global:VCConnected) { return }

foreach ($h in (Get-VMHost -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $v = (Get-AdvancedSetting -Entity $h -Name 'Net.BlockGuestBPDU' -ErrorAction SilentlyContinue).Value
    if ([int]$v -ne 1) {
        [pscustomobject]@{
            Host             = $h.Name
            BlockGuestBPDU   = $v
            Recommended      = 1
        }
    }
}

$TableFormat = @{
    BlockGuestBPDU = { param($v,$row) if ([int]$v -ne 1) { 'bad' } else { '' } }
}
