# Start of Settings
# End of Settings

$Title          = 'ESXi Managed Object Browser (MOB) Disabled'
$Header         = '[count] host(s) with MOB enabled'
$Comments       = 'vSCG: Config.HostAgent.plugins.solo.enableMob exposes the Managed Object Browser, a JSON/HTML introspection of every ESXi managed object. Useful for support, attack surface in production. Default in 6.7+ is disabled.'
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = "Disable on each host: Get-VMHost <name> | Get-AdvancedSetting -Name Config.HostAgent.plugins.solo.enableMob | Set-AdvancedSetting -Value `$false"

if (-not $Global:VCConnected) { return }

foreach ($h in (Get-VMHost -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $v = (Get-AdvancedSetting -Entity $h -Name 'Config.HostAgent.plugins.solo.enableMob' -ErrorAction SilentlyContinue).Value
    if ([bool]$v) {
        [pscustomobject]@{
            Host       = $h.Name
            MobEnabled = $true
            Note       = 'MOB exposes managed-object metadata at https://<host>/mob/ - disable in production.'
        }
    }
}

$TableFormat = @{
    MobEnabled = { param($v,$row) if ($v -eq $true) { 'bad' } else { '' } }
}
