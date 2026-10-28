# Identity Metrics Report: Potomac Defense Systems

> **About this report:** Potomac Defense Systems is a fictional company in a lab tenant. Data exported Oct 28, 2026 with [`scripts/2.7-export-identity-data.ps1`](../scripts/2.7-export-identity-data.ps1) (read-only) and KQL. How it was built: [part 2.7](../parts/2.7-identity-metrics/README.md).

## Scorecard

| Metric | Result | Target | Status |
|---|---|---|:---:|
| **MFA registration, users who sign in** | **7 of 7** (100%) | 100% of active users | ✅ |
| MFA registration, all enabled accounts | 7 of 322 (2%) | n/a | ⚠️ |
| **Standing privileged role assignments** | **1** (break-glass Global Admin) | 1 | ✅ |
| Just-in-time (eligible) admin assignments | 4 | n/a | ℹ️ |
| **Access review completion** | **6 of 6 decisions** (100%), 2 removals | 100% | ✅ |
| **Stale accounts** (no sign-in in 90 days) | 0, tenant is 26 days old | Identified | ℹ️ |
| Enabled accounts that never signed in | 315 | Reviewed | ⚠️ |
| **Legacy authentication attempts** | **0** since logging began (Oct 17) | Tracked | ✅ |

## Accounts

| | Count |
|---|---:|
| Total | 340 |
| Enabled | 322 |
| Disabled (Project 1 leavers) | 18 |
| Synced from AD | 338 |
| Cloud-only (break-glass, admin) | 2 |
| Enabled and signed in at least once | 7 |

## MFA

| Group | MFA capable | Phishing-resistant |
|---|---|---|
| Users who sign in (7) | 7 (100%) | 1 (my admin account, passkey) |
| Break-glass | Yes: Authenticator push and one-time code | **No** |
| Enabled accounts that never signed in (315) | 0 | 0 |

## Privileged access

| Role | Principal | State |
|---|---|---|
| Global Administrator | Break-glass | **Standing** (by design) |
| Global Administrator | Admin account | Eligible |
| User Administrator | Admin account | Eligible |
| Authentication Administrator | Admin account | Eligible |
| Helpdesk Administrator | Helpdesk tech | Eligible |

One Global Administrator activation was live during the export. It ended on its own.

## Access reviews (part 2.5)

| Review | Decisions | Denied and removed |
|---|---|---|
| Privileged roles (Security) | 5 of 5 | 1: helpdesk tech's User Administrator |
| Radar program access (managers) | 1 of 1 | 1: engineer's program access, 87 days early |

## Findings

| # | Finding | Risk | Recommendation |
|---|---|---|---|
| 1 | **315 enabled accounts have never signed in and have no MFA registered** | Whoever signs in first with the password registers MFA, possibly an attacker | Onboard with a Temporary Access Pass, restrict security info registration with Conditional Access, keep accounts disabled until the start date |
| 2 | **Break-glass uses phishable MFA** (push and one-time code) | The most powerful account has the weakest MFA type among admins | Register FIDO2 security keys for break-glass and store them securely |
| 3 | **"Stale" can't be measured yet** | No account is 90 days old | Re-run monthly. Until then, track "never signed in" |
| 4 | **18 disabled accounts kept with no deletion date** | Disabled accounts can be re-enabled by mistake | Define a retention window for leavers (for example 30 days), then delete |
| 5 | **The report needed a manual, interactive export** | Metrics only exist when someone remembers to run them | Automate with a managed identity runbook (part 2.8) |
