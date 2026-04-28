# Start of Settings
# End of Settings

$Title          = "vCenter Inventory Counts"
$Header         = "Datacenter / Cluster / Host / VM / Datastore / Network counts"
$Comments       = "Topline inventory for capacity-planning and licensing snapshots. One row per datacenter."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "96 vSphere Standalone"
$Severity       = "Info"
$Recommendation = "Track these counts month-over-month. >10% growth in VMs without matching license / capacity expansion = silent oversubscription brewing."

if (-not $Global:VCConnected) { return }

$dcs = @(Get-Datacenter -ErrorAction SilentlyContinue)
foreach ($dc in $dcs) {
    [pscustomobject]@{
        Datacenter   = $dc.Name
        Clusters     = @(Get-Cluster -Location $dc -ErrorAction SilentlyContinue).Count
        Hosts        = @(Get-VMHost  -Location $dc -ErrorAction SilentlyContinue).Count
        VMs          = @(Get-VM      -Location $dc -ErrorAction SilentlyContinue).Count
        VMsPoweredOn = @(Get-VM      -Location $dc -ErrorAction SilentlyContinue | Where-Object { $_.PowerState -eq 'PoweredOn' }).Count
        Datastores   = @(Get-Datastore -Location $dc -ErrorAction SilentlyContinue).Count
        Networks     = @(Get-VirtualPortGroup -Location $dc -ErrorAction SilentlyContinue).Count
        ResourcePools = @(Get-ResourcePool -Location $dc -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'Resources' }).Count
        Folders      = @(Get-Folder -Location $dc -Type VM -ErrorAction SilentlyContinue).Count
    }
}
