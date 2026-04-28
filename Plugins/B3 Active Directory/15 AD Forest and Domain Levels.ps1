# Start of Settings
# End of Settings

$Title          = "AD Forest + Domain Functional Levels + Schema"
$Header         = "Forest + per-domain Functional Level + Schema version"
$Comments       = "Functional levels gate which AD features are usable: AES Kerberos (FL2008+), Compound Identity / KCD (FL2012+), Authentication Silos (FL2012R2+), Privileged Access Workstation tiering (FL2016+). Schema version reveals OS that last extended the schema."
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "B3 Active Directory"
$Severity       = "P3"
$Recommendation = "Functional levels older than Windows2012R2 lose features and are no longer mainstream-supported. Plan FL upgrade before retiring the last DC at the lower level. Schema upgrades require Schema Admin + a forest-wide change window."

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    [pscustomobject]@{ Note = 'ActiveDirectory PowerShell module not available.' }
    return
}
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

try {
    $forest = Get-ADForest
    $rows = New-Object System.Collections.ArrayList
    [void]$rows.Add([pscustomobject]@{
        Scope        = 'Forest'
        Name         = $forest.Name
        Mode         = $forest.ForestMode
        SchemaMaster = $forest.SchemaMaster
        DomainNamingMaster = $forest.DomainNamingMaster
        UPNSuffixes  = ($forest.UPNSuffixes -join ', ')
        Trusts       = (@(Get-ADTrust -Filter * -ErrorAction SilentlyContinue).Count)
    })
    foreach ($d in $forest.Domains) {
        try {
            $dom = Get-ADDomain -Identity $d -ErrorAction Stop
            [void]$rows.Add([pscustomobject]@{
                Scope        = 'Domain'
                Name         = $dom.DNSRoot
                Mode         = $dom.DomainMode
                SchemaMaster = $dom.PDCEmulator
                DomainNamingMaster = $dom.RIDMaster
                UPNSuffixes  = ''
                Trusts       = ''
            })
        } catch { }
    }
    # Schema version
    try {
        $schema = Get-ADObject (Get-ADRootDSE).schemaNamingContext -Properties objectVersion
        [void]$rows.Add([pscustomobject]@{
            Scope        = 'Schema'
            Name         = "objectVersion=$($schema.objectVersion)"
            Mode         = switch ([int]$schema.objectVersion) {
                88 { 'Windows Server 2019/2022 (88)' }
                87 { 'Windows Server 2016 (87)' }
                69 { 'Windows Server 2012 R2 (69)' }
                56 { 'Windows Server 2012 (56)' }
                47 { 'Windows Server 2008 R2 (47)' }
                default { "Schema v$($schema.objectVersion)" }
            }
            SchemaMaster = ''
            DomainNamingMaster = ''
            UPNSuffixes  = ''
            Trusts       = ''
        })
    } catch { }
    $rows
} catch {
    [pscustomobject]@{ Note = "Forest probe failed: $($_.Exception.Message)" }
}
