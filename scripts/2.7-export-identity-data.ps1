<#
  Part 2.7: export the data behind the identity metrics report.
  READ-ONLY. Reads users, MFA registration and admin role assignments
  from Microsoft Graph and writes three CSV files. Changes nothing.

  Run in Azure Cloud Shell (PowerShell). First time only:
    Install-Module Microsoft.Graph.Users, Microsoft.Graph.Reports,
      Microsoft.Graph.Identity.Governance, Microsoft.Graph.DirectoryObjects -Scope CurrentUser -Force
#>

Connect-MgGraph -UseDeviceCode -NoWelcome -Scopes "User.Read.All","AuditLog.Read.All","UserAuthenticationMethod.Read.All","RoleManagement.Read.Directory","Directory.Read.All"

# 1. Users and last sign-in
$users = Get-MgUser -All -Property "id,displayName,userPrincipalName,accountEnabled,onPremisesSyncEnabled,userType,createdDateTime,signInActivity" |
  Select-Object DisplayName, UserPrincipalName, AccountEnabled, OnPremisesSyncEnabled, UserType, CreatedDateTime,
    @{n='LastSignIn';e={$_.SignInActivity.LastSignInDateTime}},
    @{n='LastNonInteractiveSignIn';e={$_.SignInActivity.LastNonInteractiveSignInDateTime}}
$users | Export-Csv users.csv -NoTypeInformation

# 2. MFA registration
$mfa = Get-MgReportAuthenticationMethodUserRegistrationDetail -All |
  Select-Object UserPrincipalName, IsAdmin, IsMfaRegistered, IsMfaCapable, IsPasswordlessCapable,
    @{n='Methods';e={$_.MethodsRegistered -join ';'}}
$mfa | Export-Csv mfa.csv -NoTypeInformation

# 3. Admin roles: standing, activated (PIM) and eligible
$roleNames = @{}
Get-MgRoleManagementDirectoryRoleDefinition -All | ForEach-Object { $roleNames[$_.Id] = $_.DisplayName }
$active = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -All | ForEach-Object {
  [pscustomobject]@{ Role = $roleNames[$_.RoleDefinitionId]; PrincipalId = $_.PrincipalId; State = $_.AssignmentType; End = $_.EndDateTime } }
$eligible = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -All | ForEach-Object {
  [pscustomobject]@{ Role = $roleNames[$_.RoleDefinitionId]; PrincipalId = $_.PrincipalId; State = 'Eligible'; End = $_.EndDateTime } }
$all = @($active) + @($eligible)
$names = @{}
Get-MgDirectoryObjectById -Ids ($all.PrincipalId | Select-Object -Unique) | ForEach-Object { $names[$_.Id] = $_.AdditionalProperties.displayName }
$all | Select-Object Role, @{n='Principal';e={$names[$_.PrincipalId]}}, State, End | Export-Csv roles.csv -NoTypeInformation

# 4. Quick summary
"Users: {0} total, {1} enabled" -f $users.Count, ($users | Where-Object AccountEnabled).Count
"MFA capable: {0} of {1}" -f ($mfa | Where-Object IsMfaCapable).Count, $mfa.Count
"Enabled users who never signed in: {0}" -f ($users | Where-Object { $_.AccountEnabled -and -not $_.LastSignIn }).Count
"Admin roles: {0} standing, {1} activated, {2} eligible" -f ($active | Where-Object State -eq 'Assigned').Count, ($active | Where-Object State -eq 'Activated').Count, $eligible.Count
