# Start of Settings
# Hosts on or below this build are flagged. Update yearly. Defaults reflect a
# late-2024/early-2025 LTSR-equivalent baseline; verify against your support
# matrix and the VMware/Broadcom 'Patches and Updates' KB.
$MinAcceptableEsxiBuild = 22380479    # ~ ESXi 8.0 U2b, 2024-Q1 baseline
$MinAcceptableVcsaBuild = 22617221    # ~ vCenter 8.0 U2b
# End of Settings

$Title          = "ESXi / vCenter Build Currency"
$Header         = "[count] host(s) at or below the configured baseline build"
$Comments       = "Per VMware Lifecycle / VMSA security advisories, ESXi must be patched within ~90 days of release. Hosts below the baseline build are listed; vCenter is reported in the table footer."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "95 vSphere Backing Infra"
$Severity       = "P2"
$Recommendation = "Stage host upgrades via vSphere Lifecycle Manager (vLCM). Reference: VMSA bulletins + KB 'Build numbers and versions of ESXi/vCenter' (KB 2143832 / 2143838)."

if (-not $Global:VCConnected) { return }

# ESXi hosts
Get-VMHost -ErrorAction SilentlyContinue | ForEach-Object {
    $build = [int]($_.Build -replace '[^0-9]','')
    if ($build -gt 0 -and $build -le $MinAcceptableEsxiBuild) {
        [pscustomobject]@{
            Type    = 'ESXi'
            Name    = $_.Name
            Version = $_.Version
            Build   = $_.Build
            BaselineBuild = $MinAcceptableEsxiBuild
            Cluster = $_.Parent.Name
        }
    }
}

# vCenter (one row, only when below baseline)
$vc = $global:DefaultVIServer
if ($vc) {
    $vcBuild = [int]($vc.Build -replace '[^0-9]','')
    if ($vcBuild -gt 0 -and $vcBuild -le $MinAcceptableVcsaBuild) {
        [pscustomobject]@{
            Type    = 'vCenter'
            Name    = $vc.Name
            Version = $vc.Version
            Build   = $vc.Build
            BaselineBuild = $MinAcceptableVcsaBuild
            Cluster = '-'
        }
    }
}

$TableFormat = @{
    Build = { param($v,$row) 'warn' }
}
