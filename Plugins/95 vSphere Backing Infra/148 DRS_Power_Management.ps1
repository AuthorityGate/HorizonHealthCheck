# Start of Settings
# End of Settings

$Title          = 'DRS Power Management (DPM)'
$Header         = '[count] cluster(s) with DPM state worth reviewing'
$Comments       = "Distributed Power Management (DPM) hibernates idle ESXi hosts to save power. Most consulting clients have DPM Off (correct: capacity-on-demand workloads). DPM Manual is rare. DPM Automatic only for specifically-engineered designs with proven boot reliability and BMC integration."
$Display        = 'Table'
$Author         = 'AuthorityGate'
$PluginVersion  = 1.0
$PluginCategory = '95 vSphere Backing Infra'
$Severity       = 'P3'
$Recommendation = "Cluster -> Configure -> vSphere DRS -> Edit -> Power Management. Default = Off. Enable Automatic only after validating IPMI/iLO/iDRAC wake-on-LAN reliability across the fleet."

if (-not $Global:VCConnected) { return }

foreach ($c in (Get-Cluster -ErrorAction SilentlyContinue | Where-Object { $_.DrsEnabled } | Sort-Object Name)) {
    try {
        $cv = ($c | Get-View)
        $dpm = $cv.Configuration.DpmConfigInfo
        if ($dpm) {
            $enabled = $dpm.Enabled
            $level   = $dpm.DefaultDpmBehavior
            if ($enabled) {
                [pscustomobject]@{
                    Cluster      = $c.Name
                    DPMEnabled   = $enabled
                    AutomationLevel = $level
                    Note         = 'DPM enabled - validate WOL across all hosts; DPM evacuations during night windows can mask hardware faults.'
                }
            }
        }
    } catch { }
}
