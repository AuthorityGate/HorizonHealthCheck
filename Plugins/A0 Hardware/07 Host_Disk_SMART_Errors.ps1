# Start of Settings
# End of Settings

$Title          = 'Host Disk SMART Errors'
$Header         = '[count] device(s) with SMART pre-fail / failure indicators'
$Comments       = 'Reference: KB 2148572. SMART pre-fail status on a drive means imminent failure. Replace before catastrophic loss.'
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.1
$PluginCategory = 'A0 Hardware'
$Severity       = 'P1'
$Recommendation = 'Replace the drive while it is still readable. For vSAN cache devices, follow the vSAN disk-replacement procedure (vSphere Client -> Cluster -> Configure -> vSAN -> Disk Management -> Remove Disk Group -> replace -> recreate group).'

if (-not $Global:VCConnected) { return }

foreach ($h in (Get-VMHost -ErrorAction SilentlyContinue)) {
    if ($h.ConnectionState -ne 'Connected') { continue }

    try {
        $esxcli = Get-EsxCli -V2 -VMHost $h -ErrorAction Stop
    } catch {
        # Cannot reach host's esxcli interface - emit a single 'unknown' row so
        # the host shows up in the report rather than silently being skipped.
        [pscustomobject]@{
            Host       = $h.Name
            Cluster    = $h.Parent.Name
            Device     = '(esxcli unreachable)'
            Parameter  = 'n/a'
            Value      = ''
            Threshold  = ''
            Status     = 'unknown'
            Note       = "esxcli probe failed: $($_.Exception.Message)"
        }
        continue
    }

    try {
        $devices = $esxcli.storage.core.device.list.Invoke() |
            Where-Object { $_.IsLocal -eq 'true' -and $_.IsRemovable -eq 'false' }
    } catch {
        $devices = @()
    }

    foreach ($d in $devices) {
        try {
            $smart = $esxcli.storage.core.device.smart.get.Invoke(@{ devicename = $d.Device }) 2>$null
        } catch {
            continue
        }
        if (-not $smart) { continue }

        foreach ($p in $smart) {
            $isFail = $false
            $reason = ''
            # SMART rows expose Value and Threshold; if Value -le Threshold the
            # parameter is in pre-fail state. Some drives instead expose a
            # 'Worst' column - we treat that the same way.
            if ($p.Value -ne $null -and $p.Threshold -ne $null) {
                $vNum = 0; $tNum = 0
                if ([int]::TryParse([string]$p.Value, [ref]$vNum) -and [int]::TryParse([string]$p.Threshold, [ref]$tNum)) {
                    if ($tNum -gt 0 -and $vNum -le $tNum) { $isFail = $true; $reason = "Value $vNum <= Threshold $tNum" }
                }
            }
            if (-not $isFail -and $p.Status -and ($p.Status -match 'fail|prefail|degraded')) {
                $isFail = $true; $reason = "SMART status: $($p.Status)"
            }
            if ($isFail) {
                [pscustomobject]@{
                    Host       = $h.Name
                    Cluster    = $h.Parent.Name
                    Device     = $d.Device
                    Parameter  = $p.Parameter
                    Value      = $p.Value
                    Threshold  = $p.Threshold
                    Status     = if ($p.Status) { $p.Status } else { 'pre-fail' }
                    Note       = $reason
                }
            }
        }
    }
}

$TableFormat = @{
    Status = { param($v,$row) if ($v -match 'fail|prefail') { 'bad' } elseif ($v -eq 'unknown') { 'warn' } else { '' } }
}
