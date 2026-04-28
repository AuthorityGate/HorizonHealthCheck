# Start of Settings
# Maximum tolerable clock skew (seconds) before a finding is raised.
$MaxClockSkewSeconds = 60
# End of Settings

$Title          = "ESXi NTP Service / Clock Skew"
$Header         = "[count] host(s) with NTP service stopped, not configured, or skewed"
$Comments       = "VMware KB 57147 / 1339: Horizon authentication uses Kerberos which fails with > 5 minutes clock drift. We flag at 60s as an early warning. Two NTP servers minimum are recommended."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "95 vSphere Backing Infra"
$Severity       = "P1"
$Recommendation = "Set 'ntpd' service to Start automatically, configure 2+ NTP sources, then 'Restart NTP Daemon'. Verify with 'esxcli system time get' (KB 57147)."

if (-not $Global:VCConnected) { return }

Get-VMHost -ErrorAction SilentlyContinue | ForEach-Object {
    $h        = $_
    $ntpSvc   = Get-VMHostService -VMHost $h -ErrorAction SilentlyContinue | Where-Object { $_.Key -eq 'ntpd' }
    $ntpHosts = (Get-VMHostNtpServer -VMHost $h -ErrorAction SilentlyContinue) -join ', '
    $vcTime   = (Get-Date).ToUniversalTime()
    $hostTime = $null
    try {
        $dt = $h.ExtensionData.RetrieveDateTime()
        $hostTime = $dt
    } catch { }
    $skew = if ($hostTime) { [math]::Abs(($hostTime - $vcTime).TotalSeconds) } else { -1 }

    $isBad = ($null -eq $ntpSvc) -or (-not $ntpSvc.Running) -or (-not $ntpSvc.Policy -eq 'on') `
              -or (-not $ntpHosts) -or ($skew -gt $MaxClockSkewSeconds)
    if ($isBad) {
        [pscustomobject]@{
            Host        = $h.Name
            NTPRunning  = if ($ntpSvc) { $ntpSvc.Running } else { 'n/a' }
            NTPPolicy   = if ($ntpSvc) { $ntpSvc.Policy }  else { 'n/a' }
            NTPServers  = if ($ntpHosts) { $ntpHosts } else { '(none)' }
            ClockSkewSec = if ($skew -ge 0) { [int]$skew } else { 'unknown' }
        }
    }
}

$TableFormat = @{
    NTPRunning   = { param($v,$row) if ($v -ne $true) { 'bad' } else { '' } }
    NTPServers   = { param($v,$row) if ($v -eq '(none)') { 'bad' } elseif (($v -split ',').Count -lt 2) { 'warn' } else { '' } }
    ClockSkewSec = { param($v,$row) if ($v -is [int] -and $v -gt 60) { 'bad' } else { '' } }
}
