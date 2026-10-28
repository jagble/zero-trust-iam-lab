<#
  Part 2.8: non-human identity inventory.
  READ-ONLY. Lists app registrations (owners, credentials, application permissions, last sign-in),
  delegated permission consents and managed identities. Writes CSV files. Changes nothing.
  Run in Azure Cloud Shell (PowerShell).
#>
Connect-MgGraph -UseDeviceCode -NoWelcome -Scopes "Application.Read.All","Directory.Read.All","AuditLog.Read.All"
function Get-All($uri) { $out = @(); while ($uri) { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $out += $r.value; $uri = $r.'@odata.nextLink' }; $out }

# Microsoft Graph permission IDs -> names
$graphSp = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '00000003-0000-0000-c000-000000000000'").value[0]
$roleName = @{}; $graphSp.appRoles | ForEach-Object { $roleName[$_.id] = $_.value }

# Last sign-in for every app
$lastSignIn = @{}
Get-All "https://graph.microsoft.com/beta/reports/servicePrincipalSignInActivities" | ForEach-Object { $lastSignIn[$_.appId] = $_.lastSignInActivity.lastSignInDateTime }

# 1. App registrations
$apps = Get-All "https://graph.microsoft.com/v1.0/applications?`$select=id,appId,displayName,createdDateTime,passwordCredentials,keyCredentials"
$appRows = foreach ($a in $apps) {
  $owners = (Get-All "https://graph.microsoft.com/v1.0/applications/$($a.id)/owners").displayName -join '; '
  $sp = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$($a.appId)'").value | Select-Object -First 1
  $perms = if ($sp) { (Get-All "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignments" | ForEach-Object {
             if ($roleName[$_.appRoleId]) { $roleName[$_.appRoleId] } else { "$($_.resourceDisplayName) role" } }) -join '; ' }
  [pscustomobject]@{
    App            = $a.displayName
    Created        = $a.createdDateTime
    Owners         = $owners
    Secrets        = @($a.passwordCredentials).Count
    SecretExpires  = (@($a.passwordCredentials).endDateTime | Sort-Object | Select-Object -First 1)
    Certificates   = @($a.keyCredentials).Count
    CertExpires    = (@($a.keyCredentials).endDateTime | Sort-Object | Select-Object -First 1)
    AppPermissions = $perms
    LastSignIn     = $lastSignIn[$a.appId]
  }
}
$appRows | Export-Csv apps.csv -NoTypeInformation

# 2. Delegated permission consents
$grants = Get-All "https://graph.microsoft.com/v1.0/oauth2PermissionGrants"
$grants | ForEach-Object {
  $client = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($_.clientId)?`$select=displayName"
  [pscustomobject]@{ App = $client.displayName; ConsentType = $_.consentType; Scopes = $_.scope.Trim() }
} | Export-Csv delegated.csv -NoTypeInformation

# 3. Managed identities
Get-All "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=servicePrincipalType eq 'ManagedIdentity'&`$select=displayName,appId" |
  ForEach-Object { [pscustomobject]@{ ManagedIdentity = $_.displayName } } | Export-Csv managed-identities.csv -NoTypeInformation

$appRows | Format-Table App, Owners, Secrets, Certificates, AppPermissions, LastSignIn -AutoSize -Wrap
"Delegated consents: {0}" -f @($grants).Count
