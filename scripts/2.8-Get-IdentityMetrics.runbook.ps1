# Get-IdentityMetrics: Azure Automation runbook (PowerShell 7).
# Runs as the Automation account's system-assigned managed identity. READ-ONLY. No stored credentials.
$headers = @{ 'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER; 'Metadata' = 'True' }
$token   = (Invoke-RestMethod -Uri "$($env:IDENTITY_ENDPOINT)?resource=https://graph.microsoft.com/" -Headers $headers).access_token
$auth    = @{ Authorization = "Bearer $token" }
function Get-All($uri) { $out = @(); while ($uri) { $r = Invoke-RestMethod -Uri $uri -Headers $auth; $out += $r.value; $uri = $r.'@odata.nextLink' }; $out }

$users   = Get-All 'https://graph.microsoft.com/v1.0/users?$select=userPrincipalName,accountEnabled,signInActivity&$top=999'
$enabled = @($users | Where-Object accountEnabled)
$active  = @($enabled | Where-Object { $_.signInActivity.lastSignInDateTime })
$stale   = @($active | Where-Object { [datetime]$_.signInActivity.lastSignInDateTime -lt (Get-Date).AddDays(-90) })

$capable = @{}
Get-All 'https://graph.microsoft.com/v1.0/reports/authenticationMethods/userRegistrationDetails' |
  Where-Object isMfaCapable | ForEach-Object { $capable[$_.userPrincipalName.ToLower()] = $true }
$activeMfa = @($active | Where-Object { $capable[$_.userPrincipalName.ToLower()] }).Count

$standing = @(Get-All 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleInstances' | Where-Object assignmentType -eq 'Assigned').Count
$eligible = @(Get-All 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleEligibilityScheduleInstances').Count

"PDS identity metrics, $(Get-Date -Format 'yyyy-MM-dd HH:mm') UTC"
"Accounts: $($users.Count) total, $($enabled.Count) enabled"
"MFA, users who sign in: $activeMfa of $($active.Count)"
"Enabled accounts never signed in: $($enabled.Count - $active.Count)"
"Stale (no sign-in in 90 days): $($stale.Count)"
"Standing admin assignments: $standing"
"Eligible admin assignments: $eligible"
