# Non-Human Identity Inventory and Findings: Potomac Defense Systems

> **About this report:** Potomac Defense Systems is a fictional company in a lab tenant. Inventory taken Oct 28, 2026 with [`scripts/2.8-nhi-inventory.ps1`](../scripts/2.8-nhi-inventory.ps1) (read-only). How it was built: [part 2.8](../parts/2.8-non-human-identities/README.md).
>
> **Scope:** app registrations owned by this tenant, delegated permission consents, and managed identities. Microsoft's own first-party service principals are out of scope.

## Findings rules (from the design)

Flag any non-human identity with: **no owner** · a **client secret** · a credential that **expires in under 30 days** or is **valid for over a year** · **high-privilege application permissions** · **no sign-in in 90 days**.

## Inventory (before remediation)

| Identity | Type | Owner | Credential | Expires | Application permissions | Last sign-in | Flags |
|---|---|---|---|---|---|---|---|
| `ConnectSyncProvisioning_FRD-SYNC-01` | App, created by Entra Connect | None | Certificate (90 days, rotated by Connect) | Jan 2, 2027 | Directory synchronization role | Oct 20 | No owner. **Tier 0** |
| `PDS-JML-Engine` (Project 1) | App | **None** | Certificate (6 months) | Apr 6, 2027 | `User.Read.All`, `User.RevokeSessions.All` | Oct 8 | No owner |
| `PDS-Legacy-Reporting` (planted) | App | **None** | **Client secret (2 years)** | Oct 27, 2028 | **`Directory.Read.All`** | **Never** | No owner, secret, valid over a year, broad permission, unused |
| Microsoft Graph Command Line Tools | Delegated, Microsoft app | n/a | n/a | n/a | Delegated, **consented for all users** | In use | Org-wide consent for an admin tool |

**Delegated consents:** 2. Graph Command Line Tools and PDS-Legacy-Reporting (`User.Read`), both **AllPrincipals** (for every user).
**Managed identities:** none.

## Remediation

| Identity | Action | Status |
|---|---|---|
| `PDS-Legacy-Reporting` | Deleted | ✅ |
| `PDS-JML-Engine` | Owner added (IAM admin) | ✅ |
| `ConnectSyncProvisioning_FRD-SYNC-01` | No owner added on purpose. Owners can add credentials, which would widen the path to Tier 0. Accountable owner: IAM (Tier 0 admin). Credential changes alerted | ✅ |
| Graph Command Line Tools | Assignment required, admin account only | ✅ |
| All apps | `ALERT-App-Credential-Added` (Severity 2) on any new secret or certificate | ✅ |

## Inventory (after remediation)

| Identity | Type | Owner | Credential | Permissions | Status |
|---|---|---|---|---|---|
| `ConnectSyncProvisioning_FRD-SYNC-01` | App (Entra Connect) | IAM, recorded here | Certificate, auto-rotated | Directory synchronization | Tier 0, monitored |
| `PDS-JML-Engine` | App | IAM admin | Certificate | 2 Graph application permissions | ✅ |
| `aa-pds-identity-metrics` | **Managed identity** (Automation) | Lifecycle tied to the Automation account | **None to store** | `Directory.Read.All`, `AuditLog.Read.All`, `RoleManagement.Read.Directory` | ✅ New |
| Graph Command Line Tools | Delegated | n/a | n/a | Delegated, assignment required | ✅ |

## Findings

| # | Finding | Risk | Fix |
|---|---|---|---|
| 1 | **The Entra Connect sync app is a Tier 0 identity with no owner and no monitoring** | Anyone who can add a credential to it can act as the sync service | Credential alert (done). Keep app-management roles eligible-only. Treat it like a domain controller |
| 2 | **The JML engine had no owner** | Nobody accountable for the app that removes leavers' access | Owner added (done) |
| 3 | **Unowned reporting app with a 2-year secret and directory-wide read, never used** | A leaked secret gives a full map of users and groups | Deleted (done) |
| 4 | **"Grant admin consent" also consented the app's default delegated permission for every user** | Each admin-consented app gets a tenant-wide delegated grant as well | Remove unused delegated permissions before granting consent |
| 5 | **An org-wide consent replaced the earlier one** | The Graph CLI permissions from 2.7 disappeared when 2.8 was consented | Consent for yourself for admin tooling (done for the managed identity setup) |
| 6 | **The admin tool was usable by every user** | Org-wide consent on Graph Command Line Tools | Assignment required (done) |
| 7 | **Admin tooling signs in with device code flow** | Device code sign-in is a known phishing technique | Conditional Access: block device code flow for everyone except the admins who need it (open) |
| 8 | **Entra access reviews can't review application permissions** | The design's "app permission review" isn't available as a built-in review | This inventory, with an owner attestation per app, run quarterly with the metrics runbook (open) |
