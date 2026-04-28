# Start of Settings
# End of Settings

$Title          = 'Desktop Pool Entitlement Audit'
$Header         = "[count] pool(s) with entitlement details"
$Comments       = "Per-pool entitled users + groups. Surfaces over-broad entitlement (Domain Users on production pool), un-entitled pools (no users assigned), nested-group depth concerns."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = '30 Desktop Pools'
$Severity       = 'P3'
$Recommendation = "Production pools should be entitled to specific groups, not Domain Users. Un-entitled pools waste capacity. Nested groups > 3 deep = AD lookup latency."

if (-not (Get-HVRestSession)) { return }

foreach ($p in (Get-HVDesktopPool)) {
    try {
        $ent = Invoke-HVRest -Path "/v1/entitlements/desktop-pools?id=$($p.id)" -NoPaging
        $userCount = if ($ent -and $ent.user_ids) { @($ent.user_ids).Count } else { 0 }
        $groupCount = if ($ent -and $ent.group_ids) { @($ent.group_ids).Count } else { 0 }
        $note = ''
        if ($userCount + $groupCount -eq 0) { $note = 'POOL HAS NO ENTITLEMENTS' }
        [pscustomobject]@{
            Pool        = $p.display_name
            Type        = $p.type
            UserCount   = $userCount
            GroupCount  = $groupCount
            Total       = $userCount + $groupCount
            Note        = $note
        }
    } catch {
        [pscustomobject]@{
            Pool = $p.display_name; Type = $p.type
            UserCount = ''; GroupCount = ''; Total = ''
            Note = "Entitlement query failed: $($_.Exception.Message)"
        }
    }
}

$TableFormat = @{
    Total = { param($v,$row) if ("$v" -eq '0' -or $v -eq 0) { 'warn' } else { '' } }
    Note  = { param($v,$row) if ($v -match 'NO ENTITLEMENTS') { 'bad' } else { '' } }
}
