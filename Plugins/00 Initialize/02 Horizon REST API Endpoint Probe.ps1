# Start of Settings
# End of Settings

$Title          = "Horizon REST API Endpoint Probe"
$Header         = "Per-endpoint REST API reachability"
$Comments       = @"
Each row shows a Horizon REST endpoint that one or more plugins called, the URL we ultimately tried, the HTTP status returned, and the disposition (OK, remapped to a working alternate, or skipped because nothing answered). Use this to triage why downstream plugins emit zero rows or 404 errors. Common causes:
- Connection Server REST API not exposed (firewall, /rest/swagger-ui returns 404)
- Service-account role missing 'Administrators' or 'Inventory Administrators'
- Horizon version older than 2106 (no REST surface for that endpoint)
- Pre-2206 Horizon that uses /v1/monitor/X form vs 2206+ /monitor/v1/X form
"@
$Display        = "Table"
$Author         = "AuthorityGate"
$PluginVersion  = 1.0
$PluginCategory = "00 Initialize"
$Severity       = "Info"
$Recommendation = @"
If everything shows 404 across the board: confirm the REST API is enabled on this Connection Server (https://<cs>/rest/swagger-ui.html should load) and that the service account holds at least 'Administrators (Read only)' role under Horizon Console -> Settings -> Administrators. If only some endpoints fail, the plugin row is logged with the exact path it tried -- compare that to the Swagger UI on this CS to see whether the path moved (Horizon REST has shifted between 2106 / 2206 / 2303 builds).
"@

if (-not (Get-HVRestSession)) {
    [pscustomobject]@{
        OriginalPath = '(no Horizon session)'
        TriedPath    = ''
        Status       = ''
        Result       = 'Horizon REST not connected; skip.'
    }
    return
}

# Run only after the regular plugins have populated the probe; the runner
# orders 00 -> 99, so this fires first BUT the probe also captures the
# remap discoveries this plugin has already triggered. To make sure we're
# useful even on an early run, hit a small set of well-known endpoints
# directly so the table is never empty.
$probeTargets = @(
    '/v1/monitor/connection-servers'
    '/v1/monitor/virtual-centers'
    '/v1/monitor/gateways'
    '/v1/pods'
    '/v1/sites'
    '/v2/desktop-pools'
    '/v1/farms'
    '/v1/application-pools'
    '/v1/machines'
    '/v1/rds-servers'
    '/v1/sessions'
    '/v1/global-entitlements'
    '/v1/settings/general-settings'
    '/v1/settings/license'
)
foreach ($t in $probeTargets) {
    try { $null = Invoke-HVRest -Path $t -NoPaging:$($t -match '/settings/') -ErrorAction SilentlyContinue } catch { }
}

$probe = Get-HVPathProbe
if (-not $probe -or $probe.Count -eq 0) {
    [pscustomobject]@{
        OriginalPath = '(no calls captured)'
        TriedPath    = ''
        Status       = ''
        Result       = 'No REST calls have been made yet on this session.'
    }
    return
}

# Collapse to one row per OriginalPath - prefer the row that succeeded; otherwise
# the first row we recorded for that path.
$grouped = $probe | Group-Object OriginalPath
foreach ($g in $grouped) {
    $hit = $g.Group | Where-Object { $_.Status -eq 200 } | Select-Object -First 1
    if (-not $hit) { $hit = $g.Group | Select-Object -First 1 }
    [pscustomobject]@{
        OriginalPath = $g.Name
        TriedPath    = $hit.TriedPath
        Status       = $hit.Status
        Result       = $hit.Result
    }
}

$TableFormat = @{
    Status = { param($v,$row)
        if ([string]$v -eq '200') { 'ok' }
        elseif ([string]$v -eq '404') { 'bad' }
        elseif ([string]$v -eq '403') { 'bad' }
        elseif ([string]$v -in @('401','405','501')) { 'warn' }
        else { '' }
    }
    Result = { param($v,$row)
        if ($v -match '^OK') { 'ok' }
        elseif ($v -match 'Forbidden|Error') { 'bad' }
        else { '' }
    }
}
