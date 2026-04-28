# Start of Settings
# End of Settings

$Title          = 'vMotion Network Isolation'
$Header         = '[count] host(s) with vMotion VMK on a shared subnet'
$Comments       = "vSCG / VMware Networking Best Practices: vMotion traffic is unencrypted by default and must NOT share a VLAN/subnet with management or VM data networks. Place vMotion on its own non-routable VLAN; consider Encrypted vMotion (per-VM setting) for tenant isolation."
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P2'
$Recommendation = "Move the vMotion VMkernel to a dedicated port group / VLAN on a separate subnet. If vMotion must traverse a shared L2/L3, enable Encrypted vMotion ('Required') on every VM that may move."

if (-not $Global:VCConnected) { return }

foreach ($h in (Get-VMHost -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $vmks = @(Get-VMHostNetworkAdapter -VMHost $h -VMKernel -ErrorAction SilentlyContinue)
    if ($vmks.Count -eq 0) { continue }

    # Build a map: subnet -> services bound to a VMK in that subnet
    $bySubnet = @{}
    foreach ($v in $vmks) {
        if (-not $v.IP -or -not $v.SubnetMask) { continue }
        # crude /24 derivation by lopping last octet
        $sub = ($v.IP -split '\.' | Select-Object -First 3) -join '.'
        if (-not $bySubnet.ContainsKey($sub)) { $bySubnet[$sub] = @() }
        $services = @()
        if ($v.ManagementTrafficEnabled) { $services += 'Mgmt' }
        if ($v.VMotionEnabled)           { $services += 'vMotion' }
        if ($v.FaultToleranceLoggingEnabled) { $services += 'FT' }
        if ($v.VsanTrafficEnabled)       { $services += 'vSAN' }
        if ($services.Count -eq 0)       { $services += 'Other' }
        foreach ($s in $services) { $bySubnet[$sub] += [pscustomobject]@{ VMK = $v.Name; IP = $v.IP; Service = $s } }
    }

    foreach ($sub in $bySubnet.Keys) {
        $entries  = $bySubnet[$sub]
        $services = @($entries | Select-Object -ExpandProperty Service -Unique)
        if ($services -contains 'vMotion' -and ($services -contains 'Mgmt' -or $services -contains 'Other')) {
            [pscustomobject]@{
                Host          = $h.Name
                Subnet        = "$sub.0/24"
                ServicesShared = ($services -join ', ')
                VMKs          = (@($entries | ForEach-Object { "$($_.VMK)=$($_.IP) [$($_.Service)]" }) -join '; ')
                Issue         = 'vMotion sharing subnet with management or untagged traffic.'
            }
        }
    }
}
