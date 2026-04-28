# Start of Settings
# End of Settings

$Title          = 'ESXi Persistent Log Location'
$Header         = "[count] host(s) with non-persistent /scratch"
$Comments       = "Default /scratch on USB/SD-boot installs is a tmpfs ramdisk - logs are lost at reboot. Persistent /scratch on a reliable datastore = forensic data survives reboots."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = "Configure ScratchConfig.ConfiguredScratchLocation to a persistent datastore path. Combine with remote syslog forwarding for full forensic coverage."

if (-not $Global:VCConnected) { return }

foreach ($h in (Get-VMHost -ErrorAction SilentlyContinue)) {
    if ($h.ConnectionState -ne 'Connected') { continue }
    try {
        $configured = (Get-AdvancedSetting -Entity $h -Name 'ScratchConfig.ConfiguredScratchLocation' -ErrorAction SilentlyContinue).Value
        $current = (Get-AdvancedSetting -Entity $h -Name 'ScratchConfig.CurrentScratchLocation' -ErrorAction SilentlyContinue).Value

        $isTmpfs = ($current -match '^/tmp' -or $current -match 'scratch$' -and $configured -ne $current)
        $isPersistent = ($current -match 'vmfs|nfs|/vmfs/volumes/' -and $current -notmatch 'tmpfs')

        if (-not $isPersistent -or $isTmpfs) {
            [pscustomobject]@{
                Host = $h.Name
                Cluster = if ($h.Parent) { $h.Parent.Name } else { '' }
                ConfiguredLocation = $configured
                CurrentLocation = $current
                Note = if ($isTmpfs) { 'Scratch on tmpfs - logs lost at reboot' } else { 'Verify persistent location' }
            }
        }
    } catch { }
}

$TableFormat = @{
    Note = { param($v,$row) if ($v -match 'tmpfs') { 'bad' } else { 'warn' } }
}
