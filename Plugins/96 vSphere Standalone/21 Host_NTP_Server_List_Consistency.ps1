# Start of Settings
# End of Settings

$Title          = 'Host NTP Server List Consistency'
$Header         = '[count] cluster(s) with NTP server lists that differ between hosts'
$Comments       = 'Mixed NTP sources within a cluster lead to subtle skew. Standardize.'
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = '96 vSphere Standalone'
$Severity       = 'P3'
$Recommendation = 'Apply via host profile or PowerCLI: Set-VMHostNtpServer -VMHost <h> -NtpServer ntp1,ntp2.'

if (-not $Global:VCConnected) { return }
Get-Cluster -ErrorAction SilentlyContinue | ForEach-Object {
    $cl = $_
    $hosts = Get-VMHost -Location $cl -ErrorAction SilentlyContinue
    $sets = @{}
    foreach ($h in $hosts) {
        $list = (Get-VMHostNtpServer -VMHost $h -ErrorAction SilentlyContinue) -join ','
        $sets[$list] = $true
    }
    if (@($sets.Keys).Count -gt 1) {
        [pscustomobject]@{ Cluster=$cl.Name; DistinctNtpLists=@($sets.Keys).Count; Lists=($sets.Keys -join ' | ') }
    }
}
