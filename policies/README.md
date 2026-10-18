# Conditional Access policies (JSON)

The seven policies from [Part 2.2](../parts/2.2-conditional-access/README.md), exported from the Entra admin center with **Download JSON** after they were turned on (`"state": "enabled"`).

| File | Who | Condition | Control |
|---|---|---|---|
| `CA001-AllUsers-AllResources-RequireMFA.json` | All users | All resources | Require MFA |
| `CA002-AllUsers-BlockLegacyAuth.json` | All users | Exchange ActiveSync, other clients | Block |
| `CA003-Admins-RequirePhishingResistantMFA.json` | 6 admin roles | All resources | Phishing-resistant MFA strength |
| `CA004-Leavers-BlockAllAccess.json` | `CA-Block-Leavers` | All resources | Block |
| `CA005-AllUsers-SignInRisk-RequireMFA.json` | All users | Sign-in risk medium or high | Require MFA, sign-in every time |
| `CA006-AllUsers-HighUserRisk-PasswordChange.json` | All users | User risk high | MFA + password change, sign-in every time |
| `CA007-AllUsers-BlockOutsideUS.json` | All users | Any location except `Allowed-Countries-US` | Block |

Every policy excludes the `CA-Exclude-EmergencyAccess` group. Every all-user policy also excludes the Directory Synchronization Accounts role.

**Redactions:** each policy's own ID and the Graph metadata links are removed, and tenant-specific object IDs are replaced with placeholders: `<CA-Exclude-EmergencyAccess-group-id>`, `<CA-Block-Leavers-group-id>` and `<Allowed-Countries-US-named-location-id>`. The remaining IDs are Microsoft's built-in role template IDs (such as `62e90394-…` for Global Administrator and `d29b2b05-…` for Directory Synchronization Accounts) and built-in authentication strengths, which are the same in every tenant.

**To reuse these:** replace the placeholders with object IDs from your own tenant, import with **Conditional Access → Policies → Upload policy file**, and import them in **report-only** first, the same way they were built.
