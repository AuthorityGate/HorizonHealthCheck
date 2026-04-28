# Start of Settings
# Days-to-expiry threshold.
$WarnDays = 60
# End of Settings

$Title          = "ESXi Host Certificate Expiry"
$Header         = "[count] host certificate(s) expiring in <= $WarnDays days"
$Comments       = "VMware KB 2113034 / vSphere Security Guide: ESXi machine SSL certs default to 2 years, signed by VMCA. When they expire (or are about to), management agents (hostd, vpxa) lose trust with vCenter - host shows 'Disconnected' until renewed."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "96 vSphere Standalone"
$Severity       = "P1"
$Recommendation = "Host -> Configure -> Certificate -> 'Renew'. For VMCA-signed: re-issue from vCenter. For external CA: replace via 'certificate-manager' on the host or PowerCLI 'New-VMHostCertificate'."

if (-not $Global:VCConnected) { return }

Get-VMHost -ErrorAction SilentlyContinue | ForEach-Object {
    $h = $_
    try {
        $cert = (Get-VMHost -Name $h.Name).ExtensionData.Config.Certificate
        if (-not $cert) { return }
        $x = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(,([byte[]]$cert))
        $days = [int]($x.NotAfter - (Get-Date)).TotalDays
        if ($days -lt $WarnDays) {
            [pscustomobject]@{
                Host       = $h.Name
                Subject    = $x.Subject
                Issuer     = $x.Issuer
                NotAfter   = $x.NotAfter
                DaysLeft   = $days
                Thumbprint = $x.Thumbprint
            }
        }
    } catch { }
}

$TableFormat = @{ DaysLeft = { param($v,$row) if ([int]$v -lt 0) { 'bad' } elseif ([int]$v -lt 30) { 'bad' } elseif ([int]$v -lt 60) { 'warn' } else { '' } } }
