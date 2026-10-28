<#
  Part 2.8: give the Automation account's managed identity three read-only Microsoft Graph permissions.
  CHANGES SOMETHING: creates three app role assignments. Run once, in Azure Cloud Shell (PowerShell).
  At the consent prompt, consent for yourself only (don't tick "Consent on behalf of your organization").
#>
Connect-MgGraph -UseDeviceCode -NoWelcome -Scopes "AppRoleAssignment.ReadWrite.All","Application.Read.All"
$mi    = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=displayName eq 'aa-pds-identity-metrics' and servicePrincipalType eq 'ManagedIdentity'").value[0]
$graph = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '00000003-0000-0000-c000-000000000000'").value[0]
foreach ($perm in 'Directory.Read.All','AuditLog.Read.All','RoleManagement.Read.Directory') {
  $role = $graph.appRoles | Where-Object { $_.value -eq $perm -and $_.allowedMemberTypes -contains 'Application' }
  Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($mi.id)/appRoleAssignments" -Body @{ principalId = $mi.id; resourceId = $graph.id; appRoleId = $role.id } | Out-Null
  "Granted $perm"
}
